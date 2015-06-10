//
//  HighlightsCollectionView.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 2/20/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Globals.h"
#import "Delegate.h"
#define kHighlightsHeader @"HighlightsHeader"

@interface HighlightsCollectionView : UICollectionView <UICollectionViewDataSource,
                                                        UICollectionViewDelegate>

@property (nonatomic, strong) WGCollection *eventMessages;
@property (nonatomic, assign) BOOL cancelFetchMessages;
@property (nonatomic, strong) WGEvent *event;
@property (nonatomic, assign) BOOL showAddPhoto;
@property (nonatomic, strong) id<PlacesDelegate> placesDelegate;
@end

@interface AddPhotoCell : UICollectionViewCell  <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
+ (CGFloat) width;
+ (CGFloat) height;
@property (nonatomic, strong) UIImagePickerController *controller;
@property (nonatomic, strong) UIView *colorView;
@property (nonatomic, strong) UILabel *addPhotoLabel;
@end

@interface HighlightCell : UICollectionViewCell
+ (CGFloat)height;
- (void)updateUIToRead:(BOOL)read;
@property (nonatomic, strong) WGUser *user;
@property (nonatomic, strong) UIView *orangeDotView;

@property (nonatomic, strong) UIImageView *faceImageView;

// For Transition
@property (nonatomic, assign) CGFloat startYPosition;
@property (nonatomic, assign) CGRect startFrame;
@property (nonatomic, strong) UIView *holeView;

@property (nonatomic, strong) WGEventMessage *eventMessage;
@end

@interface HighlightsFlowLayout : UICollectionViewFlowLayout

@end