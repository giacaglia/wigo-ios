//
//  LLACircularProgressView.m
//  LLACircularProgressView
//
//  Created by Lukas Lipka on 26/10/13.
//  Copyright (c) 2013 Lukas Lipka. All rights reserved.
//

#import "LLACircularProgressView.h"
#import <QuartzCore/QuartzCore.h>
#import <Availability.h>

@interface LLACircularProgressView ()

@property (nonatomic, strong) CAShapeLayer *progressLayer;

@end

@implementation LLACircularProgressView

@synthesize progressTintColor = _progressTintColor;
@synthesize innerObjectTintColor = _innerObjectTintColor;

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    self.contentMode = UIViewContentModeRedraw;
    self.backgroundColor = [UIColor whiteColor];

    _progressTintColor = [UIColor blackColor];
    
    _progressLayer = [[CAShapeLayer alloc] init];
    _progressLayer.strokeColor = self.progressTintColor.CGColor;
    _progressLayer.strokeEnd = 0;
    _progressLayer.fillColor = nil;
    _progressLayer.lineWidth = 8;
    [self.layer addSublayer:_progressLayer];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.progressLayer.frame = self.bounds;

    [self updatePath];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    //inner circle
    CGContextSetFillColorWithColor(ctx, self.innerObjectTintColor.CGColor);
    CGRect circlePoint = (CGRectMake(CGRectGetMidX(self.bounds) - self.bounds.size.width / 4, CGRectGetMidY(self.bounds) - self.bounds.size.height / 4, self.bounds.size.width / 2, self.bounds.size.height / 2));
    CGContextFillEllipseInRect(ctx, circlePoint);
    
//    CGContextSetFillColorWithColor(ctx, self.progressTintColor.CGColor);
//    CGContextSetStrokeColorWithColor(ctx, self.progressTintColor.CGColor);
//    CGContextStrokeEllipseInRect(ctx, CGRectInset(self.bounds, 1, 1));
    
    
//    CGRect stopRect;
//    stopRect.origin.x = CGRectGetMidX(self.bounds) - self.bounds.size.width / 8;
//    stopRect.origin.y = CGRectGetMidY(self.bounds) - self.bounds.size.height / 8;
//    stopRect.size.width = self.bounds.size.width / 4;
//    stopRect.size.height = self.bounds.size.height / 4;
//    CGContextFillRect(ctx, CGRectIntegral(stopRect));
}

#pragma mark - Accessors

- (void)setProgress:(float)progress {
    [self setProgress:progress animated:NO];
}

- (void)setProgress:(float)progress animated:(BOOL)animated {
    if (progress > 0) {
        if (animated) {
            CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
            animation.fromValue = self.progress == 0 ? @0 : nil;
            animation.toValue = [NSNumber numberWithFloat:progress];
            animation.duration = 1;
            self.progressLayer.strokeEnd = progress;
            [self.progressLayer addAnimation:animation forKey:@"animation"];
        } else {
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            self.progressLayer.strokeEnd = progress;
            [CATransaction commit];
        }
    } else {
        self.progressLayer.strokeEnd = 0.0f;
        [self.progressLayer removeAnimationForKey:@"animation"];
    }
    
    _progress = progress;
}

- (UIColor *)progressTintColor {
#ifdef __IPHONE_7_0
    if ([self respondsToSelector:@selector(tintColor)]) {
        return self.tintColor;
    }
#endif
    return _progressTintColor;
}

- (UIColor *)innerObjectTintColor {
    return _innerObjectTintColor;
}

- (void)setProgressTintColor:(UIColor *)progressTintColor {
#ifdef __IPHONE_7_0
    if ([self respondsToSelector:@selector(setTintColor:)]) {
        self.tintColor = progressTintColor;
        return;
    }
#endif
    _progressTintColor = progressTintColor;
    self.progressLayer.strokeColor = progressTintColor.CGColor;
    [self setNeedsDisplay];
}

- (void)setInnerObjectTintColor:(UIColor *)innerObjectTintColor {
    _innerObjectTintColor = innerObjectTintColor;
    [self setNeedsDisplay];
}

#pragma mark - Other

#ifdef __IPHONE_7_0
- (void)tintColorDidChange {
    [super tintColorDidChange];
    
    self.progressLayer.strokeColor = self.tintColor.CGColor;
    [self setNeedsDisplay];
}
#endif

#pragma mark - Private

- (void)updatePath {
    CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    self.progressLayer.path = [UIBezierPath bezierPathWithArcCenter:center radius:self.bounds.size.width / 2 - 2 startAngle:-M_PI_2 endAngle:-M_PI_2 + 2 * M_PI clockwise:YES].CGPath;
}

@end
