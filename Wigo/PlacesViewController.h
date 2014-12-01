//
//  PlacesViewController.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/2/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProfileViewController.h"

@interface PlacesViewController : UIViewController <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate>

@property ProfileViewController *profileViewController;

@end

#import "Event.h"
#import "EventPeopleScrollView.h"

@interface EventCell : UITableViewCell
@property (nonatomic, strong) Event *event;
@property (nonatomic, strong) UILabel *eventNameLabel;
@property (nonatomic, strong) UIImageView *chatBubbleImageView;
@property (nonatomic, strong) UILabel *chatNumberLabel;
@property (nonatomic, strong) EventPeopleScrollView *eventPeopleScrollView;
@end
