//
//  NSObject+WGNavigateParser.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 3/30/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kArrayNamesOfObjects @[@"group", @"user", @"event", @"message", @"eventmessage", @"notification"]
#define kObjectsKey @"objects"
#define kNameOfObjectKey @"nameOfObject"

@interface WGNavigateParser : NSObject

+ (NSDictionary *)dictionaryFromString:(NSString *)navigateString;
+ (NSString *)nameOfObjectToPresentFromString:(NSString *)navigateString;
+ (NSDictionary *)userInfoFromString:(NSString *)navigateString;
+ (NSDictionary *)objectsFromUserInfo:(NSDictionary *)userInfo;
+ (NSString *)nameOfObjectFromUserInfo:(NSDictionary *)userInfo;
+ (NSString *)applicationTabForObject:(NSString *)objectName;

@end
