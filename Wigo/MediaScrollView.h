//
//  ImagesScrollView.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 11/4/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "WGEvent.h"
#import "Delegate.h"
#import "LLACircularProgressView.h"

#define UIMediaPickerText @"UIMediaPickerText"
#define UIMediaPickerPercentage @"UIMediaPickerPercentage"

@class VideoCell;

@protocol MediaScrollViewDelegate
- (void)focusOnContent;
- (void)upvotePressed;

@optional

- (MPMoviePlayerController *)getAvailableMoviePlayer;
- (void)freeMoviePlayer:(MPMoviePlayerController *)moviePlayer;

- (NSMutableDictionary *)videoMetaData;

- (void)updateEventMessage:(WGEventMessage *)eventMessage forCell:(UICollectionViewCell *)cell;
- (void)dismissView;
- (void)mediaPickerController:(UIImagePickerController *)controller
       startUploadingWithInfo:(NSDictionary *)info;
- (void)mediaPickerController:(UIImagePickerController *)controller
       didFinishMediaWithInfo:(NSDictionary *)info;
- (void)cancelPressed;

- (void)prepareVideoAtPage:(int)page;

- (void)markVideoPlayerIsSavingThumbnail:(BOOL)finished;

@end

@interface MediaScrollView : UICollectionView <UICollectionViewDataSource,
                                                MediaScrollViewDelegate>

@property (nonatomic, strong) MPMoviePlayerController *lastMoviePlayer;
@property (nonatomic, strong) WGEvent *event;
@property (nonatomic, strong) WGCollection *eventMessages;
@property (nonatomic, strong) id<MediaScrollViewDelegate> mediaDelegate;
@property (nonatomic, strong) id<EventConversationDelegate> eventConversationDelegate;
@property (nonatomic, strong) id<StoryDelegate> storyDelegate;
@property (nonatomic, assign) int minPage;
@property (nonatomic, strong) NSNumber *index;
@property (nonatomic, assign) int maxPage;
@property (nonatomic, assign) BOOL isFocusing;
@property (nonatomic, assign) BOOL firstCell;
@property (nonatomic, assign) BOOL isPeeking;
@property (nonatomic, assign) BOOL cameraPromptAddToStory;
@property (nonatomic, strong) NSString *filenameString;

@property (nonatomic, strong) MPMoviePlayerController *sharedMoviePlayer;
@property (nonatomic, weak) VideoCell *currentVideoCell;
@property (nonatomic, weak) VideoCell *lastVideoCell;

@property (nonatomic) BOOL videoPlayerIsSavingThumbnail;
@property (nonatomic) BOOL videoIsWaitingToPrepare;

@property (nonatomic) NSMutableDictionary *videoMetaDataInternal;

-(void) closeViewWithHandler:(BoolResultBlock)handler;
-(void) scrolledToPage:(int)page;
-(void) scrollStoppedAtPage:(int)page;
-(void) startedScrollingFromPage:(int)fromPage;


- (void)callbackFromUploadWithInfo:(NSDictionary *)callbackInfo
                       andFilename:(NSString *)filename;
@property (nonatomic, strong) NSMutableSet *tasksStillBeingUploaded;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) WGEventMessage *object;

#pragma mark - UIImagePickerDelegate  Delegate

@property (nonatomic, strong) NSData *fileData;
@property (nonatomic, strong) NSDictionary *options;
@property (nonatomic, strong) NSString *type;
@end


@interface MediaFlowLayout : UICollectionViewFlowLayout
@end

@interface MediaCell : UICollectionViewCell
@property (nonatomic, assign) id <MediaScrollViewDelegate> mediaScrollDelegate;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) WGEventMessage *eventMessage;

@property (nonatomic, strong) UILabel *numberOfVotesLabel;
@property (nonatomic, strong) UIButton *upVoteButton;
@property (nonatomic, strong) UIImageView *upvoteImageView;
@property (nonatomic, strong) UIView *touchableView;
@property (nonatomic, strong) UIImageView *gradientBackgroundImageView;

@property (nonatomic, assign) BOOL isFocusing;
@property (nonatomic, assign) BOOL isPeeking;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;

- (void)updateUI;
- (void)focusOnContent;
- (void)doubleTapToLike;

@end


@interface PromptCell : MediaCell
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *titleTextLabel;
@property (nonatomic, strong) UILabel *subtitleTextLabel;
@property (nonatomic, strong) UIButton *actionButton;
@property (nonatomic, strong) UIButton *avoidAction;
@property (nonatomic, strong) UILabel *blackBackgroundLabel;
@property (nonatomic, strong) UIView *cameraAccessView;
@end

@interface ImageCell : MediaCell
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *label;
@end

@interface VideoCell : MediaCell
@property (nonatomic, strong) UIImageView *thumbnailImageView;
@property (nonatomic, strong) UIImageView *thumbnailImageView2;
@property (nonatomic, strong) MPMoviePlayerController *moviePlayer;
@property (nonatomic, strong) NSURL *videoURL;

@property (nonatomic) BOOL isRequestingThumbnail;

@property (nonatomic) NSNumber *videoStartTime;
@property (nonatomic) UIImage *startingThumbnail;

@property (nonatomic) BOOL isCurrentVideoCell;

- (void)prepareVideo;
- (void)startVideo;
- (void)pauseVideo;
- (void)resumeVideo;
- (void)unloadVideoCell;

@end


@interface CameraCell : UICollectionViewCell<UINavigationControllerDelegate,
                                            UIImagePickerControllerDelegate,
                                            UIGestureRecognizerDelegate,
                                            UITextFieldDelegate>
@property (nonatomic, strong) UIView *overlayView;
@property (nonatomic, assign) id <MediaScrollViewDelegate> mediaScrollDelegate;
@property (nonatomic, strong) UIImagePickerController *controller;
@property (nonatomic, strong) UIButton *dismissButton;
@property (nonatomic, strong) UIButton *flashButton;
@property (nonatomic, strong) UIImageView *flashImageView;
@property (nonatomic, strong) UIButton *switchButton;
@property (nonatomic, strong) UIImageView *cameraImageView;
@property (nonatomic, strong) UIButton *pictureButton;
@property (nonatomic, strong) UIView *flashWhiteView;
@property (nonatomic, strong) UIImageView *captureImageView;
@property (nonatomic, assign) BOOL isRecording;
@property (nonatomic, assign) double videoTimerCount;
@property (nonatomic, assign) BOOL longGesturePressed;
@property (nonatomic, strong) LLACircularProgressView *circularProgressView ;
@property (nonatomic, strong) NSTimer *videoTimer;

@property (nonatomic, strong) UIImagePickerController *photoController;

@property (nonatomic, strong) UIImageView *previewImageView;
@property (nonatomic, strong) MPMoviePlayerController *previewMoviePlayer;
@property (nonatomic, strong) UITapGestureRecognizer *tapRecognizer;
@property (nonatomic, strong) UIPanGestureRecognizer *panRecognizer;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIButton *postButton;
@property (nonatomic, strong) NSMutableDictionary *info;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, assign) CGPoint percentPoint;
@property (nonatomic, assign) CGPoint startPoint;

@property (nonatomic) BOOL isTakingPicture;
@property (nonatomic,weak) AVCaptureSession *captureSession;

- (void)cellDidDisappear;

@end
