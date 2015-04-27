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
#import "Delegate.h"

@interface EventConversationViewController : UIViewController<UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, EventConversationDelegate>
- (void)highlightCellAtPage:(NSInteger)page animated:(BOOL)animated;
@property (nonatomic, strong) WGEvent *event;
@property (nonatomic, strong) WGCollection *eventMessages;
@property (nonatomic, strong) MediaScrollView *mediaScrollView;
@property (nonatomic, assign) NSInteger lastPage;
@property (nonatomic, strong) IBOutlet UICollectionView *facesCollectionView;
@property (nonatomic, strong) NSNumber *index;
@property (nonatomic, strong) NSNumber *numberOfPagesBefore;
@property (nonatomic, assign) BOOL isFetchingMessages;
@property (nonatomic, assign) BOOL isOldEvent;

#pragma mark - Delegate objects
@property (nonatomic, strong) id<StoryDelegate> storyDelegate;

#pragma mark - Posting objects
@property (nonatomic, assign) BOOL isFocusing;
@property (nonatomic, strong) UILabel *postingLabel;
@property (nonatomic, strong) UIView *loadingBanner;
@property (nonatomic, assign) BOOL isPeeking;

#pragma mark - Posting Buttons
@property (nonatomic, strong) UIButton *buttonCancel;
@property (nonatomic, strong) UIButton *buttonTrash;
@property (nonatomic, strong) UIImageView *backgroundBottom;
@property (nonatomic, strong) UILabel *numberOfVotesLabel;
@property (nonatomic, strong) UIImageView *downArrowImageView;
@property (nonatomic, strong) UIButton *upVoteButton;
@property (nonatomic, strong) UIImageView *upvoteImageView;
@end

@interface FaceCell : UICollectionViewCell
- (void) resetToInactive;
- (void)setToActiveWithNoAnimation;
@property (nonatomic, strong) WGUser *user;
@property (nonatomic, assign) BOOL isActive;
@property (nonatomic, strong) UIView *faceAndMediaTypeView;
@property (nonatomic, strong) UIImageView *faceImageView;
@property (nonatomic, strong) UIImageView *mediaTypeImageView;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
// For Transition
@property (nonatomic, assign) CGFloat startYPosition;
@property (nonatomic, assign) CGRect startFrame;
@property (nonatomic, strong) id<EventConversationDelegate> eventConversationDelegate;
@property (nonatomic, strong) UIView *holeView;
@property (nonatomic, strong) WGEventMessage *eventMessage;
@end

@interface FaceFlowLayout : UICollectionViewFlowLayout

@end