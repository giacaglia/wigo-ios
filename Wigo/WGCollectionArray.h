//
//  WGCollectionArray.h
//  Wigo
//
//  Created by Adam Eagle on 12/29/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WGCollection.h"

@interface WGCollectionArray : NSEnumerator <UICollectionViewDataSource, UITableViewDataSource>

@property NSMutableArray *collections;
@property NSInteger currentPosition;

+(WGCollectionArray *) initWithCollection:(WGCollection *) collection;
+(WGCollectionArray *) initWithCollections:(NSArray *) collections;

-(NSArray *) idArray;

-(NSArray *) deserialize;

@end
