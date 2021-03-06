//
//  HighlightsCollectionView.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 2/20/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import "HighlightsCollectionView.h"

#define kHighlightCellName @"HighLightCellName"
#define kAddPhotoCellName @"AddPhotoCellName"
#define kAddPhotoSection 0
#define kHighlightSection 1

@implementation HighlightsCollectionView

- (id)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout {
    self = [super initWithFrame:frame collectionViewLayout:layout];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

-(id)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.backgroundColor = UIColor.clearColor;
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
    
    self.pagingEnabled = NO;
    [self registerClass:[HighlightCell class] forCellWithReuseIdentifier:kHighlightCellName];
    [self registerClass:[AddPhotoCell class] forCellWithReuseIdentifier:kAddPhotoCellName];
    [self registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kHighlightsHeader];
    
    self.dataSource = self;
    self.delegate = self;
    self.scrollEnabled = YES;
    self.showAddPhoto = YES;
}

- (void)setEvent:(WGEvent *)event {
    _event = event;
    self.contentSize = CGSizeMake(_event.messages.count *[HighlightCell height], [HighlightCell height]);
    [self reloadData];
}

#pragma mark - UICollectionView Delegate

- (void)collectionView:(UICollectionView *)collectionView
didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.event.isExpired.boolValue) {
        [self.placesDelegate showConversationForEvent:self.event
                                    withEventMessages:self.event.messages
                                              atIndex:(int)indexPath.item];
        return;
    }
    

    if (indexPath.section != kAddPhotoSection) {
        int index = (int)indexPath.item;
        if ([[self.event.attendees objectAtIndex:0] isEqual:WGProfile.currentUser]) {
            index +=1;
        }
        [self.placesDelegate showConversationForEvent:self.event
                                    withEventMessages:self.event.messages
                                              atIndex:index];
        return;
    }
    
    [self.placesDelegate showConversationForEvent:self.event
                                withEventMessages:self.event.messages
                                          atIndex:(int)indexPath.item];

}


#pragma mark - UICollectionView Data Source

-(NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView
{
    return 2;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView
    numberOfItemsInSection:(NSInteger)section {
    if (section == kAddPhotoSection)  {
        if (self.event.attendees.count == 0) return 0;
       if (self.event.isExpired.boolValue ||
           ![[self.event.attendees objectAtIndex:0] isEqual:WGProfile.currentUser]) return 0;
       return 1;
    }
    if (section == kHighlightSection) return self.event.messages.count;
    return 0;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kAddPhotoSection) {
        AddPhotoCell *addPhotoCell = [collectionView dequeueReusableCellWithReuseIdentifier:kAddPhotoCellName forIndexPath: indexPath];
        return addPhotoCell;
    }
    HighlightCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kHighlightCellName forIndexPath: indexPath];
    cell.alpha = 1.0f;
    
    cell.faceImageView.alpha = 1.0f;
    cell.orangeDotView.hidden = YES;

    if (indexPath.item == self.event.messages.count - 1) {
        [self fetchEventMessages];
    }
    WGEventMessage *eventMessage = (WGEventMessage *)[self.event.messages objectAtIndex:[indexPath row]];
    cell.eventMessage = eventMessage;
    return cell;
}

- (void)showNavigationBar:(UIImagePickerController*)imagePicker {
    [imagePicker setNavigationBarHidden:NO];
}

- (void)fetchEventMessages {
    self.cancelFetchMessages = YES;
    if (!self.event.messages.nextPage) return;
    
    __weak typeof(self) weakSelf = self;
    [self.event.messages addNextPage:^(BOOL success, NSError *error) {
        __strong typeof(self) strongSelf = weakSelf;
        strongSelf.cancelFetchMessages = NO;
        if (error) {
            [[WGError sharedInstance] logError:error forAction:WGActionLoad];
            return;
        }
        strongSelf.contentSize = CGSizeMake(strongSelf.event.messages.count *[HighlightCell height], [HighlightCell height]);
        [strongSelf reloadData];
    }];
}

#pragma mark - UICollectionView Header
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        UICollectionViewCell *cell = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                        withReuseIdentifier:kHighlightsHeader
                                                                               forIndexPath:indexPath];
        return cell;
    }
    return nil;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeMake(5, 1);
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kAddPhotoSection) return CGSizeMake(10 + [AddPhotoCell width], [HighlightCell height]);
    return CGSizeMake([HighlightCell height], [HighlightCell height]);
}



@end

@implementation AddPhotoCell

+ (CGFloat) width {
    return 0.9*(float)[UIScreen mainScreen].bounds.size.width/(float)5.5;
}

+ (CGFloat) height {
    return 55 + 5;
}

- (id)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
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
    self.backgroundColor = UIColor.clearColor;
    self.frame = CGRectMake(0, 0, 10 + [AddPhotoCell width], [HighlightCell height]);
    self.contentView.frame = self.frame;
    
    UIImageView *cameraImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, self.contentView.frame.size.height/2 - [AddPhotoCell height]/2, [AddPhotoCell width], [AddPhotoCell width])];
    cameraImageView.image = [UIImage imageNamed:@"addPhoto"];
    [self.contentView addSubview:cameraImageView];
}

-(BOOL)prefersStatusBarHidden   // iOS8 definitely needs this one. checked.
{
    return NO;
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [[UIApplication sharedApplication] setStatusBarHidden:NO];

    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

@end

@implementation HighlightCell

+ (CGFloat)height {
    return [UIScreen mainScreen].bounds.size.width/3.3;
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
    
    self.faceImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 3, 0.9*[HighlightCell height], 0.9*[HighlightCell height])];
    self.faceImageView.center = self.contentView.center;
    self.faceImageView.backgroundColor = UIColor.clearColor;
    self.faceImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.faceImageView.layer.masksToBounds = YES;
    self.faceImageView.layer.cornerRadius = 10.0f;
    self.faceImageView.layer.borderWidth = 1.0f;
    self.faceImageView.layer.borderColor = UIColor.clearColor.CGColor;
    [self.contentView addSubview: self.faceImageView];
    
    self.orangeDotView = [[UIView alloc] initWithFrame:CGRectMake(0.9*[HighlightCell height] - 3, 0, 15, 15)];
    self.orangeDotView.backgroundColor = [FontProperties getOrangeColor];
    self.orangeDotView.layer.borderColor = [UIColor clearColor].CGColor;
    self.orangeDotView.clipsToBounds = YES;
    self.orangeDotView.layer.borderWidth = 3;
    self.orangeDotView.layer.cornerRadius = 7.5;
    [self.contentView addSubview:self.orangeDotView];
}


- (void)updateUIToRead:(BOOL)read {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (read) {
            self.orangeDotView.hidden = YES;
        } else {
            self.orangeDotView.hidden = NO;
        }
    });
}

-(void) setEventMessage:(WGEventMessage *)eventMessage {
    _eventMessage = eventMessage;
    NSString *contentURL;
    if (eventMessage.thumbnail) contentURL = eventMessage.thumbnail;
    else  contentURL = eventMessage.media;
    NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/%@", WGProfile.currentUser.cdnPrefix, contentURL]];
    [self.faceImageView setImageWithURL:imageURL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {}];
    
    if (eventMessage.isRead) {
        if (eventMessage.isRead.boolValue) [self updateUIToRead:YES];
        else [self updateUIToRead:NO];
    }
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
//    self.sectionInset = UIEdgeInsetsMake(0, 10, 10, 10);
    self.minimumLineSpacing = 0;
    self.minimumInteritemSpacing = 0;
    self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
}

@end
