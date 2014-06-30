//
//  MainViewController.h
//
//  Created by Giuliano Giacaglia.
//

#import <UIKit/UIKit.h>
#import "ProfileViewController.h"
#import "PeopleViewController.h"
#import "SignViewController.h"
#import "SignNavigationViewController.h"

@interface MainViewController : UIViewController <UIScrollViewDelegate>

@property ProfileViewController *profileViewController;
@property PeopleViewController *peopleViewController;
@property SignViewController *signViewController;
@property SignNavigationViewController *signNavigationViewController;
+ (void)setPushed:(BOOL)push;

@end
