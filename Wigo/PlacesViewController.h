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
#import "BaseViewController.h"
#import "Globals.h"

@class WGDateSelectionView;

@interface PlacesViewController : BaseViewController
    <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate,
    UIGestureRecognizerDelegate, PlacesDelegate, CLLocationManagerDelegate,
    WGViewController>

#define kTodaySection 0
#define kHighlightsEmptySection 1

@property (nonatomic, strong) NSNumber *groupNumberID;
@property (nonatomic, strong) NSString *groupName;
@property (nonatomic, strong) NSMutableDictionary *eventOffsetDictionary;

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
@property (nonatomic, assign) BOOL shouldReloadEvents;
@property (nonatomic, strong) UIButton *switchButton;
@property (nonatomic, assign) BOOL doNotReloadOffsets;
@property (nonatomic, assign) CGPoint pointNow;
@property (nonatomic, assign) BOOL spinnerAtCenter;
@property (nonatomic, strong) WGDateSelectionView *datesView;

@property (nonatomic, strong) LabelSwitch *labelSwitch;
@property (nonatomic, strong) UIView *toggleView;
@property (nonatomic, strong) UILabel *bostonLabel;
@property (nonatomic, strong) UIButton *friendsButton;
@property (nonatomic, assign) BOOL isLocal;
@property (nonatomic, strong) UIButton *createButton;
@property (nonatomic, strong) UIView *overlayView;

@property (nonatomic, strong) UIView *emptyFriendsView;
@property (nonatomic, strong) UIImageView *onboardView;
@property (nonatomic, strong) UIView *emptyLocalView;

@property (nonatomic, readonly) BOOL isShowingFutureEvents;

@end

#import "EventPeopleScrollView.h"
#import "HighlightsCollectionView.h"

@interface EventCell : UITableViewCell
+ (CGFloat)height;
@property (nonatomic, strong) UIView *whiteView;
@property (nonatomic, strong) UIActivityIndicatorView *loadingView;
@property (nonatomic, assign) id<PlacesDelegate> placesDelegate;
@property (nonatomic, strong) UIButton *privacyLockButton;
@property (nonatomic, strong) UIImageView *privacyLockImageView;
@property (nonatomic, strong) WGEvent *event;
@property (nonatomic, strong) UILabel *eventNameLabel;
@property (nonatomic, strong) UILabel *numberOfPeopleGoingLabel;
@property (nonatomic, strong) EventPeopleScrollView *eventPeopleScrollView;
@property (nonatomic, strong) UILabel *numberOfNewHighlightsLabel;
@property (nonatomic, strong) UIButton *goingHereButton;
@property (nonatomic, strong) UIView *grayView;
@property (nonatomic, strong) HighlightsCollectionView *highlightsCollectionView;
@property (nonatomic, strong) UIView *verifiedView;
@property (nonatomic, strong) UIView *lineView;
@end

@interface OneLineEventCell : EventCell
+ (CGFloat)height;
@end

@interface TwoLineEventCell : EventCell
+ (CGFloat)height;
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
@property (nonatomic, strong) WGEvent *event;
@property (nonatomic, assign) id<PlacesDelegate> placesDelegate;
@property (nonatomic, strong) UILabel *eventNameLabel;
@property (nonatomic, strong) UILabel *numberOfPeopleGoingLabel;
@property (nonatomic, strong) EventPeopleScrollView *eventPeopleScrollView;
@property (nonatomic, strong) HighlightsCollectionView *highlightsCollectionView;
@property (nonatomic, strong) UIView *whiteView;
@property (nonatomic, strong) UIView *lineView;
@end

@interface OldTwoLinesEventCell : HighlightOldEventCell
+(CGFloat)height;
@end

@interface OldOneLineEventCell : HighlightOldEventCell
+(CGFloat)height;
@end

@interface OldEventShowHighlightsCell : UITableViewCell
@property (nonatomic, assign) id<PlacesDelegate> placesDelegate;
@property (nonatomic, strong) UIButton *showHighlightsButton;
+ (CGFloat) height;
@end