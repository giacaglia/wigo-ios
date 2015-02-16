//
//  EventPeopleScrollView.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 10/29/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WGEvent.h"
#import "Delegate.h"
#import "EventPeopleModalViewController.h"

@interface EventPeopleScrollView : UIScrollView <UIScrollViewDelegate, UIGestureRecognizerDelegate>

-(id) initWithEvent:(WGEvent*)event;
-(void) updateUI;
+(CGFloat) containerHeight;
-(void) scrollToSavedPosition;
-(void) saveScrollPosition;
-(CGPoint) indexToPoint:(int) index;

@property EventPeopleModalViewController *eventPeopleModalViewController;

@property (nonatomic, assign) id <UserSelectDelegate> userSelectDelegate;
@property (nonatomic, assign) id <PlacesDelegate> placesDelegate;
@property (nonatomic, strong) NSNumber *groupID;
@property (nonatomic, assign) int eventOffset;
@property (nonatomic, assign) BOOL fetchingEventAttendees;
@property (nonatomic, strong) NSNumber *page;
@property (nonatomic, assign) int xPosition;
@property (nonatomic, strong) WGEvent *event;
@property (nonatomic, assign) int sizeOfEachImage;
@end