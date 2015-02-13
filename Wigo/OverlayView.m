//
//  OverlayView.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 2/11/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import "OverlayView.h"

@implementation OverlayView

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    [self.cameraDelegate presentFocusPoint:point];
    return YES;
}


@end
