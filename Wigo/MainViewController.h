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

@interface MainViewController : UIViewController <UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
{
    UICollectionView *_collectionView;
}

@property ProfileViewController *profileViewController;
@property PeopleViewController *peopleViewController;
@property SignViewController *signViewController;
@property SignNavigationViewController *signNavigationViewController;

@end
