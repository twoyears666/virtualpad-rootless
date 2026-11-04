#import "Preferences.h"
#import "VPModel.h"
#import "VPEditorViewController.h"

@interface VPRootListController : PSListController
@end

@implementation VPRootListController {
	NSMutableArray *_vpSpecifiers;
}

- (NSString *)title {
	return @"VirtualPad";
}

- (NSArray *)specifiers {
	if (!_vpSpecifiers) {
		_vpSpecifiers = [NSMutableArray array];

		PSSpecifier *enableGroup = [PSSpecifier preferenceSpecifierNamed:@""
																 target:self
																	set:NULL
																	get:NULL
																 detail:nil
																   cell:PSGroupCell
																   edit:nil];
		[enableGroup setProperty:@"关闭后控制中心开关无效，虚拟按键也不会显示。"
						forKey:@"footerText"];
		[_vpSpecifiers addObject:enableGroup];

		PSSpecifier *enabled = [PSSpecifier preferenceSpecifierNamed:@"启用虚拟按键"
															  target:self
																 set:@selector(setEnabled:specifier:)
																 get:@selector(getEnabled:)
															  detail:nil
																cell:PSSwitchCell
																edit:nil];
		[_vpSpecifiers addObject:enabled];

		PSSpecifier *layoutGroup = [PSSpecifier preferenceSpecifierNamed:@""
																  target:self
																	 set:NULL
																	 get:NULL
																  detail:nil
																	cell:PSGroupCell
																	edit:nil];
		[layoutGroup setProperty:@"长按画布空白处添加按键或摇杆；长按已有控件可修改、删除；拖动可调整位置。"
						forKey:@"footerText"];
		[_vpSpecifiers addObject:layoutGroup];

		PSSpecifier *editLayout = [PSSpecifier preferenceSpecifierNamed:@"编辑键位"
																 target:self
																	set:NULL
																	get:NULL
															 detail:nil
															   cell:PSButtonCell
															   edit:nil];
		[editLayout setProperty:NSStringFromSelector(@selector(openLayoutEditor)) forKey:@"action"];
		[_vpSpecifiers addObject:editLayout];
	}
	return _vpSpecifiers;
}

#pragma mark - 开关

- (void)setEnabled:(id)value specifier:(PSSpecifier *)specifier {
	VPSetEnabled([value boolValue]);
	VPPostRefreshNotification();
}

- (id)getEnabled:(PSSpecifier *)specifier {
	return @(VPIsEnabled());
}

#pragma mark - 编辑器

- (void)openLayoutEditor {
	VPEditorViewController *editor = [[VPEditorViewController alloc] init];
	editor.modalPresentationStyle = UIModalPresentationFullScreen;
	[self presentViewController:editor animated:YES completion:nil];
}

@end
