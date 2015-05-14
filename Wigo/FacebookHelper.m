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

+ (void) fetchProfilePicturesWithHandler:(PicturesHandler)handler {
    if (![FBSDKAccessToken currentAccessToken]) {
        handler(nil, NO);
        return;
    }
    
    [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me/albums" parameters:nil]
     startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
         if (error) {
             [[WGError sharedInstance] logError:error forAction:WGActionFacebook];
         }
         BOOL foundProfilePicturesAlbum = NO;
         FBGraphObject *resultObject = (FBGraphObject *)[result objectForKey:@"data"];
         for (FBGraphObject *album in resultObject) {
             if ([album[@"name"] isEqual:@"Profile Pictures"]) {
                 foundProfilePicturesAlbum = YES;
                 NSString *profilePicsAlbumID = (NSString *)album[@"id"];
                 [FacebookHelper get3ProfilePictures:profilePicsAlbumID
                                         withHandler:^(NSArray *imagesArray, BOOL success) {
                                             handler(imagesArray, success);
                                             return;
                 }];
                 break;
             }
         }
         if (!foundProfilePicturesAlbum) {
             NSMutableArray *profilePictures = [NSMutableArray new];
             NSString *profilePic = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?width=640&height=640", WGProfile.currentUser.facebookId];
             [profilePictures addObject:@{@"url": profilePic}];
             handler(profilePictures, YES);
             return;
         }
     }];
}

+ (void) get3ProfilePictures:(NSString *)albumID
                 withHandler:(PicturesHandler)handler {
    NSString *graphPath = [NSString stringWithFormat:@"/%@/photos", albumID];
    [[[FBSDKGraphRequest alloc] initWithGraphPath:graphPath
                                       parameters:nil]
     startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
         if (error) {
             [[WGError sharedInstance] logError:error forAction:WGActionFacebook];
             handler(nil, NO);
             return;
          }
         NSMutableArray *profilePictures = [NSMutableArray new];
         FBGraphObject *resultObject = result[@"data"];
         for (FBGraphObject *photoRepresentation in resultObject) {
             FBGraphObject *images = photoRepresentation[@"images"];
             FBGraphObject *newPhoto = [FacebookHelper getFirstFacebookPhotoGreaterThanX:600 inPhotoArray:images];
             FBGraphObject *smallPhoto = [FacebookHelper getFirstFacebookPhotoGreaterThanX:200 inPhotoArray:images];
             if (newPhoto) {
                 NSDictionary *newImage;
                 if (smallPhoto) {
                     newImage =
                        @{
                          @"url": [newPhoto objectForKey:@"source"],
                          @"id": [photoRepresentation objectForKey:@"id"],
                          @"type": @"facebook",
                          @"small": [smallPhoto objectForKey:@"source"]
                        };
                        }
                 else {
                     newImage =
                          @{
                            @"url": [newPhoto objectForKey:@"source"],
                            @"id": [photoRepresentation objectForKey:@"id"],
                            @"type": @"facebook",
                            };
                 }
                  [profilePictures addObject:newImage];
                  if (profilePictures.count == 1) {
                      WGProfile.currentUser.image = [profilePictures objectAtIndex:0];
                  }
                  if (profilePictures.count >= 3) {
                      handler(profilePictures, YES);
                      break;
                  }
             }
        }
        if (profilePictures.count == 0) {
          [profilePictures addObject:@{@"url": @"https://api.wigo.us/static/img/wigo_profile_gray.png"}];
        }
         handler(profilePictures, YES);
         return;
  }];
}




@end
