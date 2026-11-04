#import "VPOverlayManager.h"
#import "VPControlView.h"
#import "VPModel.h"
#import "VPOverlayWindow.h"

/// 承载控件并按屏幕尺寸重新排布（旋转后依然按归一化坐标落位）
@interface VPOverlayContainerView : UIView
@property (nonatomic, copy) NSArray<VPControlView *> *controlViews;
@end

@implementation VPOverlayContainerView

- (void)layoutSubviews {
	[super layoutSubviews];
	CGFloat width = CGRectGetWidth(self.bounds);
	CGFloat height = CGRectGetHeight(self.bounds);
	for (VPControlView *view in self.controlViews) {
		VPControl *control = view.control;
		view.center = CGPointMake(control.x * width, control.y * height);
	}
}

@end

static void VPRefreshNotificationCallback(CFNotificationCenterRef center,
										  void *observer,
										  CFStringRef name,
										  const void *object,
										  CFDictionaryRef userInfo) {
	VPOverlayManager *manager = (__bridge VPOverlayManager *)observer;
	[manager performSelectorOnMainThread:@selector(handleRefresh) withObject:nil waitUntilDone:NO];
}

@interface VPOverlayManager ()
- (void)handleRefresh;
@end

@implementation VPOverlayManager {
	VPOverlayWindow *_window;
	VPOverlayContainerView *_container;
	NSMutableArray<VPControlView *> *_controlViews;
	BOOL _started;
}

+ (instancetype)sharedManager {
	static VPOverlayManager *manager;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		manager = [[VPOverlayManager alloc] init];
	});
	return manager;
}

- (void)start {
	if (_started) return;
	_started = YES;
	_controlViews = [NSMutableArray array];

	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	[center addObserver:self
				 selector:@selector(applicationDidBecomeActive)
					 name:UIApplicationDidBecomeActiveNotification
				   object:nil];
	[center addObserver:self
				 selector:@selector(applicationWillResignActive)
					 name:UIApplicationWillResignActiveNotification
				   object:nil];

	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
									(__bridge const void *)(self),
									VPRefreshNotificationCallback,
									(__bridge CFStringRef)VPRefreshNotificationName,
									NULL,
									CFNotificationSuspensionBehaviorDeliverImmediately);

	if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
		[self showOverlayIfNeeded];
	}
}

#pragma mark - 前后台

- (void)applicationDidBecomeActive {
	[self showOverlayIfNeeded];
}

- (void)applicationWillResignActive {
	[self hideOverlay];
}

- (void)handleRefresh {
	if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
		[self showOverlayIfNeeded];
	}
}

#pragma mark - 显示与隐藏

- (UIWindowScene *)activeWindowScene {
	if (@available(iOS 13.0, *)) {
		for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
			if (![scene isKindOfClass:[UIWindowScene class]]) continue;
			if (scene.activationState == UISceneActivationStateForegroundActive) {
				return (UIWindowScene *)scene;
			}
		}
		id scene = [UIApplication sharedApplication].connectedScenes.anyObject;
		if ([scene isKindOfClass:[UIWindowScene class]]) return (UIWindowScene *)scene;
		return nil;
	}
	return nil;
}

- (void)buildWindowIfNeeded {
	if (_window) return;

	UIWindowScene *scene = [self activeWindowScene];
	CGRect frame = scene ? scene.coordinateSpace.bounds : [UIScreen mainScreen].bounds;

	_window = [[VPOverlayWindow alloc] initWithFrame:frame];
	if (@available(iOS 13.0, *)) {
		if (scene) _window.windowScene = scene;
	}

	_container = [[VPOverlayContainerView alloc] initWithFrame:frame];
	_container.backgroundColor = UIColor.clearColor;
	_container.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

	UIViewController *rootViewController = [[UIViewController alloc] init];
	rootViewController.view = _container;
	_window.rootViewController = rootViewController;
	_window.hidden = NO;
}

- (void)reloadControls {
	for (VPControlView *view in _controlViews) {
		[view cancelActiveTouch];
		[view removeFromSuperview];
	}
	[_controlViews removeAllObjects];

	VPLayout *layout = [VPLayout loadLayout];
	for (VPControl *control in layout.controls) {
		VPControlView *view = [[VPControlView alloc] initWithControl:control];
		[_container addSubview:view];
		[_controlViews addObject:view];
	}
	_container.controlViews = [_controlViews copy];
	[_container setNeedsLayout];
	[_container layoutIfNeeded];
}

- (void)showOverlayIfNeeded {
	if (!VPIsEnabled()) {
		[self hideOverlay];
		return;
	}

	[self buildWindowIfNeeded];
	[self reloadControls];
	_window.hidden = NO;
}

- (void)hideOverlay {
	if (!_window) return;
	for (VPControlView *view in _controlViews) {
		[view cancelActiveTouch];
	}
	_window.hidden = YES;
}

@end
