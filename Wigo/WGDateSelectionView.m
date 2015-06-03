//
//  WGDateSelectionView.m
//  Wigo
//
//  Created by Gabriel Mahoney on 6/2/15.
//  Copyright (c) 2015 Gabriel Mahoney. All rights reserved.
//

#import "WGDateSelectionView.h"
#import "FontProperties.h"


NSString * const WGDateSelectionCellIdentifier = @"WGDateSelectionCell";

@interface WGDateSelectionView ()

@property (nonatomic) NSInteger numberOfDates;
@property (nonatomic) NSArray *dates;

@end

@implementation WGDateSelectionView

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout {
    self = [super initWithFrame:frame collectionViewLayout:layout];
    if(self) {
        self.delegate = self;
        self.dataSource = self;
        
        [self registerClass:[WGDateSelectionCell class] forCellWithReuseIdentifier:WGDateSelectionCellIdentifier];
        self.numberOfDates = 10;
        
    }
    return self;
}

- (void)setStartDate:(NSDate *)startDate {
    _startDate = startDate;
    
    NSMutableArray *newDates  = [NSMutableArray arrayWithCapacity:self.numberOfDates];
    
    NSDate *d = self.startDate.copy;
    
    for(int i = 0; i < self.numberOfDates; i++) {
        [newDates addObject:d];
        
        d = [d dateByAddingTimeInterval:(60.0*60.0*24.0)];
    }
    self.dates = [NSArray arrayWithArray:newDates];
    
    [self reloadData];
}


+ (CGFloat)height {
    return 95.0;
}


#pragma mark UICollectionViewDataSource methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dates.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    WGDateSelectionCell *dateCell = (WGDateSelectionCell *)[collectionView dequeueReusableCellWithReuseIdentifier:WGDateSelectionCellIdentifier forIndexPath:indexPath];
    
    dateCell.date = self.dates[indexPath.row];
    return dateCell;
}

#pragma mark UICollectionViewDelegate methods


@end


@interface WGDateSelectionCell ()

@property (nonatomic) UIImageView *borderImageView;
@property (nonatomic) UIImageView *indicatorView;

@property (nonatomic) BOOL isHighlighting;

@end

@implementation  WGDateSelectionCell

- (instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    
    if(self) {
        self.borderImageView = [[UIImageView alloc] init];
        self.indicatorView = [[UIImageView alloc] init];
        
        self.dayLabel = [[UILabel alloc] init];
        self.dayLabel.backgroundColor = [UIColor clearColor];
        self.dayLabel.textAlignment = NSTextAlignmentCenter;
        self.dayLabel.font = [FontProperties lightFont:9.0];
        
        self.dateLabel = [[UILabel alloc] init];
        self.dateLabel.backgroundColor = [UIColor clearColor];
        self.dateLabel.textAlignment = NSTextAlignmentCenter;
        self.dateLabel.font = [FontProperties boldFont:28.0];
        
        [self.contentView addSubview:self.dayLabel];
        [self.contentView addSubview:self.dateLabel];
        [self.contentView addSubview:self.borderImageView];
        [self.contentView addSubview:self.indicatorView];
        
        self.isHighlighting = NO;
    }
    return self;
}

- (void)setDate:(NSDate *)date {
    _date = date;
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"EEE"];
    self.dayLabel.text = [[df stringFromDate:self.date] uppercaseString];
    
    [df setDateFormat:@"d"];
    self.dateLabel.text = [df stringFromDate:self.date];
    
    [self layoutSubviews];
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    [self layoutSubviews];
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    
    if(self.isHighlighting) {
        return;
    }
    
    if(self.highlighted) {
        self.isHighlighting = YES;
        [UIView animateWithDuration:0.1
                         animations:^{
                             self.transform = CGAffineTransformMakeScale(1.2, 1.2);
                         }
                         completion:^(BOOL finished) {
                             self.isHighlighting = NO;
                             
                             if(!self.highlighted) {
                                 
                                 [UIView animateWithDuration:0.1
                                                  animations:^{
                                                      self.transform = CGAffineTransformIdentity;
                                                  }
                                                  completion:^(BOOL finished) {
                                                      
                                                  }];
                             }
                         }];
        
    }
    else {
        [UIView animateWithDuration:0.1
                         animations:^{
                             self.transform = CGAffineTransformIdentity;
                         }];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    NSLog(@"laying out subvies");
    // not selected
    // 155, (227 border), 198 (small circle fill)
    
    // selected
    // 118, 190, 218
    
    UIColor *textColor = [UIColor colorWithWhite:(155.0/255.0) alpha:1];
    UIColor *indicatorColor = [UIColor colorWithWhite:(198.0/255.0) alpha:1];
    UIColor *borderColor = [UIColor colorWithWhite:(227.0/255.0) alpha:1];
    
    if (self.selected) {
        textColor = [FontProperties getBlueColor];
        indicatorColor = [FontProperties getBlueColor];
        borderColor = [FontProperties getBlueColor];
    }
    
    CGPoint center = self.contentView.center;
    
    self.borderImageView.frame = self.contentView.bounds;
    self.borderImageView.image = [WGDateSelectionCell ovalWithFrame:self.contentView.bounds
                                                                color:borderColor
                                                             drawMode:kCGPathStroke];
    
    self.indicatorView.frame = CGRectMake(0, 0, 8.0, 8.0);
    self.indicatorView.image = [WGDateSelectionCell ovalWithFrame:self.contentView.bounds
                                                              color:indicatorColor
                                                           drawMode:kCGPathFill];
    [self.dayLabel sizeToFit];
    [self.dateLabel sizeToFit];
    self.dayLabel.textColor = textColor;
    self.dateLabel.textColor = textColor;
    
    self.dayLabel.center = CGPointMake(center.x,
                                       13.0);
    
    self.dateLabel.center = CGPointMake(center.x,
                                        32.0);
    
    self.indicatorView.center = CGPointMake(center.x,
                                            53.0);
    
    
    
    
    
}

+ (CGFloat)height {
    return 62.0;
}

+ (UIImage *)ovalWithFrame:(CGRect)frame color:(UIColor *)color drawMode:(CGPathDrawingMode)drawMode {
    
    CGRect ovalRect = CGRectInset(frame, 0.5, 0.5);
    
    UIGraphicsBeginImageContextWithOptions(frame.size, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [[UIColor clearColor] setFill];
    CGContextFillRect(context, frame);
    
    CGContextSetLineWidth(context, 0.5);
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextAddEllipseInRect(context, ovalRect);
    CGContextDrawPath(context, drawMode);
    
    UIImage *ret = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return ret;
}


@end

@implementation WGHorizontalDatesFlowLayout

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
    self.itemSize = CGSizeMake([WGDateSelectionCell height], [WGDateSelectionCell height]);
    self.minimumLineSpacing = 15.0;
    self.minimumInteritemSpacing = 15.0;
    self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
}


@end

