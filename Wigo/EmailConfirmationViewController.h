//
//  EmailConfirmationViewController.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/28/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LockScreenViewController.h"

@interface EmailConfirmationViewController : UIViewController <UITextFieldDelegate>

@property UILabel *numberOfPeopleLabel;
@property LockScreenViewController *lockScreenViewController;
@end
