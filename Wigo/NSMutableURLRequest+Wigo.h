//
//  NSMutableURLRequest+Wigo.h
//  Wigo
//
//  Created by Dennis Doughty on 7/17/14.
//  Copyright (c) 2014 Dennis Doughty. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableURLRequest (Wigo)

- (void)setWigoHeadersAndUserKey:(NSString *)userKey;

@end
