#import "VPOverlayWindow.h"

@implementation VPOverlayWindow

- (instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		self.windowLevel = UIWindowLevelAlert + 100;
		self.backgroundColor = UIColor.clearColor;
		self.opaque = NO;
		self.hidden = NO;
	}
	return self;
}

/// 只有命中虚拟控件时才吃事件，其余全部下发给下层 App 窗口
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
	UIView *hitView = [super hitTest:point withEvent:event];
	if (hitView == self) return nil;
	if (hitView == self.rootViewController.view) return nil;
	return hitView;
}

@end
