//
//  FacebookHelper.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 10/24/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FacebookSDK/FacebookSDK.h>

@interface FacebookHelper : NSObject

+ (FBGraphObject *)getFirstFacebookPhotoGreaterThanX:(int)X
                                         inPhotoArray:(FBGraphObject *)photoArray;

@end
