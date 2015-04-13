//
//  WhereAreYouViewController.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 4/13/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PrivateSwitchView.h"

@interface WhereAreYouViewController : UIViewController<UITextFieldDelegate,
                                                    PrivacySwitchDelegate>
@property (nonatomic, strong) UITextField *whereAreYouGoingTextField;
@property (nonatomic, strong) UIView *eventDetails;
@property (nonatomic, strong) PrivateSwitchView *privateSwitchView;
@property (nonatomic, strong) UILabel *invitePeopleLabel;
@property (nonatomic, strong) UIView *loadingView;
@property (nonatomic, strong) UIView *loadingIndicator;
@end
