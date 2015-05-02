//
//  SignUpViewController.h
//  webPays
//
//  Created by Giuliano Giacaglia on 9/26/13.
//  Copyright (c) 2013 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Delegate.h"

@interface SignViewController : UIViewController <FBLoginViewDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) id<PlacesDelegate> placesDelegate;
-(void) reloadedUserInfo:(BOOL)success andError:(NSError *)error;
-(void) showBarrierError:(NSError *)error;
@property (nonatomic, assign) BOOL fetchingProfilePictures;

@end
