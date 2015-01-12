//
//  WigoCustomCell.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 9/11/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIImageViewShake.h"

@protocol WigoCustomCellDelegate
- (void)profileSegue:(id)sender;
- (void)tapPressed:(id)sender;
@end

@interface WigoCustomCell : UICollectionViewCell
@property (nonatomic, strong) IBOutlet UIImageView *userCoverImageView;
@property (nonatomic, strong) IBOutlet UIButton *profileButton;
@property (nonatomic, strong) IBOutlet UIButton *profileButton2;
@property (nonatomic, strong) IBOutlet UIButton *profileButton3;
@property (nonatomic, strong) IBOutlet UILabel *profileName;
@property (nonatomic, strong) IBOutlet UIButton *tapButton;
@property (nonatomic, strong) IBOutlet UIImageViewShake *tappedImageView;
@property (nonatomic, strong) IBOutlet UIImageView *favoriteSmall;

@property (nonatomic, assign) id <WigoCustomCellDelegate> delegate;
@end


