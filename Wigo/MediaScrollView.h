//
//  ImagesScrollView.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 11/4/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IQMediaPickerController.h"
#import <MediaPlayer/MediaPlayer.h>


@protocol MediaScrollViewDelegate
@end

@interface MediaScrollView : UICollectionView <UICollectionViewDataSource>

@property (nonatomic, strong) NSMutableArray *eventMessages;
@property (nonatomic, assign) id<IQMediaPickerControllerDelegate> controllerDelegate;
@property (nonatomic, strong) id<MediaScrollViewDelegate> mediaDelegate;
@property (nonatomic, strong) NSNumber *index;

- (void)closeView;
-(void)scrolledToPage:(int)page;
- (void)removeMediaAtPage:(int)page;
@end


@interface MediaFlowLayout : UICollectionViewFlowLayout
@end

@interface MediaCell : UICollectionViewCell
@property (nonatomic, strong) UILabel *label;
- (void)updateUIForEventMessage:(NSDictionary *)eventMessage;
@property (nonatomic, strong) UILabel *numberOfVotesLabel;
@end

@interface ImageCell : MediaCell
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *label;
@end

@interface VideoCell : MediaCell
@property (nonatomic, strong) MPMoviePlayerController *moviePlayer;
@property (nonatomic, strong) UILabel *label;
@end

@interface CameraCell : UICollectionViewCell
@property (nonatomic, assign) BOOL controllerDelegateSet;
@property (nonatomic, strong) IQMediaPickerController *controller;
- (void)setControllerDelegate:(id)controllerDelegate;
@end
