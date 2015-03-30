//
//  NSObject+WGNavigateParser.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 3/30/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import "WGNavigateParser.h"

#define kArrayNamesOfObjects @[@"group", @"user", @"event", @"message", @"eventmessage", @"notification"]
#define kObjectsKey @"objects"
#define kNameOfObjectKey @"nameOfObject"

@implementation WGNavigateParser : NSObject

+ (NSDictionary *)dictionaryFromString:(NSString *)navigateString {
    NSArray *parsedString = [navigateString componentsSeparatedByString:@"/"];
    parsedString  = [parsedString subarrayWithRange:NSMakeRange(1, parsedString.count -1)];
    NSMutableDictionary *navigateDictionary = [NSMutableDictionary new];
    NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    for (int i = 0; i < parsedString.count/2; i++) {
        NSString *name = [parsedString objectAtIndex:(2*i)];
        NSNumber * numberID = [f numberFromString:[parsedString objectAtIndex:(2*i + 1)]];
        [navigateDictionary setObject:numberID forKey:name];
    }
    return navigateDictionary;
}

+ (NSString *)nameOfObjectToPresentFromString:(NSString *)navigateString {
    NSArray *parsedString = [navigateString componentsSeparatedByString:@"/"];
    parsedString  = [parsedString subarrayWithRange:NSMakeRange(1, parsedString.count -1)];
    NSString *objectName = [parsedString objectAtIndex:(parsedString.count - 2)];
    return objectName;
}

+ (NSDictionary *)userInfoFromString:(NSString *)navigateString {
    NSDictionary *objectsDict = [WGNavigateParser dictionaryFromString:navigateString];
    NSString *nameOfObject = [WGNavigateParser nameOfObjectToPresentFromString:navigateString];
    NSDictionary *userInfo = @{kObjectsKey : objectsDict, kNameOfObjectKey: nameOfObject};
    return userInfo;
}

+ (NSDictionary *)objectsFromUserInfo:(NSDictionary *)userInfo {
    return [userInfo objectForKey:kObjectsKey];
}

+ (NSString *)nameOfObjectFromUserInfo:(NSDictionary *)userInfo {
    return [userInfo objectForKey:kNameOfObjectKey];
}

@end
