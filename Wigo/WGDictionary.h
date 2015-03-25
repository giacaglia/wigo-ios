//
//  NSObject+WGDictionary.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 3/24/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WGDictionary : NSObject

/*!
 Returns a GAIDictionaryBuilder object with parameters specific to an event hit.
 */
+ (WGDictionary *)createActionWithName:(NSString *)viewName
                                action:(NSString *)action
                                 label:(NSString *)label
                                 value:(NSNumber *)value;

@end
