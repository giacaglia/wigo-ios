//
//  WGCache.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 4/17/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import <Foundation/Foundation.h>
#define kEventMessagesKey @"event_messages"

@interface WGCache : NSObject 

@property (nonatomic, retain) NSMutableDictionary *refCache;
@property dispatch_queue_t concurrentRefCacheQueue;

- (NSArray *)allKeys;
- (void)setObject:(id)object forKey:(NSString *)key;
- (id)objectForKey:(NSString *)key;
+ (id)sharedCache;

@end
