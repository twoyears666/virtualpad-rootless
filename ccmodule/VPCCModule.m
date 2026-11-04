#import <UIKit/UIKit.h>
#import "VPModel.h"

/// ControlCenterUIKit 里的开关模板类，运行期由 SpringBoard 提供
@interface CCUIToggleModule : NSObject
- (BOOL)isSelected;
- (void)setSelected:(BOOL)selected;
- (void)reconfigureView;
@end

@interface VPCCModule : CCUIToggleModule
@end

@implementation VPCCModule

- (BOOL)isSelected {
	return VPIsEnabled();
}

- (void)setSelected:(BOOL)selected {
	VPSetEnabled(selected);
	VPPostRefreshNotification();
	[self reconfigureView];
}

@end
