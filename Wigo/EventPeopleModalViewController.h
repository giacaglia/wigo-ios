//
//  EventPeopleModalViewViewController.h
//  Wigo
//
//  Created by Adam Eagle on 2/1/15.
//  Copyright (c) 2015 Adam Eagle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Globals.h"
#import "Delegate.h"

@interface EventPeopleModalViewController : UIViewController <UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property CGPoint initialPosition;
@property CGPoint lastPosition;

@property BOOL fetchingEventAttendees;

@property NSTimer *timer;

@property UIImage *backgroundImage;

@property NSMutableArray *images;
@property NSMutableArray *imageDidLoad;

@property int startIndex;
@property float velocity;
@property UIScrollView *attendeesPhotosScrollView;
@property WGEvent *event;
@property (nonatomic, assign) id <PlacesDelegate> placesDelegate;

- (id)initWithEvent:(WGEvent *)event startIndex:(int)index andBackgroundImage:(UIImage *)image;

-(void) untap:(UILongPressGestureRecognizer *)gestureRecognizer;
-(void) updateUI;
-(void) touchedLocation:(UIGestureRecognizer *)gestureRecognizer;

@end
