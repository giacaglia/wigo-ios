//
//  WGGroup.h
//  Wigo
//
//  Created by Adam Eagle on 1/7/15.
//  Copyright (c) 2015 Adam Eagle. All rights reserved.
//

#import "WGObject.h"

@interface WGGroup : WGObject

@property NSString *name;
@property NSNumber *locked;
@property NSNumber *unlockAt;
@property NSNumber *numMembers;
@property NSNumber *numEvents;

+(WGGroup *)serialize:(NSDictionary *)json;

@end
