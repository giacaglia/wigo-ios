//
//  AWSUploader.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 11/4/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AWSUploader : NSObject

+ (void)uploadImage:(NSData *)image;

@end
