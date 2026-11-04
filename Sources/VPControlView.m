#import "VPControlView.h"
#import "VPTouchSynthesizer.h"

@interface VPControlView ()
@property (nonatomic, strong, readwrite) VPControl *control;
@end

@implementation VPControlView {
	NSInteger _finger;
	CGPoint _touchStart;
	CGPoint _knobOffset;
	CGPoint _lastPoint;
	BOOL _active;
}

- (instancetype)initWithControl:(VPControl *)control {
	self = [super initWithFrame:CGRectZero];
	if (self) {
		self.backgroundColor = UIColor.clearColor;
		self.opaque = NO;
		self.multipleTouchEnabled = YES;
		[self setControl:control];
	}
	return self;
}

- (void)setControl:(VPControl *)control {
	_control = control;
	CGFloat size = control.size > 0 ? control.size : VPDefaultSizeForKind(control.kind);
	self.bounds = CGRectMake(0, 0, size, size);
	[self setNeedsDisplay];
}

- (void)layoutSubviews {
	[super layoutSubviews];
	[self setNeedsDisplay];
}

#pragma mark - 绘制

- (void)drawRect:(CGRect)rect {
	CGFloat radius = CGRectGetWidth(self.bounds) / 2.0;
	CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));

	UIBezierPath *circle = [UIBezierPath bezierPathWithArcCenter:center radius:radius - 1.0 startAngle:0 endAngle:M_PI * 2 clockwise:YES];
	[[UIColor colorWithWhite:1.0 alpha:0.14] setFill];
	[circle fill];
	[[UIColor colorWithWhite:1.0 alpha:0.45] setStroke];
	circle.lineWidth = 1.5;
	[circle stroke];

	if (self.control.kind == VPControlKindStick) {
		[self drawStickWithCenter:center radius:radius];
	} else {
		[self drawTitle:self.control.title
				atCenter:center
				  radius:radius
					font:[UIFont boldSystemFontOfSize:MAX(14.0, radius * 0.55)]
				   alpha:0.95];
	}
}

- (void)drawStickWithCenter:(CGPoint)center radius:(CGFloat)radius {
	CGFloat knobRadius = radius * 0.36;
	CGPoint knobCenter = CGPointMake(center.x + _knobOffset.x, center.y + _knobOffset.y);
	UIBezierPath *knob = [UIBezierPath bezierPathWithArcCenter:knobCenter radius:knobRadius startAngle:0 endAngle:M_PI * 2 clockwise:YES];
	[[UIColor colorWithWhite:1.0 alpha:0.28] setFill];
	[knob fill];
	[[UIColor colorWithWhite:1.0 alpha:0.6] setStroke];
	knob.lineWidth = 1.0;
	[knob stroke];

	UIFont *font = [UIFont boldSystemFontOfSize:MAX(10.0, radius * 0.2)];
	NSArray<NSString *> *labels;
	switch (self.control.style) {
		case VPStickStyleArrows:
			labels = @[ @"↑", @"←", @"↓", @"→" ];
			break;
		case VPStickStyleLeft:
			labels = @[ @"", @"", @"", @"" ];
			break;
		case VPStickStyleRight:
			labels = @[ @"", @"", @"", @"" ];
			break;
		case VPStickStyleWASD:
		default:
			labels = @[ @"W", @"A", @"S", @"D" ];
			break;
	}

	if (labels.count == 4) {
		CGFloat offset = radius * 0.68;
		[self drawTitle:labels[0] atCenter:CGPointMake(center.x, center.y - offset) radius:radius font:font alpha:0.85];
		[self drawTitle:labels[1] atCenter:CGPointMake(center.x - offset, center.y) radius:radius font:font alpha:0.85];
		[self drawTitle:labels[2] atCenter:CGPointMake(center.x, center.y + offset) radius:radius font:font alpha:0.85];
		[self drawTitle:labels[3] atCenter:CGPointMake(center.x + offset, center.y) radius:radius font:font alpha:0.85];
	}

	NSString *mark = self.control.style == VPStickStyleRight ? @"R" : (self.control.style == VPStickStyleLeft ? @"L" : @"");
	if (mark.length > 0) {
		[self drawTitle:mark
				atCenter:CGPointMake(center.x, center.y + radius * 0.72)
				  radius:radius
					font:[UIFont boldSystemFontOfSize:MAX(10.0, radius * 0.22)]
				   alpha:0.5];
	}
}

- (void)drawTitle:(NSString *)title atCenter:(CGPoint)center radius:(CGFloat)radius font:(UIFont *)font alpha:(CGFloat)alpha {
	if (title.length == 0) return;
	NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
	style.alignment = NSTextAlignmentCenter;
	NSDictionary *attributes = @{
		NSFontAttributeName: font,
		NSForegroundColorAttributeName: [UIColor colorWithWhite:1.0 alpha:alpha],
		NSParagraphStyleAttributeName: style,
	};
	CGSize textSize = [title sizeWithAttributes:attributes];
	CGRect textRect = CGRectMake(center.x - textSize.width / 2.0,
								 center.y - textSize.height / 2.0,
								 textSize.width,
								 textSize.height);
	[title drawInRect:textRect withAttributes:attributes];
}

#pragma mark - 触摸

- (CGPoint)screenCenter {
	CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
	return [self convertPoint:center toView:nil];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	if (_active) return;
	UITouch *touch = touches.anyObject;
	if (!touch) return;

	_active = YES;
	_finger = (NSInteger)[VPTouchSynthesizer acquireFingerIndex];
	_touchStart = [touch locationInView:nil];
	_knobOffset = CGPointZero;
	_lastPoint = [self screenCenter];

	[VPTouchSynthesizer beginTouchAtPoint:_lastPoint finger:(NSUInteger)_finger];
	[self setNeedsDisplay];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	if (!_active) return;
	UITouch *touch = touches.anyObject;
	if (!touch) return;

	if (self.control.kind == VPControlKindButton) {
		// 按键只固定在中心发送，避免滑动误触
		return;
	}

	CGPoint current = [touch locationInView:nil];
	CGPoint delta = CGPointMake(current.x - _touchStart.x, current.y - _touchStart.y);
	CGFloat radius = CGRectGetWidth(self.bounds) / 2.0;
	CGFloat length = sqrt(delta.x * delta.x + delta.y * delta.y);
	if (length > radius) {
		delta = CGPointMake(delta.x / length * radius, delta.y / length * radius);
	}
	_knobOffset = delta;

	CGPoint center = [self screenCenter];
	_lastPoint = CGPointMake(center.x + delta.x, center.y + delta.y);
	[VPTouchSynthesizer moveTouchToPoint:_lastPoint finger:(NSUInteger)_finger];
	[self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	[self finishTouch];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	[self finishTouch];
}

- (void)finishTouch {
	if (!_active) return;
	_active = NO;
	[VPTouchSynthesizer endTouchAtPoint:_lastPoint finger:(NSUInteger)_finger];
	[VPTouchSynthesizer releaseFingerIndex:(NSUInteger)_finger];
	_knobOffset = CGPointZero;
	[self setNeedsDisplay];
}

- (void)cancelActiveTouch {
	[self finishTouch];
}

@end
