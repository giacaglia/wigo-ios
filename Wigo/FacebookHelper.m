//
//  FacebookHelper.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 10/24/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "FacebookHelper.h"

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

@end
