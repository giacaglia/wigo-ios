//
//  HighlightsCollectionView.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 2/20/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import "HighlightsCollectionView.h"

#define sizeOfEachHighLightCell 84

@implementation HighlightsCollectionView

-(id)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}


- (void)setup {
    self.backgroundColor = UIColor.whiteColor;
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
    
//    [self setCollectionViewLayout: flow];
    self.pagingEnabled = NO;
    [self registerClass:[HighlightCell class] forCellWithReuseIdentifier:@"FaceCell"];
    
    self.dataSource = self;
    self.delegate = self;
    
    
    CGRect frame = self.bounds;
    frame.origin.y = -frame.size.height;
    UIView* whiteView = [[UIView alloc] initWithFrame:frame];
    whiteView.backgroundColor = UIColor.whiteColor;
    [self addSubview:whiteView];
    
    self.showsVerticalScrollIndicator = NO;
    self.scrollEnabled = YES;
    self.alwaysBounceVertical = YES;
    self.bounces = YES;
}

@end

@implementation HighlightCell


@end




@implementation HighlightsFlowLayout

- (id)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    
    return self;
}


- (void)setup
{
    self.itemSize = CGSizeMake(sizeOfEachHighLightCell, sizeOfEachHighLightCell);
    self.sectionInset = UIEdgeInsetsMake(0, 10, 10, 10);
    self.minimumLineSpacing = 0;
    self.minimumInteritemSpacing = 0;
    self.scrollDirection = UICollectionViewScrollDirectionVertical;
}

@end
