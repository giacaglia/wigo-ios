//
//  WGDateSelectionView.h
//  Wigo
//
//  Created by Gabriel Mahoney on 6/2/15.
//  Copyright (c) 2015 Gabriel Mahoney. All rights reserved.
//


#import <UIKit/UIKit.h>

@interface WGDateSelectionView : UICollectionView <UICollectionViewDataSource,
UICollectionViewDelegate>

@property (nonatomic) NSDate *startDate;

+ (CGFloat)height;

@end

@interface WGDateSelectionCell : UICollectionViewCell

@property (nonatomic) NSDate *date;

@property (nonatomic) UILabel *dateLabel;
@property (nonatomic) UILabel *dayLabel;

+ (CGFloat)height;

@end

@interface WGHorizontalDatesFlowLayout : UICollectionViewFlowLayout

@end
