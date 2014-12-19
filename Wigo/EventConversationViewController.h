//
//  EventConversationViewController.h
//  Wigo
//
//  Created by Alex Grinman on 10/17/14.
//  Copyright (c) 2014 Alex Grinman. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "Globals.h"
#import "MediaScrollView.h"
#import "IQMediaPickerController.h"
#import "Delegate.h"

@interface EventConversationViewController : UIViewController<UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, EventConversationDelegate>
- (void)highlightCellAtPage:(NSInteger)page;
@property (nonatomic, strong) Event *event;
@property (nonatomic, strong) NSMutableArray *eventMessages;
@property (nonatomic, strong) MediaScrollView *mediaScrollView;
@property (nonatomic, strong) IBOutlet UICollectionView *facesCollectionView;
@property (nonatomic, assign) id<IQMediaPickerControllerDelegate> controllerDelegate;
@property (nonatomic, strong) NSNumber *index;
@property (nonatomic, strong) id<StoryDelegate> storyDelegate;
@property (nonatomic, assign) BOOL isFocusing;
@property (nonatomic, strong) UILabel *postingLabel;
@property (nonatomic, strong) UIView *loadingBanner;
@end

@interface FaceCell : UICollectionViewCell

- (void) resetToInactive;
- (void)setToActiveWithNoAnimation;
- (void)updateUIToRead:(BOOL)read;
@property (nonatomic, assign) BOOL rightLineEnabled;
@property (nonatomic, assign) BOOL leftLineEnabled;

@property (nonatomic, assign) BOOL isActive;
@property (nonatomic, strong) UIView *faceAndMediaTypeView;
@property (nonatomic, strong) UIImageView *faceImageView;
@property (nonatomic, strong) UIImageView *mediaTypeImageView;
@property (nonatomic, strong) UILabel *timeLabel;

@property (nonatomic, strong) UIView *leftLine;
@property (nonatomic, strong) UIView *rightLine;


@end

@interface FaceFlowLayout : UICollectionViewFlowLayout

@end