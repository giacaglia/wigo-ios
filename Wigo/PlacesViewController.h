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

@property (nonatomic, assign) BOOL fetchingIsThereNewPerson;
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

@interface TitleHeaderEventCell : UITableViewCell
@property (nonatomic, strong) Event *event;
@property (nonatomic, assign) id<PlacesDelegate> placesDelegate;
- (void)setupTitleHeader;
@property (nonatomic, strong) UILabel *oldEventLabel;
@end

@interface HighlightOldEventCell : TitleHeaderEventCell
@property (nonatomic, strong) UIImageView *highlightImageView;
@end

@interface OldEventCell : TitleHeaderEventCell
@end

@interface HeaderOldEventCell : UITableViewHeaderFooterView
@property (nonatomic, strong) UILabel *headerTitleLabel;
@end
