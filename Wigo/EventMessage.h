//
//  EventMessage.h
//  Wigo
//
//  Created by Alex Grinman on 10/17/14.
//  Copyright (c) 2014 Alex Grinman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Globals.h"

@interface EventMessage : NSObject

@property (nonatomic, strong) User *sender;
@property (nonatomic, strong) Event *event;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) UIImage *photo;
@property (nonatomic, strong) NSData *video;

@end
