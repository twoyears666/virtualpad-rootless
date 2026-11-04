#import <UIKit/UIKit.h>
#import "VPModel.h"

NS_ASSUME_NONNULL_BEGIN

/// 覆盖层上的单个虚拟控件：按键或摇杆，负责把触摸转成底层 App 的输入
@interface VPControlView : UIView

@property (nonatomic, strong, readonly) VPControl *control;

- (instancetype)initWithControl:(VPControl *)control;
- (void)setControl:(VPControl *)control;
/// 强制结束正在进行的触摸（隐藏覆盖层时调用）
- (void)cancelActiveTouch;

@end

NS_ASSUME_NONNULL_END
