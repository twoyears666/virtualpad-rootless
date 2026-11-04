#import <UIKit/UIKit.h>

/// 偏好面板里用到的最小 Preferences 私有接口，避免依赖完整私有头文件
typedef NS_ENUM(NSInteger, PSListCellType) {
	PSGroupCell = 0,
	PSButtonCell = 1,
	PSSwitchCell = 2,
	PSLinkListCell = 3,
	PSListItemCell = 4,
	PSListLinkCell = 7,
	PSLinkCell = 8,
};

@interface PSSpecifier : NSObject
+ (instancetype)preferenceSpecifierNamed:(NSString *)name
								 target:(id)target
									set:(SEL)set
									get:(SEL)get
								 detail:(Class)detail
								   cell:(NSInteger)cell
								   edit:(Class)edit;
- (void)setProperty:(id)value forKey:(NSString *)key;
- (id)propertyForKey:(NSString *)key;
@end

@interface PSListController : UIViewController
- (id)initForContentSize:(CGSize)size;
- (void)reloadSpecifiers;
@end
