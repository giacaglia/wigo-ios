//
//  ImagesScrollView.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 11/4/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IQMediaPickerController.h"

@protocol MediaScrollViewDelegate
@end

@interface MediaScrollView : UICollectionView <UITextFieldDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) NSMutableArray *eventMessages;
@property (nonatomic, strong) IQMediaPickerController *controller;
@property (nonatomic, strong) id<MediaScrollViewDelegate> mediaDelegate;
@property (nonatomic, strong) NSNumber *index;

- (void)closeView;
-(void)scrolledToPage:(int)page;
- (void)removeMediaAtPage:(int)page;
@end


@interface MediaFlowLayout : UICollectionViewFlowLayout
@end

@interface MediaCell : UICollectionViewCell
@property (nonatomic, strong) UIImageView *coverMediaView;
@end