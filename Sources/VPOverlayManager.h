#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 覆盖层管理器：跟随 App 前后台状态显示/隐藏虚拟按键
@interface VPOverlayManager : NSObject

+ (instancetype)sharedManager;
- (void)start;

@end

NS_ASSUME_NONNULL_END
