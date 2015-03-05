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
    if (self.widthOfEachCell == 0) self.widthOfEachCell = (float)[[UIScreen mainScreen] bounds].size.width/(float)6.4;
    self = [super initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, self.widthOfEachCell + 50) collectionViewLayout:[[ScrollViewLayout alloc] initWithWidth:self.widthOfEachCell]];
    if (self) {
        self.contentSize = CGSizeMake(15, self.widthOfEachCell + 40);
        self.showsHorizontalScrollIndicator = NO;
        self.delegate = self;
        self.dataSource = self;
        self.event = event;
        [self registerClass:[ScrollViewCell class] forCellWithReuseIdentifier:kScrollViewCellName];
        [self registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kScrollViewHeader];
    }
    return self;
}

+ (CGFloat) containerHeight {
    return (float)[[UIScreen mainScreen] bounds].size.width/(float)3.7;
}

-(void) updateUI {
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
                                                             tintColor:RGBAlpha(0, 0, 0, 0.75)
                                                 saturationDeltaFactor:1.3
                                                             maskImage:nil];
    
    self.eventPeopleModalViewController = [[EventPeopleModalViewController alloc] initWithEvent:self.event startIndex:tag andBackgroundImage:imageOfUnderlyingView];
    self.eventPeopleModalViewController.placesDelegate = self.placesDelegate;
    
    [self.placesDelegate showModalAttendees:self.eventPeopleModalViewController];
}

- (void)invitePressed {
    [self.placesDelegate invitePressed];
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
                
                [strongSelf saveScrollPosition];
                [strongSelf updateUI];
                
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
        if (self.event.id && [WGProfile.currentUser.eventAttending.id isEqual:self.event.id]) {
            return 1;
        }
        else return 0;
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
    if (indexPath.section == kInviteSection) {
        [scrollCell.imageButton removeTarget:nil
                           action:NULL
                 forControlEvents:UIControlEventAllEvents];
        [scrollCell.imageButton addTarget:self action:@selector(invitePressed) forControlEvents:UIControlEventTouchUpInside];
        scrollCell.imgView.image = [UIImage imageNamed:@"inviteButton"];
        scrollCell.profileNameLabel.text = @"Invite";
        scrollCell.profileNameLabel.alpha = 1.0f;
        scrollCell.profileNameLabel.textColor = [FontProperties getOrangeColor];
        scrollCell.profileNameLabel.font = [FontProperties openSansSemibold:12.0f];
    }
    else {
        scrollCell.imageButton.tag = indexPath.item;
        [scrollCell.imageButton removeTarget:nil
                                      action:NULL
                            forControlEvents:UIControlEventAllEvents];
        [scrollCell.imageButton addTarget:self action:@selector(chooseUser:) forControlEvents:UIControlEventTouchUpInside];
        WGEventAttendee *attendee = (WGEventAttendee *)[self.event.attendees objectAtIndex:indexPath.item];
        [scrollCell setStateForUser:attendee.user];
        if (indexPath.item == self.event.attendees.count - 1) [self fetchEventAttendeesAsynchronous];
    }
    return scrollCell;
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
    self.imgView.layer.cornerRadius = self.imgView.frame.size.width/2;
    self.imgView.layer.borderColor = UIColor.clearColor.CGColor;
    self.imgView.layer.borderWidth = 1.0f;
    [self.imageButton addSubview:self.imgView];
    
    self.profileNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, imageWidth, imageWidth, 20)];
    self.profileNameLabel.textColor = UIColor.blackColor;
    self.profileNameLabel.textAlignment = NSTextAlignmentCenter;
    self.profileNameLabel.font = [FontProperties openSansRegular:12.0f];
    [self.contentView addSubview:self.profileNameLabel];
}

- (void)setStateForUser:(WGUser *)user {
    [self.imgView setSmallImageForUser:user completed:nil];
    self.profileNameLabel.text = user.firstName;
    self.profileNameLabel.textColor = UIColor.blackColor;
    if (user.isCurrentUser) {
        self.profileNameLabel.alpha = 1.0f;
        self.profileNameLabel.text = @"You";
        self.profileNameLabel.font = [FontProperties openSansSemibold:12.0f];
    }
    else {
        self.profileNameLabel.alpha = 0.5f;
        CGFloat fontSize = 12.0f;
        CGSize size;
        while (fontSize > 0.0f)
        {
            size = [user.firstName sizeWithAttributes:
                    @{NSFontAttributeName:[FontProperties openSansRegular:fontSize]}];
            //TODO: not use fixed length
            if (size.width <= self.frame.size.width - 10) break;
            
            fontSize -= 1.0;
        }
        self.profileNameLabel.font = [FontProperties openSansRegular:fontSize];
    }
  
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