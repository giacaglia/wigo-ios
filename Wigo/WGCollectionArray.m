//
//  WGCollectionArray.m
//  Wigo
//
//  Created by Adam Eagle on 12/29/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import "WGCollectionArray.h"

@implementation WGCollectionArray

+(WGCollectionArray *)initWithCollection:(WGCollection *) collection {
    WGCollectionArray* new = [WGCollectionArray new];
    new.collections = [[NSMutableArray alloc] initWithObjects:collection, nil];
    return new;
}

+(WGCollectionArray *)initWithCollections:(NSArray *) collections {
    WGCollectionArray* new = [WGCollectionArray new];
    new.collections = [[NSMutableArray alloc] initWithArray:collections];
    return new;
}

#pragma mark - Data Source methods

-(NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    WGCollection *collection = [self.collections objectAtIndex:section];
    return [collection count];
}

-(NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return [self.collections count];
}

-(UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [collectionView dequeueReusableCellWithReuseIdentifier:@"WGCollectionViewCell" forIndexPath:indexPath];
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    WGCollection *collection = [self.collections objectAtIndex:section];
    return [collection count];
}

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.collections count];
}

-(UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [tableView dequeueReusableCellWithIdentifier:@"WGTableViewCell" forIndexPath:indexPath];
}

@end
