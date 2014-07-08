//
//  EditProfileViewController.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/2/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PhotoViewController.h"
#import "FacebookAlbumTableViewController.h"
#import "FacebookImagesViewController.h"

@interface EditProfileViewController : UIViewController <UITextViewDelegate>

@property PhotoViewController *photoViewController;
@property FacebookImagesViewController *facebookImagesViewController;

@end
