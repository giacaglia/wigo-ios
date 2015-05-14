//
//  SignViewController.h
//
//  Created by Giuliano Giacaglia on 9/26/13.
//  Copyright (c) 2013 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Delegate.h"

@interface SignViewController : UIViewController <UIAlertViewDelegate>

@property (nonatomic, strong) id<PlacesDelegate> placesDelegate;
-(void) reloadedUserInfo:(BOOL)success andError:(NSError *)error;
@property (nonatomic, assign) BOOL fetchingProfilePictures;
@property (nonatomic, strong) UIVisualEffectView *blurredView;
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic, assign) BOOL pushed;
@property (nonatomic, assign) BOOL alertShown;


//Facebook properties
@property (nonatomic, strong) NSString *fbID;
@property (nonatomic, strong) NSString *profilePic;
@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic, strong) NSDictionary *properties;
@end
