#import <Foundation/Foundation.h>

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
	%orig;
	NSLog(@"[VirtualPad] 已在 SpringBoard 注入，rootless 版本加载成功");
}

%end
