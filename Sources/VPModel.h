#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 控件类型：普通按键 / 摇杆
typedef NS_ENUM(NSInteger, VPControlKind) {
	VPControlKindButton = 0,
	VPControlKindStick = 1,
};

/// 摇杆外观样式（触摸输出一致，仅决定盘面标识）
typedef NS_ENUM(NSInteger, VPStickStyle) {
	VPStickStyleWASD = 0,
	VPStickStyleArrows = 1,
	VPStickStyleLeft = 2,
	VPStickStyleRight = 3,
};

/// 偏好设置域，插件与偏好面板共用
extern NSString *const VPDomainName;
/// 布局或开关变化后广播的 Darwin 通知
extern NSString *const VPRefreshNotificationName;

/// 可选的普通按键标题
NSArray<NSString *> *VPButtonTitles(void);
/// 摇杆样式的中文名
NSString *VPStickStyleTitle(VPStickStyle style);
/// 默认尺寸（点）
CGFloat VPDefaultSizeForKind(VPControlKind kind);

@interface VPControl : NSObject

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, assign) VPControlKind kind;
@property (nonatomic, copy) NSString *title;
/// 归一化中心点（0~1，相对于屏幕）
@property (nonatomic, assign) CGFloat x;
@property (nonatomic, assign) CGFloat y;
/// 直径（点）
@property (nonatomic, assign) CGFloat size;
@property (nonatomic, assign) VPStickStyle style;

+ (instancetype)controlWithDictionary:(NSDictionary *)dictionary;
+ (instancetype)buttonWithTitle:(NSString *)title;
+ (instancetype)stickWithStyle:(VPStickStyle)style;
- (NSDictionary *)dictionaryRepresentation;

@end

@interface VPLayout : NSObject

@property (nonatomic, strong) NSMutableArray<VPControl *> *controls;

+ (instancetype)defaultLayout;
+ (instancetype)loadLayout;
- (void)save;

@end

/// 总开关读写
BOOL VPIsEnabled(void);
void VPSetEnabled(BOOL enabled);
/// 广播刷新通知（偏好面板保存后调用）
void VPPostRefreshNotification(void);

NS_ASSUME_NONNULL_END
