//
//  EventPeopleScrollView.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 10/29/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "EventPeopleScrollView.h"
#import "Globals.h"
#import "UIView+ViewToImage.h"
#import "UIImage+ImageEffects.h"

@implementation EventPeopleScrollView

- (id)initWithEvent:(WGEvent *)event {
    if (self.widthOfEachCell == 0) self.widthOfEachCell = 0.9*(float)[UIScreen mainScreen].bounds.size.width/(float)5.5;
    self = [super initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, self.widthOfEachCell + 50) collectionViewLayout:[[ScrollViewLayout alloc] initWithWidth:self.widthOfEachCell]];
    if (self) {
        self.contentSize = CGSizeMake(15, self.widthOfEachCell + 40);
        self.showsHorizontalScrollIndicator = NO;
        self.delegate = self;
        self.dataSource = self;
        self.clipsToBounds = NO;
        self.event = event;
        [self registerClass:[ScrollViewCell class] forCellWithReuseIdentifier:kScrollViewCellName];
        [self registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kScrollViewHeader];
        [self addInviteButton];
    }
    return self;
}


- (void)addInviteButton {
    self.hiddenInviteButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.widthOfEachCell, self.widthOfEachCell)];
//    UIImageView *inviteImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.widthOfEachCell, self.widthOfEachCell)];
//    inviteImageView.image = [UIImage imageNamed:@"inviteButton"];
//    [self.hiddenInviteButton addSubview:inviteImageView];
    
    self.hiddenInviteButton.hidden = YES;
    self.hiddenInviteButton.transform = CGAffineTransformMakeScale(0.2f, 0.2f);
    [self addSubview:self.hiddenInviteButton];
}

+ (CGFloat) containerHeight {
    return (float)[[UIScreen mainScreen] bounds].size.width/(float)3.7;
}

-(void) setEvent:(WGEvent *)event {
    _event = event;
    [self reloadData];
    [self scrollToSavedPosition];
}


-(void) scrollToSavedPosition {
    if ([self.placesDelegate.eventOffsetDictionary objectForKey:[self.event.id stringValue]]) {
        self.contentOffset = CGPointMake([[self.placesDelegate.eventOffsetDictionary valueForKey:[self.event.id stringValue]] intValue], 0);
    }
}

-(void) saveScrollPosition {
    [self.placesDelegate.eventOffsetDictionary setObject:[NSNumber numberWithInt:self.contentOffset.x] forKey:[self.event.id stringValue]];
}

- (void)chooseUser:(id)sender {
//    UIButton *buttonSender = (UIButton *)sender;
//    int tag = (int)buttonSender.tag;
//    WGEventAttendee *attendee = (WGEventAttendee *)[self.event.attendees objectAtIndex:tag];
//    // self.eventOffset = self.contentOffset.x;
//    if (self.userSelectDelegate) {
//        [self.userSelectDelegate showUser: attendee.user];
//    } else {
//        [self.placesDelegate.eventOffsetDictionary setValue:[NSNumber numberWithInt:self.contentOffset.x]
//                                                     forKey:[self.event.id stringValue]];
//        [self.placesDelegate showUser:attendee.user];
//    }
    UIButton *buttonSender = (UIButton *)sender;
    int tag = (int)buttonSender.tag;
    UIImage* imageOfUnderlyingView = [[UIApplication sharedApplication].keyWindow convertViewToImage];
    imageOfUnderlyingView = [imageOfUnderlyingView applyBlurWithRadius:10
                                                             tintColor:RGBAlpha(255, 255, 255, 0.85f)
                                                 saturationDeltaFactor:1.3
                                                             maskImage:nil];
    
    self.eventPeopleModalViewController = [[EventPeopleModalViewController alloc] initWithEvent:self.event startIndex:tag andBackgroundImage:imageOfUnderlyingView];
    self.eventPeopleModalViewController.isPeeking = self.isPeeking;
    self.eventPeopleModalViewController.placesDelegate = self.placesDelegate;
    
    [self.placesDelegate showViewController:self.eventPeopleModalViewController];
}

- (void)goHerePressed:(id)sender {
    self.animationState = STARTED_ANIMATION_AND_NETWORK;
    __weak typeof(self) weakSelf = self;
    [self.placesDelegate startAnimatingAtTop:sender
                      finishAnimationHandler:^(UICollectionViewCell *cell) {
        weakSelf.hiddenInviteButton.hidden = NO;
        ScrollViewCell *scrollCell = (ScrollViewCell *)cell;
        [UIView animateWithDuration:1 animations:^{
            scrollCell.blueOverlayView.alpha = 1.0f;
            scrollCell.goHereLabel.alpha = 1.0f;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:1 animations:^{
                weakSelf.hiddenInviteButton.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
                scrollCell.blueOverlayView.alpha = 0.0f;
                scrollCell.goHereLabel.alpha = 0.0f;
                scrollCell.profileNameLabel.alpha = 0.5f;
                scrollCell.profileNameLabel.text = WGProfile.currentUser.firstName;
                weakSelf.transform = CGAffineTransformMakeTranslation(weakSelf.widthOfEachCell + 10, 0);
                weakSelf.hiddenInviteButton.transform = CGAffineTransformMakeTranslation(-self.widthOfEachCell, 0);
            } completion:^(BOOL finished) {
                UIButton *buttonSender = (UIButton *)sender;
                buttonSender.tag = 0;
                [weakSelf finishAnimationOrNetworkRequestForCell:scrollCell];
            }];
        }];
    } postingHandler:^(BOOL success, NSError *error) {
        [weakSelf finishAnimationOrNetworkRequestForCell:nil];
    }];

}

- (void)finishAnimationOrNetworkRequestForCell:(ScrollViewCell *)scrollCell {
    if (self.animationState == STARTED_ANIMATION_AND_NETWORK) {
        self.animationState = ONE_OF_THEM_IS_CONCLUDED;
    }
    else if (self.animationState == ONE_OF_THEM_IS_CONCLUDED) {
        self.animationState = BOTH_OF_THEM_ARE_DONE;
    }
    if (scrollCell != nil) self.scrollCell = scrollCell;
    
    
    if (self.animationState == BOTH_OF_THEM_ARE_DONE) {
        CGAffineTransform t = CGAffineTransformMakeScale(0.2f, 0.2f);
        self.hiddenInviteButton.transform = CGAffineTransformTranslate(t, 0, 0);
        self.transform = CGAffineTransformMakeTranslation(0, 0);
        self.hiddenInviteButton.hidden = YES;
        self.scrollCell.blueOverlayView.alpha = 0.8f;
        self.scrollCell.goHereLabel.alpha = 1.0f;
        [self.placesDelegate reloadTable];
    }
    
}


- (void)fetchEventAttendeesAsynchronous {
    if (!self.fetchingEventAttendees) {
        self.fetchingEventAttendees = YES;
        __weak typeof(self) weakSelf = self;
        if ([self.event.attendees.hasNextPage boolValue]) {
            [self.event.attendees addNextPage:^(BOOL success, NSError *error) {
                __strong typeof(self) strongSelf = weakSelf;
                if (error) {
                    [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                    [[WGError sharedInstance] logError:error forAction:WGActionLoad];
                    strongSelf.fetchingEventAttendees = NO;
                    return;
                }
                
                [strongSelf reloadData];
                [strongSelf saveScrollPosition];
                strongSelf.fetchingEventAttendees = NO;
            }];
        } else {
            self.fetchingEventAttendees = NO;
        }
    }
}

#pragma mark - UICollectionView Data Source

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
    if (section == kInviteSection) {
        if (self.isPeeking || self.event.isAggregate) return 0;
        return 1;
    }
    else if (section == kPeopleSection) {
        return self.event.attendees.count;
    }
    return 0;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 2;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ScrollViewCell *scrollCell = [collectionView dequeueReusableCellWithReuseIdentifier:kScrollViewCellName forIndexPath:indexPath];
    scrollCell.alpha = 1.0f;
    scrollCell.imgView.image = nil;
    scrollCell.imgViewLabel.hidden = YES;
    scrollCell.imgView.layer.borderColor = UIColor.clearColor.CGColor;
    if (indexPath.section == kInviteSection) {
        if ([[self.event.attendees objectAtIndex:0] isEqual:WGProfile.currentUser]) {
            [scrollCell.imageButton removeTarget:nil
                                          action:NULL
                                forControlEvents:UIControlEventAllEvents];
            if (self.event.isPrivate && ![self.event.owner isEqual:WGProfile.currentUser]) {
                scrollCell.alpha = 0.5f;
                scrollCell.imageButton.tag = self.rowOfEvent;
                [scrollCell.imageButton addTarget:self.placesDelegate action:@selector(showOverlayForInvite:) forControlEvents:UIControlEventTouchUpInside];
            }
            else {
                scrollCell.alpha = 1.0f;
                [scrollCell.imageButton addTarget:self action:@selector(invitePressed) forControlEvents:UIControlEventTouchUpInside];
            }
            scrollCell.imgViewLabel.hidden = NO;
            scrollCell.imgView.layer.borderColor = [FontProperties getBlueColor].CGColor;
            scrollCell.imgView.layer.borderWidth = 1.0f;
            scrollCell.imgView.layer.cornerRadius = scrollCell.imgView.frame.size.width/2.0f;
            scrollCell.blueOverlayView.hidden = YES;
            scrollCell.goHereLabel.hidden = YES;
            scrollCell.profileNameLabel.text = nil;
        }
        else {
            [scrollCell.imageButton removeTarget:nil
                                          action:NULL
                                forControlEvents:UIControlEventAllEvents];
            scrollCell.imageButton.tag = self.rowOfEvent;
            [scrollCell.imageButton addTarget:self action:@selector(goHerePressed:) forControlEvents:UIControlEventTouchUpInside];
            [scrollCell.imgView setImageWithURL:WGProfile.currentUser.smallCoverImageURL];
            scrollCell.blueOverlayView.hidden = NO;
            scrollCell.goHereLabel.hidden = NO;
            scrollCell.profileNameLabel.alpha = 0.0f;
        }
    }
    else {
        scrollCell.imageButton.tag = indexPath.item;
        [scrollCell.imageButton removeTarget:nil
                                      action:NULL
                            forControlEvents:UIControlEventAllEvents];
        scrollCell.blueOverlayView.hidden = YES;
        scrollCell.goHereLabel.hidden = YES;
        [scrollCell.imageButton addTarget:self action:@selector(chooseUser:) forControlEvents:UIControlEventTouchUpInside];
        scrollCell.profileNameLabel.alpha = 1.0f;
        WGUser *attendee = (WGUser *)[self.event.attendees objectAtIndex:indexPath.item];
        scrollCell.user = attendee;
        if (indexPath.item == self.event.attendees.count - 1) [self fetchEventAttendeesAsynchronous];
    }
    return scrollCell;
}

- (void)invitePressed {
    [self.placesDelegate invitePressed:self.event];
}

#pragma mark - UICollectionView Header
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        UICollectionViewCell *cell = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                        withReuseIdentifier:kScrollViewHeader
                                                                               forIndexPath:indexPath];
        return cell;
    }
    return nil;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    if (section == kInviteSection) {
        return CGSizeMake(10, 1);
    }
    else return CGSizeMake(0.5, 0.5);
}


@end

@implementation ScrollViewCell

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


- (void)setup {
    int imageWidth = self.frame.size.width - 10;
    self.frame = CGRectMake(0, 0, imageWidth, imageWidth + 30);
    self.contentView.frame = self.frame;

    self.imageButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, imageWidth, imageWidth)];
    [self.contentView addSubview:self.imageButton];
    
    self.imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, imageWidth, imageWidth)];
    self.imgView.contentMode = UIViewContentModeScaleAspectFill;
    self.imgView.clipsToBounds = YES;
    self.imgView.layer.cornerRadius = imageWidth/2;
    self.imgView.layer.borderColor = UIColor.clearColor.CGColor;
    self.imgView.layer.borderWidth = 1.0f;
    [self.imageButton addSubview:self.imgView];
    
    self.imgViewLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, imageWidth, imageWidth)];
    self.imgViewLabel.text = @"INVITE";
    self.imgViewLabel.font = [FontProperties mediumFont:12.0f];
    self.imgViewLabel.textColor = [FontProperties getBlueColor];
    self.imgViewLabel.textAlignment = NSTextAlignmentCenter;
    self.imgViewLabel.hidden = YES;
    [self.imageButton addSubview:self.imgViewLabel];
    
    self.blueOverlayView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, imageWidth, imageWidth)];
    self.blueOverlayView.backgroundColor = RGB(109, 166, 206);
    self.blueOverlayView.alpha = 0.8f;
    self.blueOverlayView.hidden = YES;
    [self.imgView addSubview:self.blueOverlayView];
    
    self.goHereLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, imageWidth, imageWidth)];
    self.goHereLabel.text = @"Join";
    self.goHereLabel.textAlignment = NSTextAlignmentCenter;
    self.goHereLabel.font = [FontProperties scMediumFont:20.0f];
    self.goHereLabel.textColor = UIColor.whiteColor;
    [self.imgView bringSubviewToFront:self.goHereLabel];
    [self.imgView addSubview:self.goHereLabel];
    
    self.profileNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, imageWidth, imageWidth, 20)];
    self.profileNameLabel.textColor = UIColor.blackColor;
    self.profileNameLabel.textAlignment = NSTextAlignmentCenter;
    self.profileNameLabel.font = [FontProperties lightFont:12.0f];
    [self.contentView addSubview:self.profileNameLabel];
}

- (void)setUser:(WGUser *)user {
    _user = user;
    self.profileNameLabel.textColor = UIColor.blackColor;
    self.profileNameLabel.alpha = 0.5f;
    CGFloat fontSize = 12.0f;
    CGSize size;
    while (fontSize > 0.0f)
    {
        size = [user.firstName sizeWithAttributes:
                @{NSFontAttributeName:[FontProperties lightFont:fontSize]}];
        //TODO: not use fixed length
        if (size.width <= self.frame.size.width - 10) break;
        
        fontSize -= 1.0;
    }
    
    // UI changes
    [self.imgView setSmallImageForUser:user completed:nil];
    self.profileNameLabel.text = user.firstName;
    self.profileNameLabel.font = [FontProperties lightFont:fontSize];

}



@end

@implementation ScrollViewLayout

- (id)initWithWidth:(int)width {
    self = [super init];
    if (self) {
        self.widthOfFrame = width;
        [self setup];
    }
    return self;
}

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
    self.itemSize = CGSizeMake(self.widthOfFrame + 10, self.widthOfFrame + 20);
    self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    self.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0);
    self.minimumInteritemSpacing = 0.0f;
    self.minimumLineSpacing = 0.0f;
}

@end