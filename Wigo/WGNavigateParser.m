//
//  NSObject+WGNavigateParser.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 3/30/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import "WGNavigateParser.h"
#import "Globals.h"

@implementation WGNavigateParser : NSObject

+ (NSDictionary *)dictionaryFromString:(NSString *)navigateString {
    
    // remove leading or trailing slash
    
    if([navigateString hasPrefix:@"/"]) {
        navigateString = [navigateString substringFromIndex:1];
    }
    
    if([navigateString hasSuffix:@"/"]) {
        navigateString = [navigateString substringToIndex:navigateString.length-1];
    }
    
    NSArray *parsedString = [navigateString componentsSeparatedByString:@"/"];
    
    NSMutableDictionary *navigateDictionary = [NSMutableDictionary new];
    NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    
    
    // parse odd component strings as keys, even as values
    // -- or NSNull if the number of components is odd
    
    for (int i = 0; i < parsedString.count; i+=2) {
        
        NSString *name = [parsedString objectAtIndex:i];
        
        if(parsedString.count >= (i+2)) {
            NSString *numberID = [parsedString objectAtIndex:(i + 1)];
            [navigateDictionary setObject:numberID forKey:name];
        }
        else {
            [navigateDictionary setObject:[NSNull null] forKey:name];
        }
        
        
    }
    return navigateDictionary;
}

+ (NSString *)nameOfObjectToPresentFromString:(NSString *)navigateString {
    
    // remove leading or trailing slash
    
    if([navigateString hasPrefix:@"/"]) {
        navigateString = [navigateString substringFromIndex:1];
    }
    
    if([navigateString hasSuffix:@"/"]) {
        navigateString = [navigateString substringToIndex:navigateString.length-1];
    }
    
    NSArray *parsedString = [navigateString componentsSeparatedByString:@"/"];
    
    NSString *objectName;
    if(parsedString.count % 2 == 0) {
        objectName = [parsedString objectAtIndex:(parsedString.count - 2)];
    }
    else {
        objectName = [parsedString lastObject];
    }
    
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

// return the name of the root tab for a given object to display

+ (NSString *)applicationTabForObject:(NSString *)objectName {
    
    if([objectName isEqualToString:@"messages"] ||
       [objectName isEqualToString:@"events"]) {
        return kWGTabHome;
    }
    else if([objectName isEqualToString:@"users"]) {
        return kWGTabDiscover;
    }
    return nil;
}

@end
