#import "VPTouchSynthesizer.h"
#import <dlfcn.h>
#import <mach/mach_time.h>
#import <objc/message.h>

typedef struct __IOHIDEvent *IOHIDEventRef;
typedef double IOHIDFloat;

// IOKit / BackBoardServices 按需动态绑定，避免依赖私有头文件
// 注意：函数指针里的 options 参数直接用 uint32_t 代替 IOOptionBits，避免额外引入 IOKit 类型
static IOHIDEventRef (*VPIOHIDEventCreateDigitizerEvent)(CFAllocatorRef, uint64_t, uint32_t, uint32_t,
														 uint32_t, uint32_t, uint32_t, IOHIDFloat, IOHIDFloat,
														 IOHIDFloat, IOHIDFloat, IOHIDFloat, Boolean, Boolean,
														 uint32_t);
static IOHIDEventRef (*VPIOHIDEventCreateDigitizerFingerEvent)(CFAllocatorRef, uint64_t, uint32_t,
															   uint32_t, uint32_t, IOHIDFloat, IOHIDFloat,
															   IOHIDFloat, IOHIDFloat, IOHIDFloat, Boolean,
															   Boolean, uint32_t);
static void (*VPIOHIDEventAppendEvent)(IOHIDEventRef, IOHIDEventRef, uint32_t);
static void (*VPIOHIDEventSetIntegerValue)(IOHIDEventRef, uint32_t, int);
static void (*VPIOHIDEventSetFloatValue)(IOHIDEventRef, uint32_t, IOHIDFloat);
static void (*VPIOHIDEventSetSenderID)(IOHIDEventRef, uint64_t);
static void (*VPBKSHIDEventSetDigitizerInfo)(IOHIDEventRef, uint32_t, Boolean, Boolean, CFStringRef,
											 CFTimeInterval, float);

// digitizer 字段基址 11 << 16
#define VPFieldDigitizerIsDisplayIntegrated 720921u // 0xB0019
#define VPFieldDigitizerMajorRadius 720916u         // 0xB0014
#define VPFieldDigitizerMinorRadius 720917u         // 0xB0015

#define VPTransducerTypeHand 3

static void VPInitializeHIDIfNeeded(void) {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		void *iokit = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_NOW);
		VPIOHIDEventCreateDigitizerEvent = dlsym(iokit, "IOHIDEventCreateDigitizerEvent");
		VPIOHIDEventCreateDigitizerFingerEvent = dlsym(iokit, "IOHIDEventCreateDigitizerFingerEvent");
		VPIOHIDEventAppendEvent = dlsym(iokit, "IOHIDEventAppendEvent");
		VPIOHIDEventSetIntegerValue = dlsym(iokit, "IOHIDEventSetIntegerValue");
		VPIOHIDEventSetFloatValue = dlsym(iokit, "IOHIDEventSetFloatValue");
		VPIOHIDEventSetSenderID = dlsym(iokit, "IOHIDEventSetSenderID");

		void *backboard = dlopen("/System/Library/PrivateFrameworks/BackBoardServices.framework/BackBoardServices", RTLD_NOW);
		VPBKSHIDEventSetDigitizerInfo = dlsym(backboard, "BKSHIDEventSetDigitizerInfo");
	});
}

static uint32_t VPWindowContextID(void) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	UIWindow *window = [UIApplication sharedApplication].windows.firstObject;
#pragma clang diagnostic pop
	SEL selector = NSSelectorFromString(@"_contextId");
	if (window && [window respondsToSelector:selector]) {
		return ((uint32_t (*)(id, SEL))objc_msgSend)(window, selector);
	}
	return 0;
}

static void VPDispatchHIDEvent(IOHIDEventRef event) {
	UIApplication *application = [UIApplication sharedApplication];
	SEL enqueueSelector = NSSelectorFromString(@"_enqueueHIDEvent:");
	if ([application respondsToSelector:enqueueSelector]) {
		((void (*)(id, SEL, IOHIDEventRef))objc_msgSend)(application, enqueueSelector, event);
		return;
	}
	SEL handleSelector = NSSelectorFromString(@"_handleHIDEvent:");
	if ([application respondsToSelector:handleSelector]) {
		((void (*)(id, SEL, IOHIDEventRef))objc_msgSend)(application, handleSelector, event);
	}
}

static void VPSendTouch(UITouchPhase phase, CGPoint point, NSUInteger finger) {
	VPInitializeHIDIfNeeded();
	if (!VPIOHIDEventCreateDigitizerEvent || !VPIOHIDEventCreateDigitizerFingerEvent || !VPIOHIDEventAppendEvent) {
		return;
	}

	uint32_t childMask = 0;
	uint32_t parentMask = 0;
	Boolean touching = false;
	switch (phase) {
		case UITouchPhaseBegan:
			childMask = 0x3;  // range | touch
			parentMask = 0x2; // touch
			touching = true;
			break;
		case UITouchPhaseMoved:
			childMask = 0x4; // position
			touching = true;
			break;
		default: // ended / cancelled
			childMask = 0x3;
			parentMask = 0x2;
			touching = false;
			break;
	}

	uint64_t timestamp = mach_absolute_time();
	IOHIDEventRef parent = VPIOHIDEventCreateDigitizerEvent(kCFAllocatorDefault,
															timestamp,
															VPTransducerTypeHand,
															0, 0,
															parentMask, 0,
															0, 0, 0, 0, 0,
															false, touching, 0);
	if (!parent) return;
	VPIOHIDEventSetIntegerValue(parent, VPFieldDigitizerIsDisplayIntegrated, 1);
	if (VPIOHIDEventSetSenderID) VPIOHIDEventSetSenderID(parent, 0x123456789ULL);

	IOHIDEventRef child = VPIOHIDEventCreateDigitizerFingerEvent(kCFAllocatorDefault,
																 timestamp,
																 (uint32_t)finger,
																 (uint32_t)finger,
																 childMask,
																 point.x, point.y, 0,
																 0, 0,
																 touching, touching, 0);
	if (!child) return;
	VPIOHIDEventSetFloatValue(child, VPFieldDigitizerMajorRadius, 5.0);
	VPIOHIDEventSetFloatValue(child, VPFieldDigitizerMinorRadius, 5.0);
	VPIOHIDEventAppendEvent(parent, child, 0);

	if (VPBKSHIDEventSetDigitizerInfo) {
		VPBKSHIDEventSetDigitizerInfo(parent, VPWindowContextID(), false, false, NULL, 0, 0);
	}

	VPDispatchHIDEvent(parent);
}

@implementation VPTouchSynthesizer

+ (NSUInteger)acquireFingerIndex {
	static NSUInteger nextFinger = 0;
	nextFinger = (nextFinger + 1) % 10;
	return nextFinger + 1;
}

+ (void)releaseFingerIndex:(NSUInteger)finger {
	(void)finger;
}

+ (void)beginTouchAtPoint:(CGPoint)point finger:(NSUInteger)finger {
	dispatch_async(dispatch_get_main_queue(), ^{
		VPSendTouch(UITouchPhaseBegan, point, finger);
	});
}

+ (void)moveTouchToPoint:(CGPoint)point finger:(NSUInteger)finger {
	dispatch_async(dispatch_get_main_queue(), ^{
		VPSendTouch(UITouchPhaseMoved, point, finger);
	});
}

+ (void)endTouchAtPoint:(CGPoint)point finger:(NSUInteger)finger {
	dispatch_async(dispatch_get_main_queue(), ^{
		VPSendTouch(UITouchPhaseEnded, point, finger);
	});
}

+ (void)releaseAllTouches {
	// 目前每次触摸都由控件自己在结束时收起，这里只保留统一入口供覆盖层隐藏时调用
}

@end
