//
//  MainViewController.h
//
//  Created by Giuliano Giacaglia.
//

#import <UIKit/UIKit.h>
#import "ProfileViewController.h"
#import "PeopleViewController.h"
#import "SignViewController.h"

@interface MainViewController : UIViewController <UIScrollViewDelegate>

@property ProfileViewController *profileViewController;
@property PeopleViewController *peopleViewController;
@property SignViewController *signViewController;
+ (void)setPushed:(BOOL)push;

@end
