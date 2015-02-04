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
@property (nonatomic, strong) NSTimer *fetchTimer;
@property (nonatomic, strong) NSArray *schoolSections;
@property (nonatomic, strong) NSNumber *groupID;
@property (nonatomic, strong) NSString *groupName;
@end
