//
//  PlacesViewController.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/2/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProfileViewController.h"

@interface PlacesViewController : UIViewController <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>

@property ProfileViewController *profileViewController;

@end
