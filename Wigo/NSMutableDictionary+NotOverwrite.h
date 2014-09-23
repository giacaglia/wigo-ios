//
//  NSMutableDictionary+NotOverwrite.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 9/23/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NSMutableDictionary (NotOverwrite)
- (void)notNillsetValue:(id)value forKey:(NSString *)key;
- (void)notNillsetObject:(id)anObject forKey:(id<NSCopying>)aKey;
@end
