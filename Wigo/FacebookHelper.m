//
//  FacebookHelper.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 10/24/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "FacebookHelper.h"
#import "WGProfile.h"

@implementation FacebookHelper

+ (FBGraphObject *)getFirstFacebookPhotoGreaterThanX:(int)X inPhotoArray:(FBGraphObject *)photoArray {
    int minHeight = 0;
    FBGraphObject *returnedPhoto;
    for (FBGraphObject *fbPhoto in photoArray) {
        int heightPhoto = [[fbPhoto objectForKey:@"height"] intValue];
        if (heightPhoto > X) {
            if (minHeight == 0) {
                returnedPhoto = fbPhoto;
                minHeight = heightPhoto;
            }
            else if (minHeight > heightPhoto) {
                returnedPhoto = fbPhoto;
                minHeight = heightPhoto;
            }
        }
    }
    
    // If the photo was fetched then returned it else return biggest res photo
    if (minHeight > 0) {
        return returnedPhoto;
    } else {
        int maxHeight = 0;
        for (FBGraphObject *fbPhoto in photoArray) {
            int heightPhoto = [[fbPhoto objectForKey:@"height"] intValue];
            if (heightPhoto > maxHeight) {
                returnedPhoto = fbPhoto;
                maxHeight = heightPhoto;
            }
        }
        return returnedPhoto;
    }
}

+ (NSString *)nameOfCollegeFromUser:(id<FBGraphUser>)fbGraphUser {
    if (fbGraphUser[@"education"]) {
        NSArray *schoolArray = ((NSArray *)fbGraphUser[@"education"]);
        NSArray *filteredArray = [schoolArray filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
            FBGraphObject *school = (FBGraphObject *)object;
            return ([school[@"type"] isEqual:@"College"]);
        }]];
        if (filteredArray.count > 0) {
            FBGraphObject *firstSchool = [filteredArray objectAtIndex:0];
            return [[firstSchool objectForKey:@"school"] objectForKey:@"name"];
        }
    }
    return nil;
}

+ (NSString *)nameOFWorkFromUser:(id<FBGraphUser>)fbGraphUser {
    if (fbGraphUser[@"work"]) {
        NSArray *workArray = fbGraphUser[@"work"];
        if (workArray.count > 0) {
            NSDictionary *employerDict = [workArray objectAtIndex:0];
            if (employerDict && [employerDict isKindOfClass:[NSDictionary class]]) {
                NSDictionary *details = [employerDict objectForKey:@"employer"];
                if (details && [details isKindOfClass:[NSDictionary class]]) {
                    if ([details.allKeys containsObject:@"name"]) {
                       return [details objectForKey:@"name"];
                    }
                }
            }
        }
    }
    return nil;
}

+ (void)fillProfileWithUser:(id<FBGraphUser>)fbGraphUser {
    WGProfile.currentUser.firstName = fbGraphUser[@"first_name"];
    WGProfile.currentUser.lastName = fbGraphUser[@"last_name"];
    if (fbGraphUser[@"birthday"]) WGProfile.currentUser.birthday = fbGraphUser[@"birthday"];
    NSString *collegeName = [FacebookHelper nameOfCollegeFromUser:fbGraphUser];
    if (collegeName) WGProfile.currentUser.education = collegeName;
    NSString *workName = [FacebookHelper nameOFWorkFromUser:fbGraphUser];
    if (workName) WGProfile.currentUser.work = workName;

    NSDictionary *userResponse = (NSDictionary *) fbGraphUser;
    if ([[userResponse allKeys] containsObject:@"gender"]) {
        WGProfile.currentUser.gender = [WGUser genderFromName:[userResponse objectForKey:@"gender"]];
    }
}



@end
