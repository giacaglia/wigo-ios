//
//  WGUserParser.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 4/15/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WGCollection.h"

@interface WGUserParser : NSObject
+(WGCollection *)usersFromText:(NSString *)text;
@end
