//
//  NSObject+WGGetter.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 3/27/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WGCollection.h"

@interface WGGetter : NSObject
- (void)fetchMessages;
@property (nonatomic, strong) WGCollection *messages;

- (void)fetchSuggestions;
@property (nonatomic, strong) WGCollection *suggestions;

- (void)fetchNotifications;
@property (nonatomic, strong) WGCollection *notifications;
@end
