//
//  WGCollectionView.m
//  Wigo
//
//  Created by Adam Eagle on 12/29/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import "WGCollectionView.h"

@implementation WGCollectionView

+(WGCollectionView *) initWithCollection: (WGCollection *) collection {
    WGCollectionView *newCollectionView = [WGCollectionView new];
    newCollectionView.collections = [WGCollectionArray initWithCollection:collection];
    [newCollectionView setDataSource: newCollectionView.collections];
    return newCollectionView;
}

+(WGCollectionView *) initWithCollections:(WGCollectionArray *)collections {
    WGCollectionView *newCollectionView = [WGCollectionView new];
    newCollectionView.collections = collections;
    [newCollectionView setDataSource: newCollectionView.collections];
    return newCollectionView;
}

+(WGCollectionView *) initWithCollectionArray: (NSArray *) collections {
    WGCollectionView *newCollectionView = [WGCollectionView new];
    newCollectionView.collections = [WGCollectionArray initWithCollections:collections];
    [newCollectionView setDataSource: newCollectionView.collections];
    return newCollectionView;
}

@end
