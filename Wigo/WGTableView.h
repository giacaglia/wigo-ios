//
//  WGTableView.h
//  Wigo
//
//  Created by Adam Eagle on 12/29/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WGCollectionArray.h"

@interface WGTableView : UITableView

@property WGCollectionArray *collections;

+(WGTableView *) initWithCollectionArray: (WGCollectionArray *) collections;
+(WGTableView *) initWithCollections: (NSArray *) collections;
+(WGTableView *) initWithCollection: (WGCollection *) collection;

@end
