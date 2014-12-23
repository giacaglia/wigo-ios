//
//  PlacesViewController.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/2/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Event.h"
#import "Delegate.h"
#import "UIButtonAligned.h"


@interface PlacesViewController : UIViewController <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate, PlacesDelegate >

@property (nonatomic, strong) NSNumber *groupNumberID;
@property (nonatomic, strong) NSString *groupName;
@property (nonatomic, strong) NSMutableDictionary *eventOffsetDictionary;
@property (nonatomic, assign) BOOL visitedProfile;

@property (nonatomic, assign) BOOL fetchingIsThereNewPerson;
@property (nonatomic, strong) UILabel *leftRedDotLabel;
@property (nonatomic, strong) UILabel *redDotLabel;
@property (nonatomic, strong) UIButton *rightButton;
@end

#import "Event.h"
#import "EventPeopleScrollView.h"

@interface EventCell : UITableViewCell
@property (nonatomic, assign) id<PlacesDelegate> placesDelegate;
@property (nonatomic, strong) Event *event;
@property (nonatomic, strong) UILabel *eventNameLabel;
@property (nonatomic, strong) UIImageView *chatBubbleImageView;
@property (nonatomic, strong) UILabel *chatNumberLabel;
@property (nonatomic, strong) UIImageView *postStoryImageView;
@property (nonatomic, strong) EventPeopleScrollView *eventPeopleScrollView;
- (void)updateUI;
@end


#pragma mark - Headers
@interface TodayHeader : UIView
@property (nonatomic, strong) NSDate *date;
+ (instancetype) initWithDay: (NSDate *) date;
+ (CGFloat) height;
@end

@interface GoOutNewPlaceHeader : UIView
@property (nonatomic, strong) UIButton *addEventButton;
+ (instancetype) init;
+ (CGFloat) height;
@end

@interface HighlightsHeader : UIView
+ (instancetype) init;
+ (CGFloat) height;
@end

@interface PastDayHeader : UIView
@property (nonatomic, strong) NSString *day;
@property (nonatomic, assign) BOOL isFirst;
+ (instancetype) initWithDay: (NSString *) dayText isFirst: (BOOL) first;
+ (CGFloat) height: (BOOL) isFirst;
@end

@interface HighlightOldEventCell : UITableViewCell
@property (nonatomic, strong) UIImageView *highlightImageView;
@property (nonatomic, strong) Event *event;
@property (nonatomic, assign) id<PlacesDelegate> placesDelegate;
@property (nonatomic, strong) UILabel *oldEventLabel;
+ (CGFloat) height;

@end

