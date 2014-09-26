//
//  InviteViewController.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 9/23/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Event.h"

@interface InviteViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

- (id)initWithEventName:(NSString *)eventName andID:(NSNumber *)eventID;

@end
