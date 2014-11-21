//
//  GroupStats.h
//  Wigo
//
//  Created by Alex Grinman on 11/21/14.
//  Copyright (c) 2014 Alex Grinman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Globals.h"
#import "EngagementGraph.h"

@interface GroupStats : NSObject

@property (nonatomic, strong) NSNumber *todayUserCount;
@property (nonatomic, strong) NSNumber *weekUserCount;
@property (nonatomic, strong) NSNumber *monthUserCount;
@property (nonatomic, strong) NSNumber *allUsersCount;

@property (nonatomic, strong) EngagementGraph *dailyEngagement;
@property (nonatomic, strong) EngagementGraph *weeklyEngagement;
@property (nonatomic, strong) EngagementGraph *monthlyEngagement;

+ (void) loadStats: (void (^)(GroupStats *groupStats, NSError *error)) handler;

@end

