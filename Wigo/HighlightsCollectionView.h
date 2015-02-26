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

@interface HighlightsCollectionView : UICollectionView <UICollectionViewDataSource,
                                                        UICollectionViewDelegate>

@property (nonatomic, strong) WGCollection *eventMessages;
@property (nonatomic, assign) BOOL cancelFetchMessages;
@property (nonatomic, strong) WGEvent *event;
@property (nonatomic, assign) BOOL showAddPhoto;
@property (nonatomic, strong) id<PlacesDelegate> placesDelegate;
@end

@interface AddPhotoCell : UICollectionViewCell  <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic, strong) UIImagePickerController *controller;
@end

@interface HighlightCell : UICollectionViewCell
+ (CGFloat) height;
- (void) resetToInactive;
- (void)setToActiveWithNoAnimation;
- (void)updateUIToRead:(BOOL)read;
- (void)setStateForUser:(WGUser *)user;
@property (nonatomic, strong) WGUser *user;


@property (nonatomic, assign) BOOL isActive;
@property (nonatomic, strong) UIImageView *faceImageView;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;

// For Transition
@property (nonatomic, assign) CGFloat startYPosition;
@property (nonatomic, assign) CGRect startFrame;
@property (nonatomic, strong) UIView *holeView;
@end

@interface HighlightsFlowLayout : UICollectionViewFlowLayout

@end