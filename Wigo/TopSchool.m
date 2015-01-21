//
//  TopSchool.m
//  Wigo
//
//  Created by Alex Grinman on 1/15/15.
//  Copyright (c) 2015 Alex Grinman. All rights reserved.
//

#import "TopSchool.h"

@implementation TopSchool


+ (TopSchool *)initWithDictionary:(NSDictionary *) obj {
    
    TopSchool *school = [TopSchool new];
    school.name = obj[@"name"];
    school.numberRegistered = obj[@"num_members"];
    
    return school;
}

@end
