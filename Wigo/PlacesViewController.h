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
#import "LabelSwitch.h"


@interface PlacesViewController : UIViewController <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate,
    UIGestureRecognizerDelegate,
    PlacesDelegate,
    PrivacySwitchDelegate>
#define kTodaySection 0
#define kHighlightsEmptySection 1

@property (nonatomic, strong) NSNumber *groupNumberID;
@property (nonatomic, strong) NSString *groupName;
@property (nonatomic, strong) NSMutableDictionary *eventOffsetDictionary;

@property (nonatomic, assign) BOOL fetchingIsThereNewPerson;
@property (nonatomic, strong) UILabel *leftRedDotLabel;
@property (nonatomic, strong) UILabel *redDotLabel;
@property (nonatomic, strong) UIButton *rightButton;

@property (nonatomic, assign) BOOL fetchingEventAttendees;
@property (nonatomic, strong) WGCollection *allEvents;
@property (nonatomic, strong) WGCollection *events;
@property (nonatomic, strong) WGCollection *oldEvents;
@property (nonatomic, strong) WGEvent *aggregateEvent;
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
@property (nonatomic, strong) UIButton *switchButton;
@property (nonatomic, strong) UILabel *invitePeopleLabel;
@property (nonatomic, assign) BOOL privacyTurnedOn;
@property (nonatomic, assign) BOOL doNotReloadOffsets;
@property (nonatomic, assign) CGPoint pointNow;
@property (nonatomic, assign) BOOL spinnerAtCenter;

@property (nonatomic, strong) UIView *blueBannerView;
@property (nonatomic, strong) LabelSwitch *labelSwitch;
@property (nonatomic, assign) CGFloat previousScrollViewYOffset;
@end

#import "EventPeopleScrollView.h"
#import "HighlightsCollectionView.h"

@interface EventCell : UITableViewCell
+ (CGFloat) heightIsFullCell:(BOOL)isFullCell;
@property (nonatomic, strong) UIActivityIndicatorView *loadingView;
@property (nonatomic, assign) id<PlacesDelegate> placesDelegate;
@property (nonatomic, strong) UIButton *privacyLockButton;
@property (nonatomic, strong) UIImageView *privacyLockImageView;
@property (nonatomic, strong) WGEvent *event;
@property (nonatomic, strong) UILabel *eventNameLabel;
@property (nonatomic, strong) UILabel *numberOfPeopleGoingLabel;
@property (nonatomic, strong) EventPeopleScrollView *eventPeopleScrollView;
@property (nonatomic, strong) UILabel *numberOfHighlightsLabel;
@property (nonatomic, strong) UILabel *numberOfNewHighlightsLabel;
@property (nonatomic, strong) UIButton *goingHereButton;
@property (nonatomic, strong) UIView *grayView;
@property (nonatomic, strong) HighlightsCollectionView *highlightsCollectionView;
@property (nonatomic, strong) UIImageView *verifiedImageView;
@end


#pragma mark - Headers
@interface TodayHeader : UIView
+ (CGFloat) height;
@property (nonatomic, strong) NSDate *date;
+ (instancetype) initWithDay: (NSDate *) date;
@property (nonatomic, strong) UILabel *friendsLabel;
@property (nonatomic, strong) UILabel *bostonLabel;
@property (nonatomic, strong) UIView *lineViewUnderLabel;
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
@property (nonatomic, strong) UIImageView *privateIconImageView;
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