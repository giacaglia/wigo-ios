//
//  NSMutableDictionary+NotOverwrite.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 9/23/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "NSMutableDictionary+NotOverwrite.h"

@implementation NSMutableDictionary (NotOverwrite)

- (void)notNillsetObject:(id)anObject forKey:(id<NSCopying>)key {
    if (anObject)
        [self setObject:anObject forKey:key];
}

- (void)notNillsetValue:(id)value forKey:(NSString *)key {
    if (value)
        [self setValue:value forKey:key];
}

@end
