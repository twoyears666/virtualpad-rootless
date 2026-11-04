#import "VPEditorViewController.h"
#import "VPEditorControlView.h"

@interface VPEditorViewController () <UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIView *topBar;
@property (nonatomic, strong) UIView *canvas;
@property (nonatomic, strong) UILabel *hintLabel;
@property (nonatomic, strong) VPLayout *layout;
@property (nonatomic, strong) NSMutableArray<VPEditorControlView *> *controlViews;
@end

@implementation VPEditorViewController

- (instancetype)init {
	self = [super init];
	if (self) {
		_layout = [VPLayout loadLayout];
		_controlViews = [NSMutableArray array];
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	self.view.backgroundColor = [UIColor colorWithWhite:0.05 alpha:1.0];
	[self buildTopBar];
	[self buildCanvas];
	[self reloadControls];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
	return UIStatusBarStyleLightContent;
}

#pragma mark - 界面搭建

- (void)buildTopBar {
	_topBar = [[UIView alloc] initWithFrame:CGRectZero];
	_topBar.translatesAutoresizingMaskIntoConstraints = NO;
	_topBar.backgroundColor = [UIColor colorWithWhite:0.09 alpha:1.0];
	[self.view addSubview:_topBar];

	UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
	[cancelButton setTitle:@"取消" forState:UIControlStateNormal];
	[cancelButton setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.85] forState:UIControlStateNormal];
	cancelButton.titleLabel.font = [UIFont systemFontOfSize:17.0];
	cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
	[cancelButton addTarget:self action:@selector(handleCancel) forControlEvents:UIControlEventTouchUpInside];
	[_topBar addSubview:cancelButton];

	UIButton *saveButton = [UIButton buttonWithType:UIButtonTypeSystem];
	[saveButton setTitle:@"保存" forState:UIControlStateNormal];
	[saveButton setTitleColor:[UIColor colorWithRed:0.35 green:0.78 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
	saveButton.titleLabel.font = [UIFont boldSystemFontOfSize:17.0];
	saveButton.translatesAutoresizingMaskIntoConstraints = NO;
	[saveButton addTarget:self action:@selector(handleSave) forControlEvents:UIControlEventTouchUpInside];
	[_topBar addSubview:saveButton];

	UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	titleLabel.text = @"编辑键位";
	titleLabel.textColor = UIColor.whiteColor;
	titleLabel.font = [UIFont boldSystemFontOfSize:17.0];
	titleLabel.textAlignment = NSTextAlignmentCenter;
	titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
	[_topBar addSubview:titleLabel];

	[NSLayoutConstraint activateConstraints:@[
		[_topBar.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
		[_topBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
		[_topBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
		[_topBar.heightAnchor constraintEqualToConstant:50.0],

		[cancelButton.leadingAnchor constraintEqualToAnchor:_topBar.leadingAnchor constant:16.0],
		[cancelButton.centerYAnchor constraintEqualToAnchor:_topBar.centerYAnchor],

		[saveButton.trailingAnchor constraintEqualToAnchor:_topBar.trailingAnchor constant:-16.0],
		[saveButton.centerYAnchor constraintEqualToAnchor:_topBar.centerYAnchor],

		[titleLabel.centerXAnchor constraintEqualToAnchor:_topBar.centerXAnchor],
		[titleLabel.centerYAnchor constraintEqualToAnchor:_topBar.centerYAnchor],
	]];
}

- (void)buildCanvas {
	_canvas = [[UIView alloc] initWithFrame:CGRectZero];
	_canvas.translatesAutoresizingMaskIntoConstraints = NO;
	_canvas.backgroundColor = [UIColor colorWithWhite:0.11 alpha:1.0];
	_canvas.layer.cornerRadius = 0.0;
	[self.view addSubview:_canvas];

	[NSLayoutConstraint activateConstraints:@[
		[_canvas.topAnchor constraintEqualToAnchor:_topBar.bottomAnchor],
		[_canvas.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
		[_canvas.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
		[_canvas.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
	]];

	UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleCanvasLongPress:)];
	longPress.minimumPressDuration = 0.5;
	longPress.delegate = self;
	[_canvas addGestureRecognizer:longPress];

	_hintLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	_hintLabel.text = @"长按空白处添加按键/摇杆，长按控件修改或删除，拖动可调整位置";
	_hintLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.35];
	_hintLabel.font = [UIFont systemFontOfSize:13.0];
	_hintLabel.textAlignment = NSTextAlignmentCenter;
	_hintLabel.numberOfLines = 0;
	_hintLabel.translatesAutoresizingMaskIntoConstraints = NO;
	[_canvas addSubview:_hintLabel];

	[NSLayoutConstraint activateConstraints:@[
		[_hintLabel.centerXAnchor constraintEqualToAnchor:_canvas.centerXAnchor],
		[_hintLabel.bottomAnchor constraintEqualToAnchor:_canvas.safeAreaLayoutGuide.bottomAnchor constant:-24.0],
		[_hintLabel.leadingAnchor constraintEqualToAnchor:_canvas.leadingAnchor constant:24.0],
		[_hintLabel.trailingAnchor constraintEqualToAnchor:_canvas.trailingAnchor constant:-24.0],
	]];
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	[self layoutControls];
}

- (void)reloadControls {
	for (VPEditorControlView *view in _controlViews) {
		[view removeFromSuperview];
	}
	[_controlViews removeAllObjects];

	for (VPControl *control in self.layout.controls) {
		VPEditorControlView *view = [[VPEditorControlView alloc] initWithControl:control];

		UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
		[view addGestureRecognizer:pan];

		UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleControlLongPress:)];
		longPress.minimumPressDuration = 0.5;
		[view addGestureRecognizer:longPress];

		[_canvas insertSubview:view belowSubview:_hintLabel];
		[_controlViews addObject:view];
	}
	[self layoutControls];
	[_canvas bringSubviewToFront:_hintLabel];
}

- (void)layoutControls {
	CGFloat width = CGRectGetWidth(_canvas.bounds);
	CGFloat height = CGRectGetHeight(_canvas.bounds);
	if (width <= 0 || height <= 0) return;

	for (VPEditorControlView *view in _controlViews) {
		VPControl *control = view.control;
		view.center = CGPointMake(control.x * width, control.y * height);
	}
}

#pragma mark - 手势

- (VPEditorControlView *)controlViewAtPoint:(CGPoint)point {
	for (VPEditorControlView *view in _controlViews.reverseObjectEnumerator) {
		if (CGRectContainsPoint(view.frame, point)) return view;
	}
	return nil;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
	if (![gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) return YES;
	if (gestureRecognizer.view != _canvas) return YES;
	CGPoint point = [gestureRecognizer locationInView:_canvas];
	return [self controlViewAtPoint:point] == nil;
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
	VPEditorControlView *view = (VPEditorControlView *)gesture.view;
	if (![view isKindOfClass:[VPEditorControlView class]]) return;
	if (gesture.state != UIGestureRecognizerStateBegan && gesture.state != UIGestureRecognizerStateChanged) return;

	CGPoint translation = [gesture translationInView:_canvas];
	CGPoint center = CGPointMake(view.center.x + translation.x, view.center.y + translation.y);
	[gesture setTranslation:CGPointZero inView:_canvas];

	CGFloat halfWidth = CGRectGetWidth(view.bounds) / 2.0;
	CGFloat halfHeight = CGRectGetHeight(view.bounds) / 2.0;
	center.x = MIN(MAX(center.x, halfWidth), CGRectGetWidth(_canvas.bounds) - halfWidth);
	center.y = MIN(MAX(center.y, halfHeight), CGRectGetHeight(_canvas.bounds) - halfHeight);
	view.center = center;

	view.control.x = center.x / CGRectGetWidth(_canvas.bounds);
	view.control.y = center.y / CGRectGetHeight(_canvas.bounds);
}

- (void)handleCanvasLongPress:(UILongPressGestureRecognizer *)gesture {
	if (gesture.state != UIGestureRecognizerStateBegan) return;
	[self presentAddMenu];
}

- (void)handleControlLongPress:(UILongPressGestureRecognizer *)gesture {
	if (gesture.state != UIGestureRecognizerStateBegan) return;
	VPEditorControlView *view = (VPEditorControlView *)gesture.view;
	if (![view isKindOfClass:[VPEditorControlView class]]) return;
	[self presentModifyMenuForControlView:view];
}

#pragma mark - 菜单

- (void)presentActionSheetWithActions:(NSArray<UIAlertAction *> *)actions {
	UIAlertController *sheet = [UIAlertController alertControllerWithTitle:nil
																  message:nil
														   preferredStyle:UIAlertControllerStyleActionSheet];
	for (UIAlertAction *action in actions) {
		[sheet addAction:action];
	}
	[sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];

	sheet.popoverPresentationController.sourceView = self.view;
	sheet.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds),
																CGRectGetMidY(self.view.bounds),
																1.0,
																1.0);
	[self presentViewController:sheet animated:YES completion:nil];
}

- (void)presentAddMenu {
	__weak typeof(self) weakSelf = self;
	[self presentActionSheetWithActions:@[
		[UIAlertAction actionWithTitle:@"添加按钮" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
			[weakSelf presentButtonPicker];
		}],
		[UIAlertAction actionWithTitle:@"添加摇杆" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
			[weakSelf presentStickPicker];
		}],
	]];
}

- (void)presentButtonPicker {
	__weak typeof(self) weakSelf = self;
	NSMutableArray<UIAlertAction *> *actions = [NSMutableArray array];
	for (NSString *title in VPButtonTitles()) {
		[actions addObject:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
			[weakSelf addControl:[VPControl buttonWithTitle:title]];
		}]];
	}
	[self presentActionSheetWithActions:actions];
}

- (void)presentStickPicker {
	__weak typeof(self) weakSelf = self;
	NSMutableArray<UIAlertAction *> *actions = [NSMutableArray array];
	for (NSInteger style = VPStickStyleWASD; style <= VPStickStyleRight; style++) {
		NSString *title = VPStickStyleTitle((VPStickStyle)style);
		[actions addObject:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
			[weakSelf addControl:[VPControl stickWithStyle:(VPStickStyle)style]];
		}]];
	}
	[self presentActionSheetWithActions:actions];
}

- (void)presentModifyMenuForControlView:(VPEditorControlView *)view {
	VPControl *control = view.control;
	__weak typeof(self) weakSelf = self;
	NSMutableArray<UIAlertAction *> *actions = [NSMutableArray array];

	[actions addObject:[UIAlertAction actionWithTitle:@"修改名称" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
		[weakSelf presentRenameForControlView:view];
	}]];
	[actions addObject:[UIAlertAction actionWithTitle:@"修改大小" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
		[weakSelf presentSizeMenuForControlView:view];
	}]];
	if (control.kind == VPControlKindStick) {
		[actions addObject:[UIAlertAction actionWithTitle:@"修改摇杆样式" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
			[weakSelf presentStyleMenuForControlView:view];
		}]];
	}
	[actions addObject:[UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
		[weakSelf removeControlView:view];
	}]];

	[self presentActionSheetWithActions:actions];
}

- (void)presentRenameForControlView:(VPEditorControlView *)view {
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"修改名称"
																  message:nil
														   preferredStyle:UIAlertControllerStyleAlert];
	[alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
		textField.text = view.control.title;
		textField.clearButtonMode = UITextFieldViewModeWhileEditing;
	}];

	__weak typeof(self) weakSelf = self;
	[alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
	[alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
		NSString *text = alert.textFields.firstObject.text ?: @"";
		view.control.title = text;
		[view setNeedsDisplay];
		[weakSelf layoutControls];
	}]];
	[self presentViewController:alert animated:YES completion:nil];
}

- (void)presentSizeMenuForControlView:(VPEditorControlView *)view {
	__weak typeof(self) weakSelf = self;
	NSArray<NSString *> *titles = @[ @"放大", @"默认", @"缩小" ];
	NSArray<NSNumber *> *scales = @[ @(1.3), @(1.0), @(0.75) ];
	NSMutableArray<UIAlertAction *> *actions = [NSMutableArray array];
	for (NSUInteger index = 0; index < titles.count; index++) {
		CGFloat scale = scales[index].doubleValue;
		[actions addObject:[UIAlertAction actionWithTitle:titles[index] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
			view.control.size = VPDefaultSizeForKind(view.control.kind) * scale;
			[view applyControl:view.control];
			[weakSelf layoutControls];
		}]];
	}
	[self presentActionSheetWithActions:actions];
}

- (void)presentStyleMenuForControlView:(VPEditorControlView *)view {
	__weak typeof(self) weakSelf = self;
	NSMutableArray<UIAlertAction *> *actions = [NSMutableArray array];
	for (NSInteger style = VPStickStyleWASD; style <= VPStickStyleRight; style++) {
		NSString *title = VPStickStyleTitle((VPStickStyle)style);
		[actions addObject:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
			view.control.style = (VPStickStyle)style;
			view.control.title = title;
			[view setNeedsDisplay];
			[weakSelf layoutControls];
		}]];
	}
	[self presentActionSheetWithActions:actions];
}

#pragma mark - 增删

- (void)addControl:(VPControl *)control {
	control.x = 0.5;
	control.y = 0.5;
	[self.layout.controls addObject:control];
	[self reloadControls];
}

- (void)removeControlView:(VPEditorControlView *)view {
	[self.layout.controls removeObject:view.control];
	[view removeFromSuperview];
	[_controlViews removeObject:view];
}

#pragma mark - 顶栏动作

- (void)handleCancel {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)handleSave {
	[self.layout save];
	VPPostRefreshNotification();
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
