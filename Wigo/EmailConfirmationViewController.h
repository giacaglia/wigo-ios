//
//  EmailConfirmationViewController.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/28/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Delegate.h"

@interface EmailConfirmationViewController : UIViewController <UITextFieldDelegate>
@property (nonatomic, strong) UILabel *numberOfPeopleLabel;
@property (nonatomic, strong) id<PlacesDelegate> placesDelegate;
@end
