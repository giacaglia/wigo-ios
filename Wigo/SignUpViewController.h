//
//  SignUpViewController.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/21/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Delegate.h"

@interface SignUpViewController : UIViewController <UITextFieldDelegate>
@property (nonatomic, strong) id<PlacesDelegate> placesDelegate;
@property (nonatomic, strong) UITextField *studentTextField;
@end
