#import "VPEditorControlView.h"

@implementation VPEditorControlView

- (instancetype)initWithControl:(VPControl *)control {
	self = [super initWithFrame:CGRectZero];
	if (self) {
		self.backgroundColor = UIColor.clearColor;
		self.opaque = NO;
		[self applyControl:control];
	}
	return self;
}

- (void)applyControl:(VPControl *)control {
	self.control = control;
	CGFloat size = control.size > 0 ? control.size : VPDefaultSizeForKind(control.kind);
	self.bounds = CGRectMake(0, 0, size, size);
	[self setNeedsDisplay];
}

- (void)setSelected:(BOOL)selected {
	_selected = selected;
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
	CGFloat radius = CGRectGetWidth(self.bounds) / 2.0;
	CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));

	UIBezierPath *circle = [UIBezierPath bezierPathWithArcCenter:center
														  radius:radius - 1.0
													  startAngle:0
														endAngle:M_PI * 2
													   clockwise:YES];
	[[UIColor colorWithWhite:1.0 alpha:0.16] setFill];
	[circle fill];

	UIColor *strokeColor = self.selected
		? [UIColor colorWithRed:0.35 green:0.78 blue:1.0 alpha:0.95]
		: [UIColor colorWithWhite:1.0 alpha:0.5];
	[strokeColor setStroke];
	circle.lineWidth = self.selected ? 2.5 : 1.5;
	[circle stroke];

	if (self.control.kind == VPControlKindStick) {
		[self drawStickWithCenter:center radius:radius];
	} else {
		[self drawTitle:self.control.title
			   atCenter:center
				 font:[UIFont boldSystemFontOfSize:MAX(14.0, radius * 0.55)]
				alpha:0.95];
	}
}

- (void)drawStickWithCenter:(CGPoint)center radius:(CGFloat)radius {
	CGFloat knobRadius = radius * 0.36;
	UIBezierPath *knob = [UIBezierPath bezierPathWithArcCenter:center
													   radius:knobRadius
												   startAngle:0
													 endAngle:M_PI * 2
													clockwise:YES];
	[[UIColor colorWithWhite:1.0 alpha:0.26] setFill];
	[knob fill];
	[[UIColor colorWithWhite:1.0 alpha:0.55] setStroke];
	knob.lineWidth = 1.0;
	[knob stroke];

	UIFont *font = [UIFont boldSystemFontOfSize:MAX(10.0, radius * 0.2)];
	NSArray<NSString *> *labels = @[ @"W", @"A", @"S", @"D" ];
	if (self.control.style == VPStickStyleArrows) {
		labels = @[ @"↑", @"←", @"↓", @"→" ];
	}
	if (self.control.style == VPStickStyleLeft || self.control.style == VPStickStyleRight) {
		labels = @[ @"", @"", @"", @"" ];
	}

	CGFloat offset = radius * 0.68;
	[self drawTitle:labels[0] atCenter:CGPointMake(center.x, center.y - offset) font:font alpha:0.8];
	[self drawTitle:labels[1] atCenter:CGPointMake(center.x - offset, center.y) font:font alpha:0.8];
	[self drawTitle:labels[2] atCenter:CGPointMake(center.x, center.y + offset) font:font alpha:0.8];
	[self drawTitle:labels[3] atCenter:CGPointMake(center.x + offset, center.y) font:font alpha:0.8];

	NSString *mark = @"";
	if (self.control.style == VPStickStyleLeft) mark = @"L";
	if (self.control.style == VPStickStyleRight) mark = @"R";
	[self drawTitle:mark
		   atCenter:CGPointMake(center.x, center.y + radius * 0.72)
			   font:[UIFont boldSystemFontOfSize:MAX(10.0, radius * 0.22)]
			  alpha:0.55];
}

- (void)drawTitle:(NSString *)title atCenter:(CGPoint)center font:(UIFont *)font alpha:(CGFloat)alpha {
	if (title.length == 0) return;
	NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
	style.alignment = NSTextAlignmentCenter;
	NSDictionary *attributes = @{
		NSFontAttributeName: font,
		NSForegroundColorAttributeName: [UIColor colorWithWhite:1.0 alpha:alpha],
		NSParagraphStyleAttributeName: style,
	};
	CGSize textSize = [title sizeWithAttributes:attributes];
	[title drawInRect:CGRectMake(center.x - textSize.width / 2.0,
								 center.y - textSize.height / 2.0,
								 textSize.width,
								 textSize.height)
	   withAttributes:attributes];
}

@end
