//
//  WGCache.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 4/17/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import "WGCache.h"

@implementation WGCache

+ (id)sharedCache {
    static WGCache *sharedCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCache = [[self alloc] init];
    });
    return sharedCache;
}

- (id)init {
    if (self = [super init]) {
        self.concurrentRefCacheQueue = dispatch_queue_create("us.wigo.refCacheQueue", DISPATCH_QUEUE_CONCURRENT);
        self.refCache = [NSMutableDictionary new];
    }
    return self;
}

-(NSArray *)allKeys {
    __block NSArray * keys;
    dispatch_sync(self.concurrentRefCacheQueue, ^{
        keys = self.refCache.allKeys;
    });
    return keys;
}


-(void)setObject:(id)object forKey:(NSString *)key {
    dispatch_barrier_async(self.concurrentRefCacheQueue, ^{
        [self.refCache setValue:object forKey:key];
    });
}

- (id)objectForKey:(NSString *)key {
    __block id value;
    dispatch_sync(self.concurrentRefCacheQueue, ^{
        value = [self.refCache objectForKey:key];
    });
    return value;
}

@end
