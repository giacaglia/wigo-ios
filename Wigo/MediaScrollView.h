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
#import "Event.h"
#import "Delegate.h"

@protocol MediaScrollViewDelegate
- (void)updateEventMessage:(NSDictionary *)eventMessage forCell:(UICollectionViewCell *)cell;
- (void)focusOnContent;
@end

@interface MediaScrollView : UICollectionView <UICollectionViewDataSource, MediaScrollViewDelegate, IQMediaPickerControllerDelegate>

@property (nonatomic, strong) Event *event;
@property (nonatomic, strong) NSMutableArray *eventMessages;
@property (nonatomic, assign) id<IQMediaPickerControllerDelegate> controllerDelegate;
@property (nonatomic, strong) id<MediaScrollViewDelegate> mediaDelegate;
@property (nonatomic, strong) id<EventConversationDelegate> eventConversationDelegate;
@property (nonatomic, strong) id<StoryDelegate> storyDelegate;
@property (nonatomic, assign) int minPage;
@property (nonatomic, strong) NSNumber *index;
@property (nonatomic, assign) int maxPage;
@property (nonatomic, assign) BOOL isFocusing;
@property (nonatomic, assign) BOOL isPeeking;
- (void)closeView;
-(void)scrolledToPage:(int)page;
- (void)removeMediaAtPage:(int)page;

#pragma mark - IQMediaPickerController  Delegate
@property (nonatomic, strong) MPMoviePlayerController *moviePlayer;
@property (nonatomic, strong) NSData *fileData;
@property (nonatomic, strong) NSDictionary *options;
@property (nonatomic, strong) NSString *type;
@end


@interface MediaFlowLayout : UICollectionViewFlowLayout
@end

@interface MediaCell : UICollectionViewCell
@property (nonatomic, assign) id <MediaScrollViewDelegate> mediaScrollDelegate;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) NSDictionary *eventMessage;
- (void)updateUI;
@property (nonatomic, strong) UILabel *numberOfVotesLabel;
@property (nonatomic, strong) UIButton *upVoteButton;
@property (nonatomic, strong) UIImageView *upvoteImageView;
@property (nonatomic, strong) UIButton *downVoteButton;
@property (nonatomic, strong) UIImageView *downvoteImageView;
@property (nonatomic, strong) UIButton *focusButton;
@property (nonatomic, strong) UIImageView *gradientBackgroundImageView;
- (void)focusOnContent;
@property (nonatomic, assign) BOOL isFocusing;
@property (nonatomic, assign) BOOL isPeeking;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@end


@interface PromptCell : MediaCell
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *titleTextLabel;
@property (nonatomic, strong) UILabel *subtitleTextLabel;
@property (nonatomic, strong) UIButton *actionButton;
@property (nonatomic, strong) UIButton *avoidAction;
@property (nonatomic, strong) UILabel *blackBackgroundLabel;
@property (nonatomic, strong) UIImageView *cameraAccessImageView;
@end

@interface ImageCell : MediaCell
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *label;
@end

@interface VideoCell : MediaCell
@property (nonatomic, strong) UIImageView *thumbnailImageView;
@property (nonatomic, strong) MPMoviePlayerController *moviePlayer;
@property (nonatomic, strong) UILabel *label;
@end

@interface CameraCell : UICollectionViewCell
@property (nonatomic, assign) BOOL controllerDelegateSet;
@property (nonatomic, strong) IQMediaPickerController *controller;
- (void)setControllerDelegate:(id)controllerDelegate;

@end
