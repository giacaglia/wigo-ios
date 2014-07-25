//
//  WigoSearchBarDelegate.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 7/25/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//



#import <UIKit/UIKit.h>
#import "Party.h"

@protocol WigoSearchBarDelegate <UISearchBarDelegate>

@end

@interface WigoSearchBarDelegate : UIViewController <UISearchDisplayDelegate>

- (id)initWithContentParty:(Party *)contentParty;
@property Party *contentParty;
@property Party *filteredContentParty;
@property BOOL isSearching;

@end
