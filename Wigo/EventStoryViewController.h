//
//  EventStoryViewController.h
//  Wigo
//
//  Created by Alex Grinman on 10/24/14.
//  Copyright (c) 2014 Alex Grinman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Globals.h"
@interface EventStoryViewController : UIViewController
@property (nonatomic, strong) Event *event;
@property (nonatomic, strong) NSMutableArray *eventMessages;

@end
