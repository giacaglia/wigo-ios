//
//  NSString+URLEncoding.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 8/24/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <Foundation/Foundation.h>
@interface NSString (URLEncoding)
-(NSString *)urlEncodeUsingEncoding:(NSStringEncoding)encoding;
@end