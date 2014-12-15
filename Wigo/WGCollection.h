//
//  WGCollection.h
//  Wigo
//
//  Created by Adam Eagle on 12/15/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WGObject.h"

@interface WGCollection : NSMutableArray

-(void)setHasNextPage:(BOOL)hasNextPage;
-(void)setNextPage:(NSString *)nextPage;

-(BOOL)hasNextPage;
-(NSString *)nextPage;

@end