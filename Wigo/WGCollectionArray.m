//
//  WGCollectionArray.m
//  Wigo
//
//  Created by Adam Eagle on 12/29/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import "WGCollectionArray.h"

@implementation WGCollectionArray

+(WGCollectionArray *) initWithCollection:(WGCollection *) collection {
    WGCollectionArray* new = [WGCollectionArray new];
    new.collections = [[NSMutableArray alloc] initWithObjects:collection, nil];
    new.currentPosition = 0;
    return new;
}

+(WGCollectionArray *) initWithCollections:(NSArray *) collections {
    WGCollectionArray* new = [WGCollectionArray new];
    new.collections = [[NSMutableArray alloc] initWithArray:collections];
    new.currentPosition = 0;
    return new;
}

-(NSArray *) deserialize {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (WGCollection *collection in self.collections) {
        [array addObject:[collection deserialize]];
    }
    return array;
}

-(WGCollection *) collectionAtIndex:(NSInteger)index {
    return [self.collections objectAtIndex:index];
}

-(void) addCollection:(WGCollection *) collection {
    [self.collections addObject:collection];
}

-(void) removeAllCollections {
    self.collections = [[NSMutableArray alloc] init];
    self.currentPosition = 0;
}

-(NSArray *) idArray {
    NSMutableArray *ids = [[NSMutableArray alloc] init];
    for (WGCollection *collection in self.collections) {
        [ids addObjectsFromArray:[collection idArray]];
    }
    return ids;
}

-(NSInteger) count {
    return [self.collections count];
}

#pragma mark - Enumeration

-(id) nextObject {
    if (self.currentPosition >= [self.collections count]) {
        self.currentPosition = 0;
        return nil;
    }
    self.currentPosition += 1;
    return [self.collections objectAtIndex: (self.currentPosition - 1)];
}

-(NSArray *) allObjects {
    return [self.collections subarrayWithRange:NSMakeRange(self.currentPosition, [self.collections count] - self.currentPosition)];
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
