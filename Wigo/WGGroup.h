//
//  WGGroup.h
//  Wigo
//
//  Created by Adam Eagle on 1/7/15.
//  Copyright (c) 2015 Adam Eagle. All rights reserved.
//

#import "WGObject.h"
#import "WGCollection.h"

@interface WGGroup : WGObject

typedef void (^WGGroupSummaryResultBlock)(NSNumber *total, NSNumber *numGroups, NSNumber *private, NSNumber *public, NSError *error);

@property NSString *name;
@property NSNumber *locked;
@property NSNumber *verified;
@property NSNumber *rank;
@property NSNumber *unlockAt;
@property NSNumber *numMembers;
@property NSNumber *numEvents;

+(WGGroup *)serialize:(NSDictionary *)json;

+(void) getWaitlist:(WGCollectionResultBlock)handler;
+(void) getGroupSummary:(WGGroupSummaryResultBlock)handler;

@end
