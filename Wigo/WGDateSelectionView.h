//
//  WGDateSelectionView.h
//  Wigo
//
//  Created by Gabriel Mahoney on 6/2/15.
//  Copyright (c) 2015 Gabriel Mahoney. All rights reserved.
//


#import <UIKit/UIKit.h>

@protocol WGDateSelectionDelegate;

@interface WGDateSelectionView : UICollectionView <UICollectionViewDataSource,
UICollectionViewDelegate>

@property (nonatomic,weak) id<WGDateSelectionDelegate> dateSelectionDelegate;

@property (nonatomic) NSDate *startDate;
@property (nonatomic) NSArray *dates;

- (void)updateWithStartDate:(NSString *)date events:(NSArray *)events;

+ (CGFloat)height;

@end

@interface WGDateSelectionCell : UICollectionViewCell

@property (nonatomic) NSDate *date;
@property (nonatomic) BOOL hasEvent;

@property (nonatomic) UILabel *dateLabel;
@property (nonatomic) UILabel *dayLabel;

+ (CGFloat)height;

@end

@interface WGHorizontalDatesFlowLayout : UICollectionViewFlowLayout

@end

@protocol WGDateSelectionDelegate <NSObject>

@optional
- (void)didSelectDate:(NSDate *)date;

@end
