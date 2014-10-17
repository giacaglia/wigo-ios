//
//  EventMessage.m
//  Wigo
//
//  Created by Alex Grinman on 10/17/14.
//  Copyright (c) 2014 Alex Grinman. All rights reserved.
//

#import "EventMessage.h"

@implementation EventMessage

@synthesize attributes,text,date,fromMe,media,thumbnail,type;

- (id)init
{
    if (self = [super init]) {
        self.date = [NSDate date];
    }
    
    return self;
}

@end