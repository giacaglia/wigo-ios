//
//  HighlightsCollectionView.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 2/20/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Globals.h"

@interface HighlightsCollectionView : UICollectionView

@end

@interface HighlightCell : UICollectionViewCell <UICollectionViewDataSource,
                                                UICollectionViewDelegate>
- (void) resetToInactive;
- (void)setToActiveWithNoAnimation;
- (void)updateUIToRead:(BOOL)read;
- (void)setStateForUser:(WGUser *)user;
@property (nonatomic, strong) WGUser *user;
@property (nonatomic, assign) BOOL rightLineEnabled;
@property (nonatomic, assign) BOOL leftLineEnabled;

@property (nonatomic, assign) BOOL isActive;
@property (nonatomic, strong) UIView *faceAndMediaTypeView;
@property (nonatomic, strong) UIImageView *faceImageView;
@property (nonatomic, strong) UIImageView *mediaTypeImageView;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) UIView *leftLine;
@property (nonatomic, strong) UIView *rightLine;

// For Transition
@property (nonatomic, assign) CGFloat startYPosition;
@property (nonatomic, assign) CGRect startFrame;
@property (nonatomic, strong) UIView *holeView;
@end

@interface HighlightsFlowLayout : UICollectionViewFlowLayout

@end