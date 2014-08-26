//
//  MoreViewController.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 7/28/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"

@interface MoreViewController : UIViewController

- (id)initWithState:(STATE)state;
- (id)initWithUser:(User *)newUser;

@end
