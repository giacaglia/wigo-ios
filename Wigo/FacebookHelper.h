//
//  FacebookHelper.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 10/24/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

@interface FacebookHelper : NSObject
typedef void (^PicturesHandler)(NSArray *imagesArray, BOOL success);


+(FBGraphObject *) getFirstFacebookPhotoGreaterThanX:(int)X
                                        inPhotoArray:(FBGraphObject *)photoArray;

+(NSString *) nameOfCollegeFromUser:(id<FBGraphUser>)object;
+(NSString *) nameOFWorkFromUser:(id<FBGraphUser>)fbGraphUser;
+(void) fillProfileWithUser:(id<FBGraphUser>)fbGraphUser;

+ (void) fetchProfilePicturesWithHandler:(PicturesHandler)handler;
+ (void) get5ProfilePictures:(NSString *)albumID
                 withHandler:(PicturesHandler)handler;

@end
