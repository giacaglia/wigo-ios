//
//  MainViewController.h
//
//  Created by Giuliano Giacaglia.
//

#import <UIKit/UIKit.h>
#import "ProfileViewController.h"
#import "SignViewController.h"
#import "SignNavigationViewController.h"
#import "WigoCustomCell.h"

@interface MainViewController : UIViewController <UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, WigoCustomCellDelegate>
{
    UICollectionView *_collectionView;
}

@property ProfileViewController *profileViewController;
@property SignViewController *signViewController;
@property SignNavigationViewController *signNavigationViewController;

@end
