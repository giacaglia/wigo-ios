//
//  PlacesViewController.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/2/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProfileViewController.h"
#import "Event.h"


@protocol PlacesDelegate <NSObject>
- (void)showUser:(User *)user;
- (void)showConversationForEvent:(Event*)event;
@end

@interface PlacesViewController : UIViewController <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate, PlacesDelegate >

@property ProfileViewController *profileViewController;

@end

#import "Event.h"
#import "EventPeopleScrollView.h"

@interface EventCell : UITableViewCell
@property (nonatomic, assign) id<PlacesDelegate> placesDelegate;
@property (nonatomic, strong) Event *event;
@property (nonatomic, strong) UILabel *eventNameLabel;
@property (nonatomic, strong) UIImageView *chatBubbleImageView;
@property (nonatomic, strong) UILabel *chatNumberLabel;
@property (nonatomic, strong) EventPeopleScrollView *eventPeopleScrollView;
@end

@interface OldEventCell : UITableViewCell
@property (nonatomic, strong) UILabel *oldEventLabel;
@property (nonatomic, strong) UIImageView *chatBubbleImageView;
@property (nonatomic, strong) UILabel *chatNumberLabel;
@end

@interface HeaderOldEventCell : UITableViewHeaderFooterView
@property (nonatomic, strong) UILabel *headerTitleLabel;
@end
