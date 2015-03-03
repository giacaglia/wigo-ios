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
    if (self.sizeOfEachImage == 0) self.sizeOfEachImage = (float)[[UIScreen mainScreen] bounds].size.width/(float)6.4;
    self = [super initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, self.sizeOfEachImage + 25) collectionViewLayout:[[ScrollViewLayout alloc] initWithSize:self.sizeOfEachImage]];
    if (self) {
        self.contentSize = CGSizeMake(15, self.sizeOfEachImage + 10);
        self.showsHorizontalScrollIndicator = NO;
        self.delegate = self;
        self.event = event;
        self.showsHorizontalScrollIndicator = NO;
        self.delegate = self;
        self.dataSource = self;
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


- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // Add 3 images
    if (scrollView.contentOffset.x + [[UIScreen mainScreen] bounds].size.width + 4 * self.sizeOfEachImage >= scrollView.contentSize.width && !self.fetchingEventAttendees) {
        [self fetchEventAttendeesAsynchronous];
    }
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
    //    [self.eventPeopleModalViewController.view addGestureRecognizer:gestureRecognizer];
    self.eventPeopleModalViewController.placesDelegate = self.placesDelegate;
    
    [self.placesDelegate showModalAttendees:self.eventPeopleModalViewController];
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
    return self.event.attendees.count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ScrollViewCell *scrollCell = [collectionView dequeueReusableCellWithReuseIdentifier:kScrollViewCellName forIndexPath:indexPath];
    scrollCell.imageButton.tag = indexPath.item;
    [scrollCell.imageButton addTarget:self action:@selector(chooseUser:) forControlEvents:UIControlEventTouchUpInside];
    WGEventAttendee *attendee = (WGEventAttendee *)[self.event.attendees objectAtIndex:indexPath.item];
    [scrollCell setStateForUser:attendee.user];
    if (indexPath.item == self.event.attendees.count - 1) [self fetchEventAttendeesAsynchronous];
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
    return CGSizeMake(10, 1);
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
    int imageWidth = self.frame.size.height - 20;
    self.frame = CGRectMake(0, 0, imageWidth + 5, imageWidth + 20);
    self.contentView.frame = self.frame;

    self.imageButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 2, imageWidth, imageWidth)];
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
    self.profileNameLabel.font = [FontProperties lightFont:14.0f];
    [self.contentView addSubview:self.profileNameLabel];
}

- (void)setStateForUser:(WGUser *)user {
    [self.imgView setSmallImageForUser:user completed:nil];
    self.profileNameLabel.text = user.firstName;
}

@end

@implementation ScrollViewLayout

- (id)initWithSize:(int)size {
    self = [super init];
    if (self) {
        self.sizeOfFrame = size;
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
    self.itemSize = CGSizeMake(self.sizeOfFrame + 10, self.sizeOfFrame + 20);
    self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    self.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0);
    self.minimumInteritemSpacing = 0.0f;
    self.minimumLineSpacing = 0.0f;
}

@end