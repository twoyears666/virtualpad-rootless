#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 在当前 App 进程内合成真实的触摸事件（屏幕坐标，单位点）
@interface VPTouchSynthesizer : NSObject

/// 申请一个手指身份（同时按下的控件各自持有，互不干扰）
+ (NSUInteger)acquireFingerIndex;
+ (void)releaseFingerIndex:(NSUInteger)finger;

+ (void)beginTouchAtPoint:(CGPoint)point finger:(NSUInteger)finger;
+ (void)moveTouchToPoint:(CGPoint)point finger:(NSUInteger)finger;
+ (void)endTouchAtPoint:(CGPoint)point finger:(NSUInteger)finger;

/// 释放全部未结束的触摸（覆盖层隐藏时调用）
+ (void)releaseAllTouches;

@end

NS_ASSUME_NONNULL_END
