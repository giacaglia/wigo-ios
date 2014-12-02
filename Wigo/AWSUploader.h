//
//  AWSUploader.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 11/4/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AWSUploader : NSObject

+ (void)uploadFields:(NSArray *)fields
       withActionURL:(NSString *)action
            withFile:(NSData *)fileData
         andFileName:(NSString *)filename
      withCompletion:(void(^)(void))callback;

+ (void)uploadFields:(NSArray *)fields
      withActionURL:(NSString *)action
           withFile:(NSData *)fileData
        andFileName:(NSString *)filename;

+ (NSString *)valueOfFieldWithName:(NSString *)name
                      ofDictionary:(NSArray *)fields;
@end
