//
//  WGTableView.m
//  Wigo
//
//  Created by Adam Eagle on 12/29/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import "WGTableView.h"

@implementation WGTableView

#warning TODO: spec this out with Dennis

+(WGTableView *) initWithCollection: (WGCollection *) collection {
    WGTableView *newCollectionView = [WGTableView new];
    newCollectionView.collections = [WGCollectionArray initWithCollection:collection];
    [newCollectionView setDataSource: newCollectionView.collections];
    return newCollectionView;
}

+(WGTableView *) initWithCollections:(WGCollectionArray *)collections {
    WGTableView *newCollectionView = [WGTableView new];
    newCollectionView.collections = collections;
    [newCollectionView setDataSource: newCollectionView.collections];
    return newCollectionView;
}

+(WGTableView *) initWithCollectionArray: (NSArray *) collections {
    WGTableView *newCollectionView = [WGTableView new];
    newCollectionView.collections = [WGCollectionArray initWithCollections:collections];
    [newCollectionView setDataSource: newCollectionView.collections];
    return newCollectionView;
}

@end
