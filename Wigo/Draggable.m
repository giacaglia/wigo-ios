//
//  Draggable.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 7/27/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "Draggable.h"
@interface Draggable()
@property CGRect startingFrame;
@end

@implementation Draggable


- (void) touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
//    NSLog(@"Event %@", event);
//    NSLog(@"Touches %@", touches);
    // Retrieve the touch point
    [self.superview bringSubviewToFront:self];
    _startingFrame = self.frame;
    CGPoint pt = [[touches anyObject] locationInView:self];
    startLocation = pt;
    [[self superview] bringSubviewToFront:self];
}

- (void) touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event {
    // Move relative to the original touch point
    CGPoint pt = [[touches anyObject] locationInView:self];
    CGRect frame = [self frame];
    frame.origin.x += pt.x - startLocation.x;
    frame.origin.y += pt.y - startLocation.y;
    [self setFrame:frame];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"chooseImage" object:nil];
    [UIView animateWithDuration:0.2 animations:^{
        [self setFrame:_startingFrame];
    }];
}

@end