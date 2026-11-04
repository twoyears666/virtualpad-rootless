#import <UIKit/UIKit.h>
#import "VPOverlayManager.h"

// 注入所有进程，但只在真正的 App 里生效：SpringBoard（主屏幕）与守护进程一律跳过
%ctor {
	@autoreleasepool {
		if (!NSClassFromString(@"UIApplication")) return;

		NSString *bundleIdentifier = [NSBundle mainBundle].bundleIdentifier ?: @"";
		if ([bundleIdentifier isEqualToString:@"com.apple.springboard"]) return;
		// 键位编辑器就在「设置」里，覆盖层会挡住画布，直接跳过
		if ([bundleIdentifier isEqualToString:@"com.apple.Preferences"]) return;

		[[VPOverlayManager sharedManager] start];
	}
}
