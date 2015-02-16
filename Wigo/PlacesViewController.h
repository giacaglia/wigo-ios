//
//  PlacesViewController.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/2/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WGEvent.h"
#import "Delegate.h"
#import "UIButtonAligned.h"
#import "SignViewController.h"


@interface PlacesViewController : UIViewController <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate, PlacesDelegate>

@property (nonatomic, strong) NSNumber *groupNumberID;
@property (nonatomic, strong) NSString *groupName;
@property (nonatomic, strong) NSMutableDictionary *eventOffsetDictionary;

@property (nonatomic, assign) BOOL fetchingIsThereNewPerson;
@property (nonatomic, strong) UILabel *leftRedDotLabel;
@property (nonatomic, strong) UILabel *redDotLabel;
@property (nonatomic, strong) UIButton *rightButton;
@property (nonatomic, strong) UIButton *goingSomewhereButton;

@property (nonatomic, assign) BOOL fetchingEventAttendees;
@property (nonatomic, strong) WGCollection *allEvents;
@property (nonatomic, strong) WGCollection *events;
@property (nonatomic, strong) WGCollection *oldEvents;
@property (nonatomic, strong) NSMutableDictionary *dayToEventObjArray;
@property (nonatomic, strong) SignViewController *signViewController;
@property (nonatomic, assign) BOOL fetchingUserInfo;
@property (nonatomic, assign) BOOL secondTimeFetchingUserInfo;
@property (nonatomic, strong) UITableView *placesTableView;
@property (nonatomic, strong) UITextField *whereAreYouGoingTextField;
@property (nonatomic, strong) UIView *loadingView;
@property (nonatomic, strong) UIView *loadingIndicator;
@property (nonatomic, strong) UIButton *schoolButton;
@property (nonatomic, assign) BOOL presentingLockedView;
@property (nonatomic, assign) BOOL shouldReloadEvents;
@property (nonatomic, strong) UIView *frontView;
@property (nonatomic, strong) UILabel *frontLabel;
@property (nonatomic, strong) UIImageView *frontImageView;
@property (nonatomic, strong) UIView *backView;
@property (nonatomic, strong) UILabel *backLabel;
@property (nonatomic, strong) UIImageView *backImageView;
@property (nonatomic, strong) UIButton *switchButton;
@property (nonatomic, assign) BOOL privacyTurnedOn;
@property (nonatomic, strong) UILabel *invitePeopleLabel;
@end

#import "EventPeopleScrollView.h"

@interface EventCell : UITableViewCell
@property (nonatomic, assign) id<PlacesDelegate> placesDelegate;
@property (nonatomic, strong) WGEvent *event;
@property (nonatomic, strong) UILabel *eventNameLabel;
@property (nonatomic, strong) UIImageView *chatBubbleImageView;
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
- (void)setupWithMoreThanOneEvent:(BOOL)moreThanOneEvent;
@property (nonatomic, strong) UILabel *goSomewhereLabel;
@property (nonatomic, strong) UIButton *plusButton;
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
@property (nonatomic, strong) WGEvent *event;
@property (nonatomic, assign) id<PlacesDelegate> placesDelegate;
@property (nonatomic, strong) UILabel *oldEventLabel;
+ (CGFloat) height;
@end

@interface OldEventShowHighlightsCell : UITableViewCell
@property (nonatomic, assign) id<PlacesDelegate> placesDelegate;
@property (nonatomic, strong) UIButton *showHighlightsButton;
+ (CGFloat) height;
@end