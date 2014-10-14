//
//  UINonStickyHeaderTableView.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 10/13/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "UINonStickyHeaderTableView.h"

@implementation UINonStickyHeaderTableView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (BOOL) allowsHeaderViewsToFloat {
    return YES;
}

@end
