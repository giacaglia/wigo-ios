//
//  WGCollectionView.h
//  Wigo
//
//  Created by Adam Eagle on 12/29/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WGCollectionArray.h"

@interface WGCollectionView : UICollectionView

@property WGCollectionArray *collections;

+(WGCollectionView *) initWithCollectionArray: (WGCollectionArray *) collections;
+(WGCollectionView *) initWithCollections: (NSArray *) collections;
+(WGCollectionView *) initWithCollection: (WGCollection *) collection;

@end
