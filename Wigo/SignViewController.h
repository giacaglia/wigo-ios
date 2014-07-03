//
//  SignUpViewController.h
//  webPays
//
//  Created by Giuliano Giacaglia on 9/26/13.
//  Copyright (c) 2013 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>
#import "EmailConfirmationViewController.h"
#import "SignUpViewController.h"

@interface SignViewController : UIViewController <FBLoginViewDelegate>

@property SignUpViewController *signUpViewController;
@property EmailConfirmationViewController *emailConfirmationViewController;
//@property MainViewController *mainViewController;

@end
