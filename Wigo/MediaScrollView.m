//
//  ImagesScrollView.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 11/4/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "MediaScrollView.h"
#import "Globals.h"
#import "EventMessagesConstants.h"

@interface MediaScrollView() {}
@property (nonatomic, strong) NSMutableArray *pageViews;

@property (nonatomic, strong) MPMoviePlayerController *lastMoviePlayer;
@property (nonatomic, strong) NSMutableDictionary *thumbnails;

@property (nonatomic, strong) UIView *chatTextFieldWrapper;
@property (nonatomic, strong) UILabel *addYourVerseLabel;
@property (nonatomic, strong) NSMutableSet *readPagesSet;
@end

@implementation MediaScrollView

- (id)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout {
    self = [super initWithFrame:frame collectionViewLayout:layout];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.backgroundColor = RGB(23, 23, 23);
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
    self.dataSource = self;
    [self registerClass:[VideoCell class] forCellWithReuseIdentifier:@"VideoCell"];
    [self registerClass:[ImageCell class] forCellWithReuseIdentifier:@"ImageCell"];
    [self registerClass:[CameraCell class] forCellWithReuseIdentifier:@"CameraCell"];
    
}

#pragma mark - UICollectionView Data Source

-(NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.eventMessages.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.pageViews) {
        self.pageViews = [[NSMutableArray alloc] initWithCapacity:self.eventMessages.count];
    }
    NSDictionary *eventMessage = [self.eventMessages objectAtIndex:indexPath.row];
    NSString *mimeType = [eventMessage objectForKey:@"media_mime_type"];
    NSString *contentURL = [eventMessage objectForKey:@"media"];
    if ([mimeType isEqualToString:kCameraType]) {
        CameraCell *cameraCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CameraCell" forIndexPath: indexPath];
        [cameraCell setControllerDelegate:self.controllerDelegate];
        [self.pageViews setObject:cameraCell.controller atIndexedSubscript:indexPath.row];
        return cameraCell;
    }
    else if ([mimeType isEqualToString:kImageEventType]) {
        ImageCell *myCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ImageCell" forIndexPath: indexPath];
        myCell.eventMessage = eventMessage;
        [myCell updateUI];
        NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/%@", [Profile cdnPrefix], contentURL]];
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        spinner.frame = CGRectMake(myCell.imageView.frame.size.width/4, myCell.imageView.frame.size.height/4, myCell.imageView.frame.size.width/2,  myCell.imageView.frame.size.height/2);
        [spinner startAnimating];
        [myCell.imageView setImageWithURL:imageURL
                                completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                                    [spinner stopAnimating];
        }];
        [self.pageViews setObject:myCell.imageView atIndexedSubscript:indexPath.row];
        return myCell;
    }
    else {
        VideoCell *myCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"VideoCell" forIndexPath: indexPath];
        myCell.eventMessage = eventMessage;
        [myCell updateUI];
        NSURL *videoURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/%@", [Profile cdnPrefix], contentURL]];
        myCell.moviePlayer.contentURL = videoURL;
        [self.pageViews setObject:myCell.moviePlayer atIndexedSubscript:indexPath.row];
        return myCell;
    }
}


- (void)closeView {
    if (self.lastMoviePlayer) {
        [self.lastMoviePlayer stop];
    }
//    [Network sendAsynchronousHTTPMethod:POST withAPIName:[NSString stringWithFormat:@"events/%@", eventMessageID] withHandler:^(NSDictionary *jsonResponse, NSError *error) {
//    }];

}



-(void)scrolledToPage:(int)page {
    if (!self.pageViews) {
        self.pageViews = [[NSMutableArray alloc] initWithCapacity:self.eventMessages.count];
        for (int i = 0 ; i < self.eventMessages.count; i++) {
            [self.pageViews addObject:[NSNull null]];
        }
    }

    [self performBlock:^(void){[self playVideoAtPage:page];}
            afterDelay:0.5
 cancelPreviousRequest:YES];
}


- (void)playVideoAtPage:(int)page {
    if (self.lastMoviePlayer)  [self.lastMoviePlayer stop];
    MPMoviePlayerController *theMoviePlayer = [self.pageViews objectAtIndex:page];
    if ([theMoviePlayer isKindOfClass:[MPMoviePlayerController class]] &&
        theMoviePlayer.playbackState != MPMoviePlaybackStatePlaying) {
        [theMoviePlayer play];
        self.lastMoviePlayer = theMoviePlayer;
    }
}

- (void)addReadPage:(int)page {
    if (!self.readPagesSet) {
        self.readPagesSet = [NSMutableSet new];
    }
    [self.readPagesSet addObject:@(page)];
}

- (void)removeMediaAtPage:(int)page {
    [self removeEventMessageAtPage:page];
    UIView *player = [self.pageViews objectAtIndex:page];
    if ([player isKindOfClass:[MPMoviePlayerController class]])    {
    }
    else {
        [UIView animateWithDuration:0.4 animations:^{
            player.alpha = 0.0f;
        } completion:^(BOOL finished) {
            [player removeFromSuperview];
        }];
    }
}

- (void)removeEventMessageAtPage:(int)page {
    NSDictionary *eventMessage = [self.eventMessages objectAtIndex:page];
    NSNumber *eventMessageID = [eventMessage objectForKey:@"id"];
    [Network sendAsynchronousHTTPMethod:DELETE withAPIName:[NSString stringWithFormat:@"eventmessages/%@", eventMessageID] withHandler:^(NSDictionary *jsonResponse, NSError *error) {
    }];
}

@end


@implementation MediaFlowLayout

- (id)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    
    return self;
}


- (void)setup
{
    self.itemSize = CGSizeMake(320, 568);
    self.minimumLineSpacing = 0;
    self.minimumInteritemSpacing = 0;
    self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
}

@end


@implementation VideoCell

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
    self.frame = CGRectMake(0, 0, 320, 568);
    self.backgroundColor = UIColor.clearColor;
    
    self.moviePlayer = [[MPMoviePlayerController alloc] init];
    self.moviePlayer.movieSourceType = MPMovieSourceTypeStreaming;
    self.moviePlayer.scalingMode = MPMovieScalingModeAspectFill;
    [self.moviePlayer setControlStyle: MPMovieControlStyleNone];
    self.moviePlayer.repeatMode = MPMovieRepeatModeOne;
    self.moviePlayer.shouldAutoplay = NO;
    [self.moviePlayer prepareToPlay];
    self.moviePlayer.view.frame = self.frame;
    [self.contentView addSubview:self.moviePlayer.view];
    
    self.label = [[UILabel alloc] initWithFrame:CGRectMake(0, 370, self.frame.size.width, 40)];
    self.label.font = [FontProperties mediumFont:17.0f];
    self.label.backgroundColor = RGBAlpha(0, 0, 0, 0.7f);
    self.label.textAlignment = NSTextAlignmentCenter;
    self.label.textColor = [UIColor whiteColor];
    self.label.hidden = YES;
    [self.contentView addSubview:self.label];
    [self.contentView bringSubviewToFront:self.label];
}


@end


@implementation ImageCell

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
    self.frame = CGRectMake(0, 0, 320, 568);
    self.backgroundColor = UIColor.clearColor;
    
    self.imageView = [[UIImageView alloc] initWithFrame:self.frame];
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.clipsToBounds = YES;
    [self.contentView addSubview:self.imageView];
    
    self.label = [[UILabel alloc] initWithFrame:CGRectMake(0, 370, self.frame.size.width, 40)];
    self.label.font = [FontProperties mediumFont:17.0f];
    self.label.backgroundColor = RGBAlpha(0, 0, 0, 0.7f);
    self.label.textAlignment = NSTextAlignmentCenter;
    self.label.textColor = [UIColor whiteColor];
    self.label.hidden = YES;
    [self.contentView addSubview:self.label];
    [self.contentView bringSubviewToFront:self.label];
}


@end


@implementation MediaCell

- (void)updateUI {
    if ([[self.eventMessage allKeys] containsObject:@"message"]) {
        NSString *message = [self.eventMessage objectForKey:@"message"];
        if (message && [message isKindOfClass:[NSString class]]) {
            self.label.hidden = NO;
            self.label.text = message;
        }
        else self.label.hidden = YES;
        if ([[self.eventMessage allKeys] containsObject:@"properties"]) {
            NSDictionary *properties = [self.eventMessage objectForKey:@"properties"];
            if (properties &&
                [properties isKindOfClass:[NSDictionary class]] &&
                [[properties allKeys] containsObject:@"yPosition"]) {
                NSNumber *yPosition = [properties objectForKey:@"yPosition"];
                self.label.frame = CGRectMake(0, [yPosition intValue], self.frame.size.width, 40);
            }
        }
    }
    
    User *user = [[User alloc] initWithDictionary:[self.eventMessage objectForKey:@"user"]];
    if (![user isEqualToUser:[Profile user]]) {
        if (!self.numberOfVotesLabel) {
            self.numberOfVotesLabel = [[UILabel alloc] initWithFrame:CGRectMake(320 - 40, 568 - 80, 20, 30)];
            self.numberOfVotesLabel.textColor = [UIColor whiteColor];
            self.numberOfVotesLabel.textAlignment = NSTextAlignmentCenter;
            self.numberOfVotesLabel.font = [FontProperties mediumFont:18.0f];
            [self.contentView addSubview:self.numberOfVotesLabel];
        }
        int votes = [[self.eventMessage objectForKey:@"up_votes"] intValue] - [[self.eventMessage objectForKey:@"down_votes"] intValue];
        self.numberOfVotesLabel.text = [[NSNumber numberWithInt:votes] stringValue];
        
        self.upVoteButton = [[UIButton alloc] initWithFrame:CGRectMake(320 - 46, 568 - 108, 36, 36)];
        UIImageView *upvoteImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 36, 36)];
        upvoteImageView.image = [UIImage imageNamed:@"upvote"];
        [self.upVoteButton addSubview:upvoteImageView];
        [self.upVoteButton addTarget:self action:@selector(upvotePressed:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:self.upVoteButton];
        
        self.downVoteButton = [[UIButton alloc] initWithFrame:CGRectMake(320 - 46, 568 - 54, 36, 36)];
        UIImageView *downVoteImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 36, 36)];
        downVoteImageView.image = [UIImage imageNamed:@"downvote"];
        [self.downVoteButton addSubview:downVoteImageView];
        [self.downVoteButton addTarget:self action:@selector(downvotePressed:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:self.downVoteButton];
        
        [self showVotes];
    }
    else {
        [self hideVotes];
    }
    
}

- (void)upvotePressed:(id)sender {
    [self updateNumberOfVotes:YES];
}

- (void)downvotePressed:(id)sender {
    [self updateNumberOfVotes:NO];
}

- (void)hideVotes {
    self.upVoteButton.hidden = YES;
    self.upVoteButton.enabled = NO;
    self.downVoteButton.hidden = YES;
    self.downVoteButton.enabled = NO;
    self.numberOfVotesLabel.hidden = YES;
}

- (void)showVotes {
    self.upVoteButton.hidden = NO;
    self.upVoteButton.enabled = YES;
    self.downVoteButton.hidden = NO;
    self.downVoteButton.enabled = YES;
    self.numberOfVotesLabel.hidden = NO;
}

- (void)updateNumberOfVotes:(BOOL)upvoteBool {
    NSNumber *votedUpNumber = [self.eventMessage objectForKey:@"vote"];
    if ([votedUpNumber intValue] == 1) {
        if (!upvoteBool) {
            NSMutableDictionary *mutableEventMessage = [NSMutableDictionary dictionaryWithDictionary:self.eventMessage];
            [mutableEventMessage setObject:@-1 forKey:@"vote"];
            NSNumber *upVotes = [mutableEventMessage objectForKey:@"up_votes"];
            upVotes = @([upVotes intValue] - 1);
            [mutableEventMessage setObject:upVotes forKey:@"up_votes"];
            NSNumber *downVotes = [mutableEventMessage objectForKey:@"down_votes"];
            downVotes = @([downVotes intValue] + 1);
            [mutableEventMessage setObject:downVotes forKey:@"down_votes"];
            self.eventMessage = [NSDictionary dictionaryWithDictionary:mutableEventMessage];
            [self updateUI];
            [self sendVote:upvoteBool];
        }
    }
    else {
        if (upvoteBool) {
            NSMutableDictionary *mutableEventMessage = [NSMutableDictionary dictionaryWithDictionary:self.eventMessage];
            [mutableEventMessage setObject:@1 forKey:@"vote"];
            NSNumber *upVotes = [mutableEventMessage objectForKey:@"up_votes"];
            upVotes = @([upVotes intValue] + 1);
            [mutableEventMessage setObject:upVotes forKey:@"up_votes"];
            NSNumber *downVotes = [mutableEventMessage objectForKey:@"down_votes"];
            downVotes = @([downVotes intValue] - 1);
            [mutableEventMessage setObject:downVotes forKey:@"down_votes"];
            self.eventMessage = [NSDictionary dictionaryWithDictionary:mutableEventMessage];
            [self updateUI];
            [self sendVote:upvoteBool];
        }
    }
}


- (void)sendVote:(BOOL)upvoteBool {
    NSNumber *eventMessageID = [self.eventMessage objectForKey:@"id"];
    NSDictionary *options = @{@"message" : eventMessageID, @"up_vote": @(upvoteBool)};
    [Network sendAsynchronousHTTPMethod:POST withAPIName:@"eventmessagevotes/"
                            withHandler:^(NSDictionary *jsonResponse, NSError *error) {
                            }
                            withOptions:options];

}

@end


@implementation CameraCell

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
    self.frame = CGRectMake(0, 0, 320, 568);
    self.backgroundColor = UIColor.clearColor;

    self.controller = [[IQMediaPickerController alloc] init];
    [self.controller setMediaType:IQMediaPickerControllerMediaTypePhoto];
    self.controller.view.frame = self.frame;
    [self.contentView addSubview:self.controller.view];
    
}

- (void)setControllerDelegate:(id)controllerDelegate {
    if (!self.controllerDelegateSet) {
        self.controller.delegate = controllerDelegate;
    }
    self.controllerDelegateSet = YES;
}


@end
