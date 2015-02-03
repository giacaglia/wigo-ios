//
//  BatteryViewController.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 10/28/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Delegate.h"

@interface BatteryViewController : UIViewController
@property (nonatomic, strong) id<PlacesDelegate> placesDelegate;
@end
