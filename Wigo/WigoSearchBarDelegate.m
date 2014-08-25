//
//  WigoSearchBarDelegate.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 7/25/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "WigoSearchBarDelegate.h"

@implementation WigoSearchBarDelegate

- (id)initWithContentParty:(Party *)contentParty {
    self = [super init];
    if (self) {
        self.contentParty = contentParty;
        self.filteredContentParty = [contentParty copy];
        self.isSearching = NO;
    }
    return self;
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateImageView" object:nil userInfo:@{@"hiden": @YES}];

//    _searchIconImageView.hidden = YES;
    self.isSearching = YES;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    if (![searchBar.text isEqualToString:@""]) {
        [UIView animateWithDuration:0.01 animations:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"updateImageView" object:nil userInfo:@{@"transform": @-62}];

//            _searchIconImageView.transform = CGAffineTransformMakeTranslation(-62,0);
        }  completion:^(BOOL finished){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"updateImageView" object:nil userInfo:@{@"hiden": @NO}];

//            _searchIconImageView.hidden = NO;
        }];
    }
    else {
        [UIView animateWithDuration:0.01 animations:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"updateImageView" object:nil userInfo:@{@"transform": @0}];

//            _searchIconImageView.transform = CGAffineTransformMakeTranslation(0,0);
        }  completion:^(BOOL finished){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"updateImageView" object:nil userInfo:@{@"hiden": @NO}];

//            _searchIconImageView.hidden = NO;
        }];
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self.filteredContentParty removeAllObjects];
    
    if([searchText length] != 0) {
        self.isSearching = YES;
        [self searchTableList:searchBar];
    }
    else {
        self.isSearching = NO;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadTableView" object:nil];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self searchTableList:searchBar];
}

- (void)searchTableList:(UISearchBar *)searchBar {
    NSString *searchString = searchBar.text;
    
    NSArray *contentNameArray = [self.contentParty getFullNameArray];
    for (int i = 0; i < [contentNameArray count]; i++) {
        NSString *tempStr = [contentNameArray objectAtIndex:i];
        NSArray *firstAndLastNameArray = [tempStr componentsSeparatedByString:@" "];
        for (NSString *firstOrLastName in firstAndLastNameArray) {
            NSComparisonResult result = [firstOrLastName compare:searchString options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch ) range:NSMakeRange(0, [searchString length])];
            if (result == NSOrderedSame && ![[_filteredContentParty getFullNameArray] containsObject:tempStr]) {
                [self.filteredContentParty addObject: [[_contentParty getObjectArray] objectAtIndex:i]];
            }
        }
    }
}



@end
