//
//  EventConversationViewController.h
//  Wigo
//
//  Created by Alex Grinman on 10/17/14.
//  Copyright (c) 2014 Alex Grinman. All rights reserved.
//

#import "ConversationViewController.h"
#import "Event.h"

@interface EventConversationViewController : UIViewController
- (id)initWithEvent: (Event *)event;
@end
