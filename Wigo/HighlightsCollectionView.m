//
//  HighlightsCollectionView.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 2/20/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import "HighlightsCollectionView.h"

#define highlightCellName @"HighLightCellName"

@implementation HighlightsCollectionView

-(id)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}


- (void)setup {
    self.backgroundColor = UIColor.whiteColor;
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
    
//    [self setCollectionViewLayout: flow];
    self.pagingEnabled = NO;
    [self registerClass:[HighlightCell class] forCellWithReuseIdentifier:highlightCellName];
    
    self.dataSource = self;
    self.delegate = self;
    
    
    CGRect frame = self.bounds;
    frame.origin.y = -frame.size.height;
    UIView* whiteView = [[UIView alloc] initWithFrame:frame];
    whiteView.backgroundColor = UIColor.whiteColor;
    [self addSubview:whiteView];
    
    self.showsVerticalScrollIndicator = NO;
    self.scrollEnabled = YES;
    self.alwaysBounceVertical = YES;
    self.bounces = YES;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    HighlightCell *myCell = [collectionView dequeueReusableCellWithReuseIdentifier:highlightCellName forIndexPath: indexPath];
    myCell.contentView.frame = CGRectMake(0, 0, [HighlightCell height],[HighlightCell height]);
    myCell.faceAndMediaTypeView.frame = myCell.contentView.frame;
    
    myCell.leftLine.backgroundColor = RGB(237, 237, 237);
    myCell.leftLineEnabled = (indexPath.row %3 > 0) && (indexPath.row > 0);
    
    myCell.rightLine.backgroundColor = RGB(237, 237, 237);
    myCell.rightLineEnabled = (indexPath.row % 3 < 2) && (indexPath.row < self.eventMessages.count - 1);
    
    if ([indexPath row] + 1 == self.eventMessages.count && [self.eventMessages.hasNextPage boolValue]) {
        [self fetchEventMessages];
    }
    myCell.timeLabel.frame = CGRectMake(0, 0.75*[HighlightCell height] + 3, [HighlightCell height], 30);
    myCell.mediaTypeImageView.hidden = NO;
    myCell.faceImageView.center = CGPointMake(myCell.contentView.center.x, myCell.faceImageView.center.y);
    myCell.timeLabel.center = CGPointMake(myCell.contentView.center.x, myCell.timeLabel.center.y);
    myCell.faceImageView.layer.borderColor = UIColor.blackColor.CGColor;
    myCell.rightLine.frame = CGRectMake(myCell.contentView.center.x + myCell.faceImageView.frame.size.width/2, myCell.contentView.center.y, myCell.contentView.center.x - myCell.faceImageView.frame.size.width/2, 2);
    myCell.leftLine.frame = CGRectMake(0, myCell.contentView.center.y, myCell.contentView.center.x - myCell.faceImageView.frame.size.width/2, 2);
    
    WGEventMessage *eventMessage = (WGEventMessage *)[self.eventMessages objectAtIndex:[indexPath row]];
    WGUser *user = eventMessage.user;
    [myCell.mediaTypeImageView setSmallImageForUser:user completed:nil];
    
    NSString *contentURL;
    if (eventMessage.thumbnail) contentURL = eventMessage.thumbnail;
    else  contentURL = eventMessage.media;
    NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/%@", [WGProfile currentUser].cdnPrefix, contentURL]];
    [myCell.spinner startAnimating];
    __weak HighlightCell *weakCell = myCell;
    [myCell.faceImageView setImageWithURL:imageURL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakCell.spinner stopAnimating];
        });
    }];
    myCell.timeLabel.text = [eventMessage.created timeInLocaltimeString];
    myCell.timeLabel.textColor = RGB(59, 59, 59);
    myCell.faceAndMediaTypeView.alpha = 1.0f;
    
    if (eventMessage.isRead) {
        if ([eventMessage.isRead boolValue]) {
            [myCell updateUIToRead:YES];
        }
        else [myCell updateUIToRead:NO];
    }
    return myCell;
}

- (void)fetchEventMessages {
    
}

@end



@implementation HighlightCell

+ (CGFloat)height {
    return 84;
}

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
    self.frame = CGRectMake(0, 0, [HighlightCell height], [HighlightCell height]);
    self.contentView.frame = self.frame;
    
    self.faceAndMediaTypeView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 2*([HighlightCell height]/3),  2*([HighlightCell height]/3))];
    self.faceAndMediaTypeView.alpha = 0.5f;
    [self.contentView addSubview:self.faceAndMediaTypeView];
    [self.contentView bringSubviewToFront:self.faceAndMediaTypeView];
    
    self.faceImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 0.6*[HighlightCell height], 0.6*[HighlightCell height])];
    self.faceImageView.center = self.contentView.center;
    self.faceImageView.backgroundColor = UIColor.blackColor;
    self.faceImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.faceImageView.layer.masksToBounds = YES;
    self.faceImageView.layer.borderWidth = 1.0;
    self.faceImageView.layer.cornerRadius = self.faceImageView.frame.size.width/2;
    [self.faceAndMediaTypeView addSubview: self.faceImageView];
    
    self.leftLine = [[UIView alloc] initWithFrame: CGRectMake(0, self.contentView.center.y, self.contentView.center.x - 0.3*[HighlightCell height], 2)];
    self.leftLine.alpha = 0.5f;
    self.leftLine.backgroundColor = UIColor.whiteColor;
    [self.contentView addSubview: self.leftLine];
    
    self.rightLine = [[UIView alloc] initWithFrame: CGRectMake(self.contentView.center.x + self.faceImageView.frame.size.width/2, self.contentView.center.y, self.contentView.center.x - 0.3*[HighlightCell height], 2)];
    self.rightLine.alpha = 0.5f;
    self.rightLine.backgroundColor = UIColor.whiteColor;
    [self.contentView addSubview: self.rightLine];
    
    self.mediaTypeImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.faceImageView.frame.origin.x + self.faceImageView.frame.size.width, [HighlightCell height]/5, [HighlightCell height]/6, [HighlightCell height]/6)];
    self.mediaTypeImageView.layer.masksToBounds = YES;
    self.mediaTypeImageView.backgroundColor = [UIColor blackColor];
    self.mediaTypeImageView.layer.cornerRadius = [HighlightCell height]*0.08;
    self.mediaTypeImageView.layer.borderWidth = 1.0;
    self.mediaTypeImageView.layer.borderColor = UIColor.blackColor.CGColor;
    self.mediaTypeImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.mediaTypeImageView.hidden = YES;
    [self.faceAndMediaTypeView addSubview:self.mediaTypeImageView];
    
    self.spinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake([HighlightCell height]/4, [HighlightCell height]/4, [HighlightCell height]/2, [HighlightCell height]/2)];
    self.spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
    [self.faceAndMediaTypeView addSubview:self.spinner];
    
    self.timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.faceImageView.frame.origin.y + self.faceImageView.frame.size.height, self.contentView.frame.size.width, 20)];
    self.timeLabel.center = CGPointMake(self.contentView.center.x, self.timeLabel.center.y);
    self.timeLabel.numberOfLines = 0;
    self.timeLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.timeLabel.textAlignment = NSTextAlignmentCenter;
    self.timeLabel.font = [FontProperties lightFont:12];
    self.timeLabel.textColor = UIColor.whiteColor;
    self.timeLabel.layer.shadowColor = UIColor.blackColor.CGColor;
    self.timeLabel.layer.shadowOffset = CGSizeMake(0.0f, 0.5f);
    self.timeLabel.layer.shadowOpacity = 0.5;
    self.timeLabel.layer.shadowRadius = 0.5;
    [self.contentView addSubview:self.timeLabel];
    [self.contentView sendSubviewToBack:self.timeLabel];
    
    _isActive = NO;
}

//- (void)panWasRecognized:(UIPanGestureRecognizer *)panner {
//    float finalYEndPoint = [[UIScreen mainScreen] bounds].size.width/2;
//    UIView *draggedView = panner.view;
//    CGPoint offset = [panner translationInView:draggedView.superview];
//    CGPoint center = draggedView.center;
//    
//    if (panner.state == UIGestureRecognizerStateBegan) {
//        self.startYPosition = center.y;
//        self.startFrame = draggedView.frame;
//        [self.eventConversationDelegate createBlurViewUnderView:draggedView];
//    }
//    if (panner.state == UIGestureRecognizerStateEnded) {
//        if (center.y > 150) {
//            [self.eventConversationDelegate presentUser:self.user
//                                               withView:draggedView
//                                         withStartFrame:self.startFrame];
//        }
//        [self.eventConversationDelegate dimOutToPercentage:0];
//    }
//    else {
//        if (_isActive) {
//            if (center.y + offset.y > self.startYPosition) {
//                if (offset.y >= 0) {
//                    if (draggedView.center.y <= [[UIScreen mainScreen] bounds].size.width/2) {
//                        draggedView.center = CGPointMake(center.x, center.y + offset.y);
//                    }
//                    else {
//                        [self.eventConversationDelegate presentHoleOnTopOfView:draggedView];
//                    }
//                }
//                else {
//                    draggedView.center = CGPointMake(center.x, center.y + offset.y);
//                }
//            }
//        }
//    }
//    if (_isActive) {
//        if (draggedView.center.y > self.startYPosition && draggedView.center.y <= finalYEndPoint - 30) {
//            float percentage = (finalYEndPoint - self.startYPosition)/(finalYEndPoint - draggedView.center.y);
//            [self.eventConversationDelegate dimOutToPercentage:percentage];
//            if (draggedView.center.y <= [[UIScreen mainScreen] bounds].size.width/2) {
//                draggedView.transform = CGAffineTransformMakeScale(percentage, percentage);
//            }
//        }
//    }
//    
//    [panner setTranslation:CGPointZero inView:draggedView.superview];
//}
//
//#warning NEED TO ADD FOR PEEKING
//- (UIView *)copyOfProfileView:(UIView*)draggedView {
//    //    ProfileViewController* profileViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier: @"ProfileViewController"];
//    //    [profileViewController setStateWithUser: self.user];
//    //    profileViewController.user = self.user;
//    //    profileViewController.view.backgroundColor = [UIColor clearColor];
//    //    self.modalPresentationStyle = UIModalPresentationCurrentContext;
//    //    [self presentModalViewController:profileViewController animated:YES];
//    
//    return nil;
//}


- (void)setRightLineEnabled:(BOOL)rightLineEnabled {
    self.rightLine.hidden = !rightLineEnabled;
}

- (void)setLeftLineEnabled:(BOOL)leftLineEnabled {
    self.leftLine.hidden = !leftLineEnabled;
}

- (void) setIsActive:(BOOL)isActive {
    if (_isActive == isActive) {
        return;
    }
    if (isActive) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.5 delay: 0.0 options: UIViewAnimationOptionCurveLinear animations:^{
                [self setToActiveWithNoAnimation];
            } completion:^(BOOL finished) {}];
        });
        
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
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
    
    self.rightLine.frame = CGRectMake(self.contentView.center.x + self.faceImageView.frame.size.width/2, self.contentView.center.y, self.contentView.center.x - self.faceImageView.frame.size.width/2, 2);
    self.leftLine.frame = CGRectMake(0, self.contentView.center.y, self.contentView.center.x - self.faceImageView.frame.size.width/2, 2);
    
    self.mediaTypeImageView.frame = CGRectMake(0.65*[HighlightCell height], 0.15*[HighlightCell height], [HighlightCell height]/5, [HighlightCell height]/5);
    self.mediaTypeImageView.layer.cornerRadius = [HighlightCell height]/10;
}

- (void) resetToInactive {
    
    self.faceAndMediaTypeView.alpha = 0.5f;
    
    self.faceImageView.transform = CGAffineTransformMakeScale(0.75, 0.75);
    
    self.mediaTypeImageView.frame = CGRectMake(0.6*[HighlightCell height], 0.25*[HighlightCell height], [HighlightCell height]/6.6, [HighlightCell height]/6.6);
    self.mediaTypeImageView.layer.cornerRadius = [HighlightCell height]/13.2;
    
    self.rightLine.frame = CGRectMake(self.contentView.center.x + self.faceImageView.frame.size.width/2, self.contentView.center.y, self.contentView.center.x - self.faceImageView.frame.size.width/2, 2);
    self.leftLine.frame = CGRectMake(0, self.contentView.center.y, self.contentView.center.x - self.faceImageView.frame.size.width/2, 2);
}

- (void)updateUIToRead:(BOOL)read {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (read) {
            self.faceAndMediaTypeView.alpha = 0.4f;
        } else {
            self.faceAndMediaTypeView.alpha = 1.0f;
        }
    });
}

- (void)setStateForUser:(WGUser *)user {
    [self.faceImageView setSmallImageForUser:user completed:nil];
    self.user = user;
}

@end


@implementation HighlightsFlowLayout

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
    self.itemSize = CGSizeMake([HighlightCell height], [HighlightCell height]);
    self.sectionInset = UIEdgeInsetsMake(0, 10, 10, 10);
    self.minimumLineSpacing = 0;
    self.minimumInteritemSpacing = 0;
    self.scrollDirection = UICollectionViewScrollDirectionVertical;
}

@end
