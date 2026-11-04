#import <UIKit/UIKit.h>
#import "VPModel.h"

NS_ASSUME_NONNULL_BEGIN

/// 编辑器画布上的控件外观（只负责显示与绘制，不合成触摸）
@interface VPEditorControlView : UIView

@property (nonatomic, strong, readwrite) VPControl *control;
@property (nonatomic, assign) BOOL selected;

- (instancetype)initWithControl:(VPControl *)control;
- (void)applyControl:(VPControl *)control;

@end

NS_ASSUME_NONNULL_END
