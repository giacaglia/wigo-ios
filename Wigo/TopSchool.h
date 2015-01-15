//
//  TopSchool.h
//  Wigo
//
//  Created by Alex Grinman on 1/15/15.
//  Copyright (c) 2015 Alex Grinman. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TopSchool : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSNumber *numberRegistered;

+ (TopSchool *) initWithDictionary: (NSDictionary *) obj;
@end
