#import "VPModel.h"

NSString *const VPDomainName = @"com.twoyears666.virtualpad";
NSString *const VPRefreshNotificationName = @"com.twoyears666.virtualpad/refresh";

static NSString *const VPLayoutKey = @"layout";
static NSString *const VPEnabledKey = @"enabled";

NSArray<NSString *> *VPButtonTitles(void) {
	return @[ @"A", @"B", @"X", @"Y", @"L", @"R", @"L2", @"R2", @"L3", @"R3", @"+", @"-" ];
}

NSString *VPStickStyleTitle(VPStickStyle style) {
	switch (style) {
		case VPStickStyleArrows:
			return @"上下左右";
		case VPStickStyleLeft:
			return @"手柄摇杆左";
		case VPStickStyleRight:
			return @"手柄摇杆右";
		case VPStickStyleWASD:
		default:
			return @"WASD";
	}
}

CGFloat VPDefaultSizeForKind(VPControlKind kind) {
	return kind == VPControlKindStick ? 140.0 : 54.0;
}

@implementation VPControl

+ (instancetype)controlWithDictionary:(NSDictionary *)dictionary {
	VPControl *control = [[VPControl alloc] init];
	control.identifier = dictionary[@"id"] ?: NSUUID.UUID.UUIDString;
	control.kind = [dictionary[@"kind"] integerValue];
	control.title = dictionary[@"title"] ?: @"";
	control.x = [dictionary[@"x"] doubleValue];
	control.y = [dictionary[@"y"] doubleValue];
	control.size = [dictionary[@"size"] doubleValue];
	control.style = [dictionary[@"style"] integerValue];
	if (control.size <= 0) {
		control.size = VPDefaultSizeForKind(control.kind);
	}
	return control;
}

+ (instancetype)buttonWithTitle:(NSString *)title {
	VPControl *control = [[VPControl alloc] init];
	control.identifier = NSUUID.UUID.UUIDString;
	control.kind = VPControlKindButton;
	control.title = title;
	control.size = VPDefaultSizeForKind(VPControlKindButton);
	control.x = 0.5;
	control.y = 0.5;
	return control;
}

+ (instancetype)stickWithStyle:(VPStickStyle)style {
	VPControl *control = [[VPControl alloc] init];
	control.identifier = NSUUID.UUID.UUIDString;
	control.kind = VPControlKindStick;
	control.style = style;
	control.title = VPStickStyleTitle(style);
	control.size = VPDefaultSizeForKind(VPControlKindStick);
	control.x = 0.5;
	control.y = 0.5;
	return control;
}

- (NSDictionary *)dictionaryRepresentation {
	return @{
		@"id": self.identifier,
		@"kind": @(self.kind),
		@"title": self.title ?: @"",
		@"x": @(self.x),
		@"y": @(self.y),
		@"size": @(self.size),
		@"style": @(self.style),
	};
}

@end

@implementation VPLayout

+ (instancetype)defaultLayout {
	VPLayout *layout = [[VPLayout alloc] init];
	layout.controls = [NSMutableArray array];

	VPControl *leftStick = [VPControl stickWithStyle:VPStickStyleLeft];
	leftStick.x = 0.16;
	leftStick.y = 0.80;
	[layout.controls addObject:leftStick];

	NSArray<NSString *> *titles = @[ @"A", @"B", @"X", @"Y" ];
	NSArray<NSValue *> *points = @[
		[NSValue valueWithCGPoint:CGPointMake(0.90, 0.86)],
		[NSValue valueWithCGPoint:CGPointMake(0.80, 0.92)],
		[NSValue valueWithCGPoint:CGPointMake(0.80, 0.78)],
		[NSValue valueWithCGPoint:CGPointMake(0.72, 0.86)],
	];
	for (NSUInteger index = 0; index < titles.count; index++) {
		VPControl *button = [VPControl buttonWithTitle:titles[index]];
		CGPoint point = points[index].CGPointValue;
		button.x = point.x;
		button.y = point.y;
		[layout.controls addObject:button];
	}

	return layout;
}

+ (instancetype)loadLayout {
	NSDictionary *dictionary = (__bridge_transfer NSDictionary *)CFPreferencesCopyValue(
		(__bridge CFStringRef)VPLayoutKey,
		(__bridge CFStringRef)VPDomainName,
		kCFPreferencesCurrentUser,
		kCFPreferencesAnyHost);

	NSArray *rawControls = dictionary[@"controls"];
	if (![rawControls isKindOfClass:[NSArray class]] || rawControls.count == 0) {
		return [self defaultLayout];
	}

	VPLayout *layout = [[VPLayout alloc] init];
	layout.controls = [NSMutableArray array];
	for (NSDictionary *raw in rawControls) {
		if (![raw isKindOfClass:[NSDictionary class]]) continue;
		[layout.controls addObject:[VPControl controlWithDictionary:raw]];
	}
	return layout;
}

- (void)save {
	NSMutableArray *array = [NSMutableArray array];
	for (VPControl *control in self.controls) {
		[array addObject:[control dictionaryRepresentation]];
	}

	NSDictionary *dictionary = @{ @"controls": array };
	CFPreferencesSetValue(
		(__bridge CFStringRef)VPLayoutKey,
		(__bridge CFPropertyListRef)dictionary,
		(__bridge CFStringRef)VPDomainName,
		kCFPreferencesCurrentUser,
		kCFPreferencesAnyHost);
	CFPreferencesAppSynchronize((__bridge CFStringRef)VPDomainName);
}

@end

BOOL VPIsEnabled(void) {
	NSNumber *value = (__bridge_transfer NSNumber *)CFPreferencesCopyValue(
		(__bridge CFStringRef)VPEnabledKey,
		(__bridge CFStringRef)VPDomainName,
		kCFPreferencesCurrentUser,
		kCFPreferencesAnyHost);
	return value ? value.boolValue : NO;
}

void VPSetEnabled(BOOL enabled) {
	CFPreferencesSetValue(
		(__bridge CFStringRef)VPEnabledKey,
		(__bridge CFPropertyListRef)@(enabled),
		(__bridge CFStringRef)VPDomainName,
		kCFPreferencesCurrentUser,
		kCFPreferencesAnyHost);
	CFPreferencesAppSynchronize((__bridge CFStringRef)VPDomainName);
}

void VPPostRefreshNotification(void) {
	CFNotificationCenterPostNotification(
		CFNotificationCenterGetDarwinNotifyCenter(),
		(__bridge CFStringRef)VPRefreshNotificationName,
		NULL, NULL, true);
}
