//
//  EventConversationViewController.m
//  Wigo
//
//  Created by Alex Grinman on 10/17/14.
//  Copyright (c) 2014 Alex Grinman. All rights reserved.
//

#import "EventConversationViewController.h"
#import "FontProperties.h"
#import "WGEventMessage.h"
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "WGProfile.h"
#import "MediaScrollView.h"
#import <MediaPlayer/MediaPlayer.h>
#import "EventMessagesConstants.h"
#import "ProfileViewController.h"
#import "PhotoSettingsViewController.h"
#import "WGEventLikesViewController.h"
#import "UIImage+ImageEffects.h"
#import "UIView+ViewToImage.h"

#define sizeOfEachFaceCell ([[UIScreen mainScreen] bounds].size.width - 20)/3
#define newSizeOfEachFaceCell ([[UIScreen mainScreen] bounds].size.width - 20)/4
@interface EventConversationViewController ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate, MediaScrollViewDelegate>
@property (nonatomic, strong) UIImage *userProfileImage;
@property (nonatomic, strong) NSIndexPath *currentActiveCell;
@property (nonatomic, assign) CGPoint collectionViewPointNow;
@property (nonatomic, assign) CGPoint imagesScrollViewPointNow;
@property (nonatomic, assign) BOOL facesHidden;
@property (nonatomic, strong) UIVisualEffectView *visualEffectView;
@property (nonatomic, strong) UIView *holeView;

// scroll view currently (or most recently) being dragged by the user
@property (nonatomic,weak) UIScrollView *currentDraggingView;

- (NSInteger)getCurrentPageForScrollView:(UIScrollView *)scrollView;

@end

@implementation EventConversationViewController

#pragma mark - ViewController Delegate

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadScrollView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deletePhoto) name:@"deletePhoto" object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];

    if (self.eventMessages.count > 0) {
        self.currentActiveCell = [NSIndexPath indexPathForItem:[self.index intValue] inSection:0];
    } else {
        self.currentActiveCell = nil;
    }

    [self highlightCellAtPage:self.index.intValue animated:YES];
    [self fetchEventMeta];
    [(FaceCell *)[self.facesCollectionView cellForItemAtIndexPath: self.currentActiveCell] setIsActive:YES];
    NSString *isPeekingString = (self.isPeeking) ? @"Yes" : @"No";
    [WGAnalytics tagEvent:@"Event Story Detail View" withDetails: @{@"isPeeking": isPeekingString}];
    [WGAnalytics tagView:@"event_story" withTargetUser:nil];
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.mediaScrollView scrollStoppedAtPage:self.index.intValue];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.index = [NSNumber numberWithInteger:[self getCurrentPageForScrollView:self.mediaScrollView]];
    [self.mediaScrollView stopCurrentVideo];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

#pragma mark UICollectionViewDataSource

-(NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.eventMessages.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    FaceCell *myCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"FaceCell" forIndexPath: indexPath];
    dispatch_barrier_async(dispatch_get_main_queue(), ^{
        [myCell resetToInactive];
        [myCell setLeftLineEnabled:(indexPath.row > 0)];
        [myCell setRightLineEnabled:(indexPath.row < self.eventMessages.count - 1)];
    });

    if (indexPath.row + 1 == self.eventMessages.count) {
        [self fetchNextMessages];
    }

    if (indexPath.row == 0 && self.eventMessages.previousPage) {
        [self fetchPreviousMessages];
    }
    WGEventMessage *eventMessage = (WGEventMessage *)[self.eventMessages objectAtIndex:[indexPath row]];
    myCell.eventMessage = eventMessage;
    if ([indexPath isEqual:self.currentActiveCell]) {
        myCell.isActive = YES;
    } else {
        myCell.isActive = NO;
    }
    return myCell;
}

#pragma mark - UICollectionViewDelegate


- (void)collectionView:(UICollectionView *)collectionView
       willDisplayCell:(UICollectionViewCell *)cell
    forItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if(collectionView == self.mediaScrollView) {
        if([cell isKindOfClass:[CameraCell class]]) {
            
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView
  didEndDisplayingCell:(UICollectionViewCell *)cell
    forItemAtIndexPath:(NSIndexPath *)indexPath {
    if(collectionView == self.mediaScrollView) {
        if([cell isKindOfClass:[VideoCell class]]) {
            VideoCell *videoCell = (VideoCell*)cell;
            [videoCell unloadVideoCell];
        }
        else if([cell isKindOfClass:[CameraCell class]]) {
            
        }
    }
}


-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView == self.facesCollectionView) {
        self.currentDraggingView = self.facesCollectionView;
        if (indexPath == self.currentActiveCell) {
            return;
        }
        NSString *isPeekingString = (self.isPeeking) ? @"Yes" : @"No";
        [WGAnalytics tagEvent:@"Event Conversation Face Tapped" withDetails: @{@"isPeeking": isPeekingString}];
        [WGAnalytics tagViewAction:@"photo_selected" atView:@"event_story" andTargetUser:nil atEvent:self.event andEventMessage:nil];

        FaceCell *cell = (FaceCell *)[collectionView cellForItemAtIndexPath: indexPath];
        cell.eventConversationDelegate = self;
        if (![self.currentActiveCell isEqual:indexPath]) {
            [(FaceCell *)[collectionView cellForItemAtIndexPath: self.currentActiveCell] setIsActive:NO];
        }
        [cell setIsActive: YES];
        self.currentActiveCell = indexPath;
        [self highlightCellAtPage:indexPath.row animated:YES];
    }
}

- (void)focusOnContent {
    if (!self.facesHidden) {
        [UIView animateWithDuration:0.5 animations:^{
            self.facesCollectionView.alpha = 0;
            self.facesCollectionView.transform = CGAffineTransformMakeTranslation(0, self.facesCollectionView.frame.size.height);
            self.buttonCancel.alpha = 0;
            self.buttonCancel.transform = CGAffineTransformMakeTranslation(0, -self.buttonCancel.frame.size.height);
            self.buttonTridot.alpha = 0;
            self.buttonTridot.transform = CGAffineTransformMakeTranslation(0, -self.buttonTridot.frame.size.height);
            self.upVoteButton.alpha = 0;
            self.upVoteButton.transform = CGAffineTransformMakeTranslation(0, -self.numberOfVotesLabel.frame.size.height);
            self.voteInfoButton.alpha = 0;
            self.voteInfoButton.transform = CGAffineTransformMakeTranslation(0, -self.voteInfoButton.frame.size.height);
            self.backgroundBottom.alpha = 0;
        } completion:^(BOOL finished) {
            self.facesHidden = YES;
        }];
    } else {
        [UIView animateWithDuration:0.5 animations:^{
            self.facesCollectionView.alpha = 1;
            self.facesCollectionView.transform = CGAffineTransformMakeTranslation(0,0);
            self.buttonCancel.alpha = 1;
            self.buttonCancel.transform = CGAffineTransformMakeTranslation(0, 0);
            self.buttonTridot.alpha = 1;
            self.buttonTridot.transform = CGAffineTransformMakeTranslation(0, 0);
            self.upVoteButton.alpha = 1;
            self.upVoteButton.transform = CGAffineTransformMakeTranslation(0, 0);
            self.voteInfoButton.alpha = 1;
            self.voteInfoButton.transform = CGAffineTransformMakeTranslation(0, 0);
            self.backgroundBottom.alpha = 1;
        } completion:^(BOOL finished) {
            self.facesHidden = NO;
        }];
    }
}

- (void)fetchEventMeta {
    __weak typeof(self) weakSelf = self;
    [self.event getMeta:^(BOOL success, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        dispatch_async(dispatch_get_main_queue(), ^{
            NSInteger page = [strongSelf getPageForScrollView:strongSelf.mediaScrollView toLeft:YES];
            if (page < strongSelf.eventMessages.count) {
                WGEventMessage *eventMessage = (WGEventMessage *)[strongSelf.eventMessages objectAtIndex:page];
                if (eventMessage.upVotes) {
                    
                    int votes = [eventMessage.upVotes intValue];
                    strongSelf.voteInfoButton.hidden = NO;
                    if(votes > 0) {
                        strongSelf.numberOfVotesLabel.text = [EventConversationViewController stringForLikes:votes];
                    }
                    else {
                        strongSelf.numberOfVotesLabel.text = @"";
                        strongSelf.voteInfoButton.hidden = YES;
                    }
                    
                }
                else {
                    self.numberOfVotesLabel.text = @"";
                    self.voteInfoButton.hidden = YES;
                }
                
                if (!eventMessage.vote) strongSelf.upvoteImageView.image =  [UIImage imageNamed:@"heart"];
                if (eventMessage.vote.intValue == 1) {
                    strongSelf.upvoteImageView.image = [UIImage imageNamed:@"upvoteFilled"];
                }
                else {
                    strongSelf.upvoteImageView.image = [UIImage imageNamed:@"heart"];
                }
            }
            
        });
    }];
}


- (void)fetchNextMessages {
    if (!self.eventMessages.nextPage) return;
    if (self.isFetchingMessages) return;
    self.isFetchingMessages = YES;
    
    __weak typeof(self) weakSelf = self;
    [self.eventMessages addNextPage:^(BOOL success, NSError *error) {
        __strong typeof(self) strongSelf = weakSelf;
        strongSelf.isFetchingMessages = NO;
        if (error) {
            [[WGError sharedInstance] logError:error forAction:WGActionLoad];
            return;
        }
        
        [strongSelf.mediaScrollView reloadData];
        [strongSelf.facesCollectionView reloadData];
    }];
}

- (void)fetchPreviousMessages {
    if (!self.eventMessages.previousPage) return;
    if (self.isFetchingMessages) return;
    self.isFetchingMessages = YES;
    
    self.numberOfPagesBefore = [NSNumber numberWithUnsignedInteger:self.eventMessages.count];
    __weak typeof(self) weakSelf = self;
    [self.eventMessages addPreviousPage:^(BOOL success, NSError *error) {
        __strong typeof(self) strongSelf = weakSelf;
        strongSelf.isFetchingMessages = NO;
        if (error) {
            [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
            [[WGError sharedInstance] logError:error forAction:WGActionLoad];
            return;
        }
        
        [strongSelf.mediaScrollView reloadData];
        [strongSelf.facesCollectionView reloadData];
        
        int indexBefore = (int)[strongSelf getPageForScrollView:strongSelf.mediaScrollView toLeft:YES];
        int differenceOfPages = (int)(strongSelf.eventMessages.count - strongSelf.numberOfPagesBefore.intValue);
        int newIndex = indexBefore + differenceOfPages;
        strongSelf.index = @(newIndex);
        [strongSelf highlightCellAtPage:newIndex animated:NO];
    }];
    
    
}

#define kActionPhotoVideo 0
#define kActionLibrary 1
#define kActionCancel 2

- (IBAction)tapPhotoVideoButton: (id) sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle: @"Add some fun media" delegate: self cancelButtonTitle: @"Cancel" destructiveButtonTitle: nil otherButtonTitles: @"Take a Photo or Video", @"Photo Library", nil];
    
    [actionSheet showInView: self.view];
}

    
#pragma mark - ActionSheet
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == kActionCancel) {
        return;
    }
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    
    if (buttonIndex == kActionPhotoVideo) {
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    } else {
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    
    picker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType: picker.sourceType];
    
    [self presentViewController:picker animated:YES completion:NULL];
}

#pragma mark - ScrollViewDelegate

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (scrollView == self.mediaScrollView)
        _imagesScrollViewPointNow = scrollView.contentOffset;
    else _collectionViewPointNow = scrollView.contentOffset;
    
    self.currentDraggingView = scrollView;
    
    if(scrollView == self.mediaScrollView) {
        int page = (int)[self getCurrentPageForScrollView:scrollView];
        [self.mediaScrollView startedScrollingFromPage:page];
    }
    else if(scrollView == self.facesCollectionView) {
        int page = (int)[self getCurrentPageForScrollView:scrollView];
        [self.mediaScrollView startedScrollingFromPage:page];
    }
}


- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    CGPoint pointNow;
    if (scrollView == self.mediaScrollView) pointNow = _imagesScrollViewPointNow;
    else pointNow = _collectionViewPointNow;
    if (scrollView.contentOffset.x < pointNow.x) {
        [self stoppedScrollingToLeft:YES forScrollView:scrollView];
    } else if (scrollView.contentOffset.x >= pointNow.x) {
        [self stoppedScrollingToLeft:NO forScrollView:scrollView];
    }
}

- (void)stoppedScrollingToLeft:(BOOL)leftBoolean forScrollView:(UIScrollView *)scrollView
{
    float width;
    if (scrollView == self.mediaScrollView) {
        width = [[UIScreen mainScreen] bounds].size.width;
    } else {
        width = sizeOfEachFaceCell;
    }
    NSInteger page = [self getPageForScrollView:scrollView toLeft:leftBoolean];
    [self highlightCellAtPage:page animated:YES];
}

- (NSInteger)getPageForScrollView:(UIScrollView *)scrollView toLeft:(BOOL)leftBoolean {
    float fractionalPage;
    if (scrollView == self.mediaScrollView) {
        CGFloat pageWidth = [[UIScreen mainScreen] bounds].size.width;
        fractionalPage = (self.mediaScrollView.contentOffset.x) / pageWidth;
    } else {
        CGFloat pageWidth = newSizeOfEachFaceCell; // you need to have a **iVar** with getter for scrollView
        fractionalPage = (self.facesCollectionView.contentOffset.x + newSizeOfEachFaceCell) / pageWidth;
    }
    NSInteger page;
    if (leftBoolean) {
        if (fractionalPage - floor(fractionalPage) < 0.95) {
            page = floor(fractionalPage);
        } else {
            page = ceil(fractionalPage);
        }
    } else {
        if (fractionalPage - floor(fractionalPage) < 0.05) {
            page = floor(fractionalPage);
        } else {
            page = ceil(fractionalPage);
        }
    }
    return page;
}

// get current page (rounded fractional page)

- (NSInteger)getCurrentPageForScrollView:(UIScrollView *)scrollView {
    float fractionalPage;
    if (scrollView == self.mediaScrollView) {
        CGFloat pageWidth = [[UIScreen mainScreen] bounds].size.width;
        fractionalPage = (self.mediaScrollView.contentOffset.x) / pageWidth;
    } else {
        CGFloat pageWidth = newSizeOfEachFaceCell; // you need to have a **iVar** with getter for scrollView
        fractionalPage = (self.facesCollectionView.contentOffset.x + newSizeOfEachFaceCell) / pageWidth;
    }
    // round fractionalPage
    return floorf(fractionalPage+0.5);
}

- (void)highlightCellAtPage:(NSInteger)page animated:(BOOL)animated {
    page = MAX(page, 0);
    page = MIN(page, self.eventMessages.count - 1);
    [self.mediaScrollView scrolledToPage:(int)page];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mediaScrollView setContentOffset:CGPointMake([[UIScreen mainScreen] bounds].size.width * page, 0.0f) animated:animated];
        [self.facesCollectionView setContentOffset:CGPointMake((newSizeOfEachFaceCell) * (page - 1.5), 0.0f) animated:animated];
    });
    [self hideOrShowFacesForPage:(int)page];
}

- (void)hideOrShowFacesForPage:(int)page {
    if (page + 1 == self.eventMessages.count) [self fetchNextMessages];
    if (page < self.eventMessages.count) {
        WGEventMessage *eventMessage = (WGEventMessage *)[self.eventMessages objectAtIndex:page];
//        self.buttonTrash.hidden = ![eventMessage.user isEqual:WGProfile.currentUser];
        if (eventMessage.upVotes) {
            
            int votes = [eventMessage.upVotes intValue];
            self.voteInfoButton.hidden = NO;
            if(votes > 0) {
                self.numberOfVotesLabel.text = [EventConversationViewController stringForLikes:votes];
            }
            else {
                self.numberOfVotesLabel.text = @"";
                self.voteInfoButton.hidden = YES;
            }
            
        }
        else {
            self.numberOfVotesLabel.text = @"";
            self.voteInfoButton.hidden = YES;
        }
        
        if (!eventMessage.vote) self.upvoteImageView.image =  [UIImage imageNamed:@"heart"];
        if (eventMessage.vote.intValue == 1) {
            self.upvoteImageView.image = [UIImage imageNamed:@"upvoteFilled"];
        }
        else {
            self.upvoteImageView.image = [UIImage imageNamed:@"heart"];
        }
        if (eventMessage.mediaMimeType && [eventMessage.mediaMimeType isEqualToString:kCameraType]) {
            self.buttonCancel.hidden = YES;
            self.facesHidden = NO;
            [self focusOnContent];
        } else if (eventMessage.mediaMimeType && ([eventMessage.mediaMimeType isEqualToString:kFaceImage] || [eventMessage.mediaMimeType isEqualToString:kNotAbleToPost])) {
        } else {
            self.facesHidden = YES;
            [self focusOnContent];
            
            self.buttonCancel.hidden = NO;
        }
        NSIndexPath *activeIndexPath = [NSIndexPath indexPathForItem:page  inSection: 0];

        // Set old face inactive and new one active.
        if (![activeIndexPath isEqual:self.currentActiveCell]) {
            [(FaceCell *)[self.facesCollectionView cellForItemAtIndexPath: self.currentActiveCell] setIsActive:NO];
        }
        [(FaceCell *)[self.facesCollectionView cellForItemAtIndexPath: activeIndexPath] setIsActive:YES];
            
        self.currentActiveCell = activeIndexPath;
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    
    if(scrollView == self.currentDraggingView) {
        int page = (int)[self getCurrentPageForScrollView:scrollView];
        [self.mediaScrollView scrollStoppedAtPage:page];
        self.currentDraggingView = nil;
    }
}

#pragma mark - G's code

- (void)loadScrollView {
    self.mediaScrollView = [[MediaScrollView alloc]
                            initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)
                            collectionViewLayout:[[MediaFlowLayout alloc] init]];
    self.mediaScrollView.eventMessages = self.eventMessages;
    self.mediaScrollView.event = self.event;
    self.mediaScrollView.mediaDelegate = self;
    self.mediaScrollView.eventConversationDelegate = self;
    self.mediaScrollView.storyDelegate = self.storyDelegate;
    self.mediaScrollView.isPeeking = self.isPeeking;
    self.mediaScrollView.delegate = self;
    self.mediaScrollView.firstCell = YES;
    [self.view addSubview:self.mediaScrollView];
    [self.view sendSubviewToBack:self.mediaScrollView];
    self.mediaScrollView.pagingEnabled = NO;
    
    self.backgroundBottom = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 100)];
    self.backgroundBottom.image = [UIImage imageNamed:@"backgroundTop"];
    [self.view addSubview:self.backgroundBottom];

    self.facesCollectionView.backgroundColor = UIColor.clearColor;
    FaceFlowLayout *flow = [[FaceFlowLayout alloc] init];
    self.facesCollectionView.showsHorizontalScrollIndicator = NO;
    [self.facesCollectionView setCollectionViewLayout: flow];
    self.facesCollectionView.contentInset = UIEdgeInsetsMake(0, newSizeOfEachFaceCell, 0, newSizeOfEachFaceCell);
    self.facesCollectionView.clipsToBounds = NO;
    self.facesCollectionView.pagingEnabled = NO;
    
    self.buttonCancel = [[UIButton alloc] initWithFrame:CGRectMake(0, 15, 86, 66)];
    UIImageView *cancelImageView = [[UIImageView alloc] initWithFrame:CGRectMake(15, 0, 27, 27)];
    cancelImageView.image = [UIImage imageNamed:@"closeModalView"];
    [self.buttonCancel addSubview:cancelImageView];
    [self.buttonCancel addTarget:self action:@selector(cancelPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.buttonCancel];
   
    self.buttonTridot = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 56 - 58 - 15, 0, 58, 65)];
    
    self.trashImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.buttonTridot.frame.size.width - 31, 15 + 10, 31, 8)];
    self.trashImageView.image = [UIImage imageNamed:@"tridot"];
    [self.buttonTridot addSubview:self.trashImageView];
    [self.buttonTridot addTarget:self action:@selector(trashPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.buttonTridot];
    
    self.upVoteButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 56 , 0, 56, 52)];
    [self.view addSubview:self.upVoteButton];
    self.upvoteImageView = [[UIImageView alloc] initWithFrame:CGRectMake(11, 15, 30, 28)];
    self.upvoteImageView.image = [UIImage imageNamed:@"heart"];
    [self.upVoteButton addSubview:self.upvoteImageView];
    [self.upVoteButton addTarget:self action:@selector(upvotePressed) forControlEvents:UIControlEventTouchUpInside];
    if (self.index && self.index.intValue >= 0 && self.index.intValue < [self.mediaScrollView numberOfItemsInSection:0]) {
        [self.mediaScrollView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.index.intValue inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
        self.mediaScrollView.index = self.index;
        self.mediaScrollView.minPage = self.index.intValue;
        self.mediaScrollView.maxPage = self.index.intValue;
    }
    
    
    self.numberOfVotesLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,
                                                                        0, 72.0, 20.0)];
    self.numberOfVotesLabel.textColor = UIColor.whiteColor;
    self.numberOfVotesLabel.textAlignment = NSTextAlignmentCenter;
    self.numberOfVotesLabel.font = [FontProperties boldFont:18.0f];
    
    self.downArrowImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"downArrow"]];
    self.downArrowImageView.frame = CGRectMake(0, 0, 36.0, 12.0);
    
    
    self.voteInfoButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 80.0, 50.0)];
    
    [self.voteInfoButton addTarget:self
                            action:@selector(showVotesPressed) forControlEvents:UIControlEventTouchUpInside];
    self.voteInfoButton.center = CGPointMake(self.view.frame.size.width/2.0, 0.0);
    CGRect frame = self.voteInfoButton.frame;
    frame.origin.y = 4.0;
    self.voteInfoButton.frame = frame;
    
    self.numberOfVotesLabel.center = CGPointMake(self.voteInfoButton.frame.size.width/2.0,0.0);
    frame = self.numberOfVotesLabel.frame;
    frame.origin.y = 4.0;
    self.numberOfVotesLabel.frame = frame;
    
    self.downArrowImageView.center = CGPointMake(self.voteInfoButton.frame.size.width/2.0,0.0);
    frame = self.downArrowImageView.frame;
    frame.origin.y = CGRectGetMaxY(self.numberOfVotesLabel.frame)+ 5;
    self.downArrowImageView.frame = frame;
    
    [self.voteInfoButton addSubview:self.numberOfVotesLabel];
    [self.voteInfoButton addSubview:self.downArrowImageView];
    
    [self.view addSubview:self.voteInfoButton];
}

- (void)upvotePressed {
    NSInteger page = [self getPageForScrollView:self.mediaScrollView toLeft:YES];
    WGEventMessage *eventMessage = (WGEventMessage *)[self.eventMessages objectAtIndex:page];
    NSNumber *vote = eventMessage.vote;
    if (vote.boolValue) {
        return;
    }
    if ([eventMessage objectForKey:@"id"] == nil) {
        return;
    }
    
    [WGAnalytics tagEvent:@"Up Vote Tapped"];
    NSString *vote_action = @"photo_vote";
    if ([eventMessage objectForKey:kMediaMimeTypeKey] && [[eventMessage objectForKey:kMediaMimeTypeKey] isEqualToString:kVideoEventType]) {
        vote_action = @"video_vote";
    }
    [WGAnalytics tagAction:vote_action atView:@"event_conversation" andTargetUser:nil atEvent:self.event andEventMessage:eventMessage];
    
    [UIView animateWithDuration:0.2f
                     animations:^{
                         self.upvoteImageView.image = [UIImage imageNamed:@"upvoteFilled"];
                         self.upvoteImageView.transform = CGAffineTransformMakeScale(1.5, 1.5);
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.2f
                                          animations:^{
                                              self.upvoteImageView.transform = CGAffineTransformIdentity;

                                          } completion:^(BOOL finished) {
                                              [self updateNumberOfVotes:YES];
                                          }];
                     }];
}

- (void)updateNumberOfVotes:(BOOL)upvoteBool {
    NSInteger page = [self getPageForScrollView:self.mediaScrollView toLeft:YES];
    WGEventMessage *eventMessage = (WGEventMessage *)[self.eventMessages objectAtIndex:page];

    NSNumber *votedUpNumber = [eventMessage objectForKey:@"vote"];
    if (!votedUpNumber) {
        eventMessage.vote = @1;
        eventMessage.upVotes = @([eventMessage.upVotes intValue] + 1);
        [eventMessage vote:upvoteBool forEvent:self.event withHandler:^(BOOL success, NSError *error) {
            if (error) {
                [[WGError sharedInstance] logError:error forAction:WGActionPost];
            }
        }];
        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
        f.numberStyle = NSNumberFormatterDecimalStyle;
        NSNumber *myNumber = [f numberFromString:self.numberOfVotesLabel.text];
        myNumber = [NSNumber numberWithInt:(myNumber.intValue + 1)];
        self.voteInfoButton.hidden = NO;
        self.numberOfVotesLabel.text = [EventConversationViewController stringForLikes:[myNumber intValue]];
    }
    
}

-(void) trashPressed {
    NSInteger page = [self getPageForScrollView:self.mediaScrollView toLeft:YES];
    if (page >= self.eventMessages.count || page < 0) return;
    WGEventMessage *eventMessage = (WGEventMessage *)[self.eventMessages objectAtIndex:page];
    if (!eventMessage.id) return;
    PhotoSettingsViewController *photoSettingsVc = [PhotoSettingsViewController new];
    photoSettingsVc.eventMsg = eventMessage;
    [self addChildViewController:photoSettingsVc];
    [self.view addSubview:photoSettingsVc.view];
}

-(void) deletePhoto {
    NSInteger page = [self getPageForScrollView:self.mediaScrollView toLeft:YES];
    if (page >= self.eventMessages.count || page < 0) return;
    WGEventMessage *eventMessage = (WGEventMessage *)[self.eventMessages objectAtIndex:page];
    if (!eventMessage.id || !eventMessage.user.isCurrentUser) return;
    [WGAnalytics tagEvent: @"Delete Highlight Tapped"];
    
    NSString *trash_action = @"photo_delete";
    if ([eventMessage objectForKey:kMediaMimeTypeKey] && [[eventMessage objectForKey:kMediaMimeTypeKey] isEqualToString:kVideoEventType]) {
        trash_action = @"video_delete";
    }
    
    [WGAnalytics tagAction:trash_action atView:@"event_conversation"
             andTargetUser:nil atEvent:self.event andEventMessage:eventMessage];
    [self.event removeMessage:eventMessage withHandler:^(BOOL success, NSError *error) {
        if (error) {
            [[WGError sharedInstance] logError:error forAction:WGActionDelete];
            return;
        }
    }];
    [self.eventMessages removeObject:eventMessage];
    [self.mediaScrollView.eventMessages removeObject:eventMessage];

    if (self.eventMessages.count == 0) {
        if (self.event.isExpired.boolValue) {
            [self.mediaScrollView closeViewWithHandler:^(BOOL success, NSError *error) {
                if (success) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"fetchEvents" object:nil];
                }
            }];
            [self dismissViewControllerAnimated:YES completion:nil];
        } else {
            [self.facesCollectionView reloadData];
            [self.mediaScrollView reloadData];
        }
    } else {
        [self.facesCollectionView reloadData];
        [self.mediaScrollView reloadData];
    }
    [self hideOrShowFacesForPage:(int) MIN(page, self.eventMessages.count - 1)];
}


- (void)cancelPressed:(id)sender {
    [WGAnalytics tagEvent: @"Close Highlights Tapped"];
    [WGAnalytics tagViewAction:@"close_highlights"
                        atView:@"event_conversation"
                 andTargetUser:nil atEvent:self.event andEventMessage:nil];
    [self.mediaScrollView closeViewWithHandler:^(BOOL success, NSError *error) {
        if (success) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"fetchEvents" object:nil];
        }
    }];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showVotesPressed {
    
    NSInteger page = [self getPageForScrollView:self.mediaScrollView toLeft:YES];
    
    if (page >= self.eventMessages.count || page < 0) {
        return;
    }
    
    WGEventMessage *eventMessage = (WGEventMessage *)[self.eventMessages objectAtIndex:page];
    if (!eventMessage.id) {
        return;
    }
    
    WGEventLikesViewController *likesController = [[WGEventLikesViewController alloc] init];
    
    
     UIImage* imageOfUnderlyingView = [[UIApplication sharedApplication].keyWindow convertViewToImage];
    
     imageOfUnderlyingView = [imageOfUnderlyingView applyBlurWithRadius:10
                                                              tintColor:RGBAlpha(0, 0, 0, 0.6f)
                                                  saturationDeltaFactor:1.3
                                                              maskImage:nil];
    
    likesController.backgroundImage = imageOfUnderlyingView;
    likesController.numberOfVotesLabel.text = self.numberOfVotesLabel.text;
    [likesController.dismissButton addTarget:self
                                     action:@selector(dismissLikesView) forControlEvents:UIControlEventTouchUpInside];
    
    [likesController getLikesForEvent:self.event eventMessage:eventMessage];
    
    [self presentViewController:likesController
                       animated:YES
                     completion:nil];
    
    
}

- (void)dismissLikesView {
    [self dismissViewControllerAnimated:YES
                             completion:^{
                                 
                             }];
}


+ (NSString *)stringForLikes:(NSInteger)likes {
    if(likes == 1) {
        return @"1 like";
    }
    else if(likes > 1) {
        return [NSString stringWithFormat:@"%ld likes", (long)likes];
    }
    else {
        return @"";
    }
}

#pragma mark -  EventConversation Delegate methods

- (void)addLoadingBanner {
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
    
//    self.view.transform = CGAffineTransformMakeTranslation(0, 20);
//    self.loadingBanner = [[UIView alloc] initWithFrame:CGRectMake(0, -20, self.view.frame.size.width, 20)];
//    self.loadingBanner.backgroundColor = UIColor.blackColor;
//    [self.view addSubview:self.loadingBanner];
//    
//    self.postingLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, -20, 150, 20)];
//    self.postingLabel.text = @"Posting...";
//    self.postingLabel.textColor = UIColor.whiteColor;
//    self.postingLabel.font = [FontProperties mediumFont:13.0f];
//    [self.view addSubview:self.postingLabel];
//    
//    [NSTimer scheduledTimerWithTimeInterval:0.2
//                                     target:self
//                                   selector:@selector(changePostingLabel)
//                                   userInfo:nil
//                                    repeats:YES];

}

- (void)changePostingLabel {
//    if ([self.postingLabel.text isEqualToString:@"Posting"]) {
//        self.postingLabel.text = @"Posting.";
//    }
//    else if ([self.postingLabel.text isEqualToString:@"Posting."]) {
//        self.postingLabel.text = @"Posting..";
//    }
//    else if ([self.postingLabel.text isEqualToString:@"Posting.."]) {
//        self.postingLabel.text = @"Posting...";
//    }
//    else if ([self.postingLabel.text isEqualToString:@"Posting..."]) {
//        self.postingLabel.text = @"Posting";
//    }
}

- (void)showErrorMessage {
//    self.loadingBanner.backgroundColor = RGB(196, 0, 0);
//    self.postingLabel.text = @"Wasn't able to post :-(";
//    
//    [self performBlock:^(void){[self removeBanner];}
//            afterDelay:5
// cancelPreviousRequest:YES];
    
}

- (void)showCompletedMessage {
//    self.loadingBanner.backgroundColor = RGB(245, 142, 29);
//    self.postingLabel.text = @"Posted!";
//    [self performBlock:^(void){[self removeBanner];}
//            afterDelay:5
// cancelPreviousRequest:YES];
}

- (void)removeBanner {
//    [UIView animateWithDuration:15 animations:^{} completion:^(BOOL finished) {
//        self.loadingBanner.hidden = YES;
//        self.postingLabel.hidden = YES;
//        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
//    }];
}

- (void)dismissView {
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - EventConversationDelegate

- (void)reloadUIForEventMessages:(NSMutableArray *)eventMessages {
    [self.facesCollectionView reloadData];
    self.mediaScrollView.eventMessages = self.eventMessages;
    [self.mediaScrollView reloadData];
    
    NSInteger page = [self getPageForScrollView:self.mediaScrollView toLeft:YES];
    [self.mediaScrollView scrolledToPage:(int)page];
    [self.mediaScrollView scrollStoppedAtPage:(int)page];
    [self hideOrShowFacesForPage:(int)page];
}

- (void)presentUser:(WGUser *)user withView:(UIView *)view withStartFrame:(CGRect)startFrame {
    CGPoint initialCenter = view.center;
    [UIView animateWithDuration:0.7f animations:^{
        view.layer.borderWidth = 0.0f;
        view.layer.cornerRadius = 0.0f;
        view.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width);
        view.center = CGPointMake(initialCenter.x, [UIScreen mainScreen].bounds.size.width/2);
    } completion:^(BOOL finished) {
        
        ProfileViewController* profileViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier: @"ProfileViewController"];
        profileViewController.user = user;
        if ([self isPeeking]) profileViewController.userState = OTHER_SCHOOL_USER_STATE;
        
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController: profileViewController];
        [self presentViewController:navController animated:NO completion:^{
            view.center = initialCenter;
            view.layer.borderWidth = 1.0f;
            view.layer.borderColor = UIColor.clearColor.CGColor;
            view.frame = startFrame;
            view.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
            view.layer.cornerRadius = startFrame.size.width/2;
        }];
    }];

}

- (void)createBlurViewUnderView:(UIView *)view {
    UIVisualEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    _visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    _visualEffectView.frame = self.view.frame;
    _visualEffectView.alpha = 0.0f;
    [self.view addSubview:_visualEffectView];
    [self.view bringSubviewToFront:self.facesCollectionView];

    self.facesCollectionView.clipsToBounds = NO;
    [view.superview.superview bringSubviewToFront:view.superview];
    [self.facesCollectionView bringSubviewToFront:[self.facesCollectionView cellForItemAtIndexPath:self.currentActiveCell]];
}

- (void)dimOutToPercentage:(float)percentage {
    if (percentage == 0) {
        [_visualEffectView removeFromSuperview];
        return;
    }
    else {
        float newAlpha = 1 - 1/percentage;
        _visualEffectView.alpha = newAlpha;
    }
}

- (void)presentHoleOnTopOfView:(UIView *)view {
    if (!_holeView) {
        _holeView = [UIView new];
        ProfileViewController* profileViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier: @"ProfileViewController"];
        profileViewController.user = WGProfile.currentUser;
        profileViewController.view.backgroundColor = [UIColor clearColor];
        self.modalPresentationStyle = UIModalPresentationCurrentContext;
        [self presentViewController:profileViewController animated:NO completion:nil];
    }
    _holeView.hidden = NO;

}

@end

#pragma mark - Face Classes

@implementation FaceCell

- (id) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder: aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame: frame];
    if (self) {
        [self setup];
    }
    
    return self;
}

- (void) setup {
    self.frame = CGRectMake(0, 0, newSizeOfEachFaceCell, sizeOfEachFaceCell);
    self.contentView.frame = self.frame;

    self.faceAndMediaTypeView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 2*(sizeOfEachFaceCell/3),  2*(sizeOfEachFaceCell/3))];
    self.faceAndMediaTypeView.alpha = 0.5f;
    [self.contentView addSubview:self.faceAndMediaTypeView];
    [self.contentView bringSubviewToFront:self.faceAndMediaTypeView];
 
    self.faceImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 0.6*sizeOfEachFaceCell, 0.6*sizeOfEachFaceCell)];
    self.faceImageView.center = self.contentView.center;
    self.faceImageView.backgroundColor = UIColor.blackColor;
    self.faceImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.faceImageView.layer.masksToBounds = YES;
    self.faceImageView.layer.borderColor = UIColor.whiteColor.CGColor;
    self.faceImageView.layer.borderWidth = 3.0;
    self.faceImageView.layer.cornerRadius = self.faceImageView.frame.size.width/2;
    [self.faceAndMediaTypeView addSubview: self.faceImageView];
    
    self.mediaTypeImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.faceImageView.frame.origin.x + self.faceImageView.frame.size.width, sizeOfEachFaceCell/5, sizeOfEachFaceCell/6, sizeOfEachFaceCell/6)];
    self.mediaTypeImageView.layer.masksToBounds = YES;
    self.mediaTypeImageView.backgroundColor = [UIColor blackColor];
    self.mediaTypeImageView.layer.cornerRadius = sizeOfEachFaceCell*0.08;
    self.mediaTypeImageView.layer.borderWidth = 3.0;
    self.mediaTypeImageView.layer.borderColor = UIColor.whiteColor.CGColor;
    self.mediaTypeImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.mediaTypeImageView.hidden = YES;
    [self.faceAndMediaTypeView addSubview:self.mediaTypeImageView];
    
    self.spinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(sizeOfEachFaceCell/4, sizeOfEachFaceCell/4, sizeOfEachFaceCell/2, sizeOfEachFaceCell/2)];
    self.spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
    [self.faceAndMediaTypeView addSubview:self.spinner];
    
    self.timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.faceImageView.frame.origin.y + self.faceImageView.frame.size.height, self.contentView.frame.size.width, 20)];
    self.timeLabel.center = CGPointMake(self.contentView.center.x, self.timeLabel.center.y);
    self.timeLabel.numberOfLines = 0;
    self.timeLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.timeLabel.textAlignment = NSTextAlignmentCenter;
    self.timeLabel.font = [FontProperties mediumFont:14];
    self.timeLabel.textColor = UIColor.whiteColor;
    self.timeLabel.layer.shadowColor = UIColor.blackColor.CGColor;
    self.timeLabel.layer.shadowOffset = CGSizeMake(0.0f, 0.5f);
    self.timeLabel.layer.shadowOpacity = 0.5;
    self.timeLabel.layer.shadowRadius = 0.5;
    self.timeLabel.alpha = 0.0f;
    [self.contentView addSubview:self.timeLabel];
    [self.contentView sendSubviewToBack:self.timeLabel];
    
//    self.leftLine = [[UIView alloc] initWithFrame: CGRectMake(0, self.contentView.center.y, self.contentView.center.x - 0.3*sizeOfEachFaceCell, 4)];
//    self.leftLine.alpha = 0.5f;
//    self.leftLine.backgroundColor = UIColor.whiteColor;
//    [self.contentView addSubview: self.leftLine];
    
//    self.rightLine = [[UIView alloc] initWithFrame: CGRectMake(self.contentView.center.x + self.faceImageView.frame.size.width/2, self.contentView.center.y, self.contentView.center.x - 0.3*sizeOfEachFaceCell, 4)];
//    self.rightLine.alpha = 0.5f;
//    self.rightLine.backgroundColor = UIColor.whiteColor;
//    [self.contentView addSubview: self.rightLine];

    _isActive = NO;
}

- (void)setRightLineEnabled:(BOOL)rightLineEnabled {
//    self.rightLine.hidden = !rightLineEnabled;
}

- (void)setLeftLineEnabled:(BOOL)leftLineEnabled {
//    self.leftLine.hidden = !leftLineEnabled;
}

- (void)panWasRecognized:(UIPanGestureRecognizer *)panner {
    float finalYEndPoint = [[UIScreen mainScreen] bounds].size.width/2;
    UIView *draggedView = panner.view;
    CGPoint offset = [panner translationInView:draggedView.superview];
    CGPoint center = draggedView.center;

    if (panner.state == UIGestureRecognizerStateBegan) {
        self.startYPosition = center.y;
        self.startFrame = draggedView.frame;
        [self.eventConversationDelegate createBlurViewUnderView:draggedView];
    }
    if (panner.state == UIGestureRecognizerStateEnded) {
        if (center.y > 150) {
            [self.eventConversationDelegate presentUser:self.user
                                               withView:draggedView
                                         withStartFrame:self.startFrame];
        }
        [self.eventConversationDelegate dimOutToPercentage:0];
    }
    else {
        if (_isActive) {
            if (center.y + offset.y > self.startYPosition) {
                if (offset.y >= 0) {
                    if (draggedView.center.y <= [[UIScreen mainScreen] bounds].size.width/2) {
                        draggedView.center = CGPointMake(center.x, center.y + offset.y);
                    }
                    else {
                        [self.eventConversationDelegate presentHoleOnTopOfView:draggedView];
                    }
                }
                else {
                    draggedView.center = CGPointMake(center.x, center.y + offset.y);
                }
            }
        }
    }
    if (_isActive) {
        if (draggedView.center.y > self.startYPosition && draggedView.center.y <= finalYEndPoint - 30) {
             float percentage = (finalYEndPoint - self.startYPosition)/(finalYEndPoint - draggedView.center.y);
            [self.eventConversationDelegate dimOutToPercentage:percentage];
            if (draggedView.center.y <= [[UIScreen mainScreen] bounds].size.width/2) {
                draggedView.transform = CGAffineTransformMakeScale(percentage, percentage);
            }
        }
    }
   
    [panner setTranslation:CGPointZero inView:draggedView.superview];
}

#warning NEED TO ADD FOR PEEKING
- (UIView *)copyOfProfileView:(UIView*)draggedView {
//    ProfileViewController* profileViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier: @"ProfileViewController"];
//    [profileViewController setStateWithUser: self.user];
//    profileViewController.user = self.user;
//    profileViewController.view.backgroundColor = [UIColor clearColor];
//    self.modalPresentationStyle = UIModalPresentationCurrentContext;
//    [self presentModalViewController:profileViewController animated:YES];

    return nil;
}



- (void) setIsActive:(BOOL)isActive {
    if (_isActive == isActive) {
        return;
    }
    if (isActive) {
        dispatch_barrier_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.5 delay: 0.0 options: UIViewAnimationOptionCurveLinear animations:^{
                [self setToActiveWithNoAnimation];
                self.timeLabel.alpha = 1.0f;
            } completion:^(BOOL finished) {}];
        });

    } else {
        dispatch_barrier_async(dispatch_get_main_queue(), ^{
            self.timeLabel.alpha = 0.0f;
            [UIView animateWithDuration: 0.5    animations:^{
                [self resetToInactive];
            }];
        });
    }
    _isActive = isActive;

}

- (void)setToActiveWithNoAnimation {
    self.faceAndMediaTypeView.alpha = 1.0f;
    self.faceImageView.transform = CGAffineTransformIdentity;
    self.mediaTypeImageView.frame = CGRectMake(0.65*sizeOfEachFaceCell, 0.15*sizeOfEachFaceCell, sizeOfEachFaceCell/5, sizeOfEachFaceCell/5);
    self.mediaTypeImageView.layer.cornerRadius = sizeOfEachFaceCell/10;
//    self.rightLine.frame = CGRectMake(self.contentView.center.x + self.faceImageView.frame.size.width/2, self.contentView.center.y, self.contentView.center.x - self.faceImageView.frame.size.width/2, 4);
//    self.leftLine.frame = CGRectMake(0, self.contentView.center.y, self.contentView.center.x - self.faceImageView.frame.size.width/2, 4);
}

- (void) resetToInactive {
    self.faceAndMediaTypeView.alpha = 0.5f;
    self.faceImageView.transform = CGAffineTransformMakeScale(0.75, 0.75);
    self.mediaTypeImageView.frame = CGRectMake(0.6*sizeOfEachFaceCell, 0.25*sizeOfEachFaceCell, sizeOfEachFaceCell/6.6, sizeOfEachFaceCell/6.6);
    self.mediaTypeImageView.layer.cornerRadius = sizeOfEachFaceCell/14;
//    self.rightLine.frame = CGRectMake(self.contentView.center.x + self.faceImageView.frame.size.width/2, self.contentView.center.y, self.contentView.center.x - self.faceImageView.frame.size.width/2, 4);
//    self.leftLine.frame = CGRectMake(0, self.contentView.center.y, self.contentView.center.x - self.faceImageView.frame.size.width/2, 4);
}

- (void)setUser:(WGUser *)user {
    _user = user;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.faceImageView setSmallImageForUser:user completed:nil];
    });
}

- (void)setEventMessage:(WGEventMessage *)eventMessage {
    _eventMessage = eventMessage;
    if ([eventMessage objectForKey:kMediaMimeTypeKey] && ([[eventMessage objectForKey:kMediaMimeTypeKey] isEqualToString:kCameraType] ||
        [[eventMessage objectForKey:kMediaMimeTypeKey] isEqualToString:kFaceImage] ||
        [[eventMessage objectForKey:kMediaMimeTypeKey] isEqualToString:kNotAbleToPost])
        ) {
        [self.faceImageView setImageWithURL:[NSURL URLWithString:@""] placeholderImage:[UIImage imageNamed:@"plusStory"]];
        self.mediaTypeImageView.hidden = YES;
        self.faceAndMediaTypeView.alpha = 0.4f;
    } else {
        self.faceAndMediaTypeView.alpha = 1.0f;
        WGUser *user = eventMessage.user;
        if (user) self.user = user;
        else self.user = WGProfile.currentUser;
        if ([eventMessage objectForKey:kMediaMimeTypeKey] &&
            [[eventMessage objectForKey:kMediaMimeTypeKey] isEqualToString:kImageEventType]) {
            self.mediaTypeImageView.image = [UIImage imageNamed:@"imageType"];
            self.mediaTypeImageView.hidden = YES;
        }
        else if ([eventMessage objectForKey:kMediaMimeTypeKey] &&
                 [[eventMessage objectForKey:kMediaMimeTypeKey] isEqualToString:kVideoEventType]) {
            self.mediaTypeImageView.image = [UIImage imageNamed:@"videoType"];
            self.mediaTypeImageView.hidden = YES;
        }
    }
    
    self.timeLabel.text = [eventMessage.created timeInLocaltimeString];
}

@end

@implementation FaceFlowLayout

- (id)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        [self setup];
    }
    
    return self;
}

- (void)setup
{
    self.itemSize = CGSizeMake(newSizeOfEachFaceCell, sizeOfEachFaceCell);
    self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    self.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);
    self.minimumInteritemSpacing = 0.0;
    self.minimumLineSpacing = 0.0;
}


@end