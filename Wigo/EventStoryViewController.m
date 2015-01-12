
//
//  EventStoryViewController.m
//  Wigo
//
//  Created by Alex Grinman on 10/24/14.
//  Copyright (c) 2014 Alex Grinman. All rights reserved.
//

#import "EventStoryViewController.h"
#import "IQMediaPickerController.h"
#import "InviteViewController.h"
#import "EventMessagesConstants.h"
#import "FancyProfileViewController.h"
#import "WGProfile.h"
#import "WGEvent.h"

#define sizeOfEachFaceCell ([[UIScreen mainScreen] bounds].size.width - 20)/3
#define kHeaderLength 64
#define kHeaderFaceCollectionView @"headerFaceCollectionView"
#define kFooterFaceCollectionView @"footerFaceCollectionView"

@interface EventStoryViewController()<UIScrollViewDelegate> {
    UIButton *sendButton;
    WGCollection *eventMessages;
    UICollectionView *facesCollectionView;
    BOOL cancelFetchMessages;
    
    CGPoint currentContentOffset;
}

@property (nonatomic, strong) UIScrollView *backgroundScrollview;
@property (nonatomic, strong) UIView *lineViewAtTop;
@end


@implementation EventStoryViewController

#pragma mark - UIViewController Delegate
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.backgroundScrollview = [[UIScrollView alloc] initWithFrame: CGRectMake(0, kHeaderLength, self.view.frame.size.width, self.view.frame.size.height - kHeaderLength)];
    self.backgroundScrollview.delegate = self;
    self.backgroundScrollview.scrollEnabled = YES;
    [self.view addSubview: self.backgroundScrollview];
    [self.view sendSubviewToBack: self.backgroundScrollview];
    
    
    [self loadEventTitle];

    [self loadEventPeopleScrollView];
    [self loadEventDetails];
    [self loadInviteOrGoHereButton];

    if (!self.groupNumberID || [self.groupNumberID isEqualToNumber:[WGProfile currentUser].group.id]) {
        [self loadTextViewAndSendButton];
    }

    [self loadConversationViewController];
    [self setDetailViewRead];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    
    BOOL isPeeking  = (self.groupNumberID && ![self.groupNumberID isEqualToNumber:[WGProfile currentUser].group.id]);

    NSString *isPeekingString = (isPeeking) ? @"Yes" : @"No";
    
    [WGAnalytics tagEvent:@"Event Story View" withDetails: @{@"isPeeking": isPeekingString}];

    if (facesCollectionView) [facesCollectionView reloadData];
    
    eventMessages = nil;
    [self fetchEventMessages];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    [self.navigationController setNavigationBarHidden: YES animated: NO];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear: animated];
    [self.navigationController setNavigationBarHidden: NO animated: NO];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear: animated];
}

#pragma mark - Loading Messages

- (void)loadEventDetails {
    UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 273)];
    backgroundView.backgroundColor = RGB(249, 249, 249);
    [self.view addSubview:backgroundView];
    [self.view sendSubviewToBack:backgroundView];
    
    self.numberGoingLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, self.eventPeopleScrollView.frame.origin.y + self.eventPeopleScrollView.frame.size.height + 10, 120, 40)];
    if ([self.event.numAttending intValue] > 0) {
        self.numberGoingLabel.text = [NSString stringWithFormat:@"%@ are going", [self.event.numAttending stringValue]];
    } else {
        self.numberGoingLabel.text = [NSString stringWithFormat:@"%@ is going", [self.event.numAttending stringValue]];
    }
//    if ([self.event.numberInvited intValue] > 0) {
//        self.numberGoingLabel.text = [NSString stringWithFormat:@"%@/%@ invited", self.numberGoingLabel.text, [self.event.numberInvited stringValue]];
//    }

    self.numberGoingLabel.textColor = RGB(170, 170, 170);
    self.numberGoingLabel.textAlignment = NSTextAlignmentLeft;
    self.numberGoingLabel.font = [FontProperties mediumFont:16];
    [self.backgroundScrollview addSubview:self.numberGoingLabel];
    

}

- (void)loadInviteOrGoHereButton {
    self.inviteButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 170 - 10, self.eventPeopleScrollView.frame.origin.y + self.eventPeopleScrollView.frame.size.height + 10, 170, 40)];
    [self.inviteButton setTitle:@"invite more people" forState:UIControlStateNormal];
    [self.inviteButton setTitleColor:[FontProperties getBlueColor] forState:UIControlStateNormal];
    self.inviteButton.titleLabel.font = [FontProperties scMediumFont:18.0f];
    self.inviteButton.layer.borderColor = [FontProperties getBlueColor].CGColor;
    self.inviteButton.layer.borderWidth = 1.0f;
    self.inviteButton.layer.cornerRadius = 5.0f;
    [self.inviteButton addTarget:self action:@selector(invitePressed) forControlEvents:UIControlEventTouchUpInside];
    self.inviteButton.hidden = YES;
    self.inviteButton.enabled = NO;
    [self.backgroundScrollview addSubview:self.inviteButton];
    
    self.goHereButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 170 - 10, self.eventPeopleScrollView.frame.origin.y + self.eventPeopleScrollView.frame.size.height + 10, 170, 40)];
    [self.goHereButton addTarget:self action:@selector(goHerePressed) forControlEvents:UIControlEventTouchUpInside];
    self.goHereButton.hidden = YES;
    self.goHereButton.enabled = NO;
    [self.goHereButton setTitle:@"go here" forState:UIControlStateNormal];
    [self.goHereButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.goHereButton.backgroundColor = [FontProperties getBlueColor];
    self.goHereButton.titleLabel.font = [FontProperties scMediumFont:18.0f];
    self.goHereButton.layer.cornerRadius = 5;
    self.goHereButton.layer.borderWidth = 1;
    self.goHereButton.layer.borderColor = [FontProperties getBlueColor].CGColor;
    [self.backgroundScrollview addSubview:self.goHereButton];
    
    
    if (self.groupNumberID && ![self.groupNumberID isEqualToNumber:[WGProfile currentUser].group.id]) {
        self.inviteButton.hidden = YES;
        self.inviteButton.enabled = NO;
        self.goHereButton.hidden = YES;
        self.goHereButton.enabled = NO;
    } else {
        if (self.event.id && [[WGProfile currentUser].eventAttending.id isEqualToNumber:self.event.id]) {
            self.inviteButton.hidden = NO;
            self.inviteButton.enabled = YES;
        } else {
            self.goHereButton.hidden = NO;
            self.goHereButton.enabled = YES;
        }
    }
}

- (void)invitePressed {
    [WGAnalytics tagEvent: @"Event Story Invite Tapped"];
    [self presentViewController:[[InviteViewController alloc] initWithEvent:self.event]
                       animated:YES
                     completion:nil];
}

- (void)goHerePressed {
    [WGAnalytics tagEvent: @"Event Story Go Here Tapped"];
    
    // Update data
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@"Places", @"Go Here Source", nil];
    [WGAnalytics tagEvent:@"Go Here" withDetails:options];
    
    // [WGProfile currentUser].isAttending = [WGEvent serialize:nil];
    [WGProfile currentUser].isGoingOut = @YES;
    [[WGProfile currentUser] goingToEvent:self.event withHandler:^(BOOL success, NSError *error) {
        if (error) {
            [[WGError sharedInstance] handleError:error actionType:WGActionSave retryHandler:nil];
            return;
        }
        
        WGEventAttendee *newAttendee = [[WGEventAttendee alloc] init];
        newAttendee.user = [WGProfile currentUser];
        [self.event addAttendee:newAttendee];
        self.event.numAttending = @([self.event.numAttending intValue] + 1);
        
        // Update UI
        self.eventPeopleScrollView.event = self.event;
        [self.eventPeopleScrollView updateUI];
        self.goHereButton.hidden = YES;
        self.goHereButton.enabled = NO;
        self.inviteButton.hidden = NO;
        self.inviteButton.enabled = YES;
        self.numberGoingLabel.text = [NSString stringWithFormat:@"%@ going", [self.event.numAttending stringValue]];
        
        [self presentFirstTimeGoingToEvent];
    }];
}

- (void)presentFirstTimeGoingToEvent {
    GOHERESTATE goHereState = (int)[[NSUserDefaults standardUserDefaults] integerForKey:kGoHereState];

    if (goHereState != DONOTPRESENTANYTHINGSTATE) {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        self.conversationViewController = [sb instantiateViewControllerWithIdentifier: @"EventConversationViewController"];
        self.conversationViewController.event = self.event;
        if (!eventMessages) self.conversationViewController.eventMessages = [[WGCollection alloc] initWithType:[WGEventMessage class]];
        if (goHereState == PRESENTFACESTATE) {
            if (eventMessages) self.conversationViewController.eventMessages = [self eventMessagesWithYourFace:YES];
        } else {
            if (goHereState == FIRSTTIMEPRESENTCAMERASTATE) [[NSUserDefaults standardUserDefaults] setInteger:SECONDTIMEPRESENTCAMERASTATE forKey:kGoHereState];
            if (goHereState == SECONDTIMEPRESENTCAMERASTATE) [[NSUserDefaults standardUserDefaults] setInteger:DONOTPRESENTANYTHINGSTATE forKey:kGoHereState];
            if (eventMessages) self.conversationViewController.eventMessages = [self eventMessagesWithCamera];
        }
        self.conversationViewController.index = [NSNumber numberWithInteger:self.conversationViewController.eventMessages.count - 1];
        self.conversationViewController.controllerDelegate = self;
        self.conversationViewController.storyDelegate = self;
        
        BOOL isPeeking  = (self.groupNumberID && ![self.groupNumberID isEqualToNumber:[WGProfile currentUser].group.id]);
        self.conversationViewController.isPeeking = isPeeking;
        
        [self presentViewController:self.conversationViewController animated:YES completion:nil];
    }
}


-(WGCollection *) eventMessagesWithYourFace:(BOOL)faceBool {
    WGCollection *newEventMessages =  [[WGCollection alloc] initWithType:[WGEventMessage class]];
    
    [newEventMessages addObjectsFromCollection:eventMessages];

    NSString *type = faceBool ? kFaceImage : kNotAbleToPost;
    WGEventMessage *eventMessage = [WGEventMessage serialize:@{
                                      @"user": [[WGProfile currentUser] deserialize],
                                      @"created": [NSDate nowStringUTC],
                                      @"media_mime_type": type,
                                      @"media": @""
                                      }];
    
    [newEventMessages addObject:eventMessage];
    
    return newEventMessages;
}


- (void)loadConversationViewController {
    StoryFlowLayout *flow = [[StoryFlowLayout alloc] init];
    CGFloat yOrigin = self.inviteButton.frame.origin.y + self.inviteButton.frame.size.height + 10;
    
    facesCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, yOrigin, self.view.frame.size.width, self.view.frame.size.height - yOrigin + 60) collectionViewLayout:flow];
    [facesCollectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kHeaderFaceCollectionView];
    [facesCollectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier: kFooterFaceCollectionView];

    facesCollectionView.backgroundColor = UIColor.whiteColor;
    facesCollectionView.showsHorizontalScrollIndicator = NO;
    facesCollectionView.showsVerticalScrollIndicator = NO;
    
    [facesCollectionView setCollectionViewLayout: flow];
    facesCollectionView.pagingEnabled = NO;
    [facesCollectionView registerClass:[FaceCell class] forCellWithReuseIdentifier:@"FaceCell"];
    
    facesCollectionView.dataSource = self;
    facesCollectionView.delegate = self;
    
    
    UIView *line = [[UIView alloc] initWithFrame: CGRectMake(0, yOrigin - 1, self.view.frame.size.width, 1)];
    line.backgroundColor = RGB(228, 228, 228);
    [self.backgroundScrollview addSubview: line];
    
    [self.backgroundScrollview addSubview: facesCollectionView];
    [self.backgroundScrollview sendSubviewToBack:facesCollectionView];
}




#pragma mark - UICollectionView Data Source

-(NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return eventMessages.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    FaceCell *myCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"FaceCell" forIndexPath: indexPath];
    [myCell setToActiveWithNoAnimation];

    myCell.leftLine.backgroundColor = RGB(237, 237, 237);
    myCell.leftLineEnabled = (indexPath.row %3 > 0) && (indexPath.row > 0);
    
    myCell.rightLine.backgroundColor = RGB(237, 237, 237);
    myCell.rightLineEnabled = (indexPath.row % 3 < 2) && (indexPath.row < eventMessages.count - 1);
    
    if ([indexPath row] + 1 == eventMessages.count && [eventMessages.hasNextPage boolValue]) {
        [self fetchEventMessages];
    }
    myCell.timeLabel.frame = CGRectMake(0, 0.75*sizeOfEachFaceCell + 3, sizeOfEachFaceCell, 30);
    myCell.mediaTypeImageView.hidden = NO;
    myCell.faceImageView.layer.borderColor = UIColor.blackColor.CGColor;
    
    WGEventMessage *eventMessage = (WGEventMessage *)[eventMessages objectAtIndex:[indexPath row]];
    WGUser *user = eventMessage.user;
    [myCell.mediaTypeImageView setImageWithURL:user.smallCoverImageURL imageArea:[user smallCoverImageArea]];

    NSString *contentURL;
    if (eventMessage.thumbnail) contentURL = eventMessage.thumbnail;
    else  contentURL = eventMessage.media;
    NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/%@", [WGProfile currentUser].cdnPrefix, contentURL]];
    [myCell.spinner startAnimating];
    __weak FaceCell *weakCell = myCell;
    [myCell.faceImageView setImageWithURL:imageURL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakCell.spinner stopAnimating];
        });
    }];
    myCell.timeLabel.text = [eventMessage.created getUTCTimeStringToLocalTimeString];
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

- (void)collectionView:(UICollectionView *)collectionView
    didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self showEventConversation:[NSNumber numberWithUnsignedInteger:indexPath.row]];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
     return CGSizeMake(collectionView.bounds.size.width, 52);
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        UICollectionViewCell *cell = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                        withReuseIdentifier:kHeaderFaceCollectionView
                                                                               forIndexPath:indexPath];

        UILabel *highlightLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 54)];
        highlightLabel.text = @"Highlights";
        highlightLabel.textAlignment = NSTextAlignmentCenter;
        highlightLabel.font = [FontProperties lightFont:20.0f];
        highlightLabel.textColor = RGB(162, 162, 162);
        [cell addSubview:highlightLabel];
        
        UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 30, cell.frame.size.height - 1, 60, 1)];
        lineView.backgroundColor = RGB(228, 228, 228);
        [cell addSubview:lineView];
        
        return cell;
    } else if ([kind isEqualToString: UICollectionElementKindSectionFooter]) {
        UICollectionViewCell *cell = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                        withReuseIdentifier: kFooterFaceCollectionView
                                                                               forIndexPath:indexPath];
     
        cell.backgroundColor = [UIColor clearColor];
        
        return cell;
    }
    
    return nil;
    
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    return CGSizeMake(collectionView.bounds.size.width, 100);
}


- (void)loadTextViewAndSendButton {
    int sizeOfButton = [[UIScreen mainScreen] bounds].size.width/6.4;
    sendButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width -sizeOfButton - 10, self.view.frame.size.height - sizeOfButton - 10, sizeOfButton, sizeOfButton)];
    [sendButton addTarget:self action:@selector(sendPressed) forControlEvents:UIControlEventTouchUpInside];
    sendButton.backgroundColor = [FontProperties getOrangeColor];
    sendButton.layer.borderWidth = 1.0f;
    sendButton.layer.borderColor = [UIColor clearColor].CGColor;
    sendButton.layer.cornerRadius = sizeOfButton/2;
    sendButton.layer.shadowColor = [UIColor blackColor].CGColor;
    sendButton.layer.shadowOpacity = 0.4f;
    sendButton.layer.shadowRadius = 5.0f;
    sendButton.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
    [self.view addSubview:sendButton];
    [self.view bringSubviewToFront:sendButton];

    UIImageView *sendOvalImageView = [[UIImageView alloc] initWithFrame:CGRectMake(sizeOfButton/2 - 7, sizeOfButton/2 - 7, 15, 15)];
    sendOvalImageView.image = [UIImage imageNamed:@"plusStoryButton"];
    [sendButton addSubview:sendOvalImageView];
}

- (void)loadEventPeopleScrollView {
    self.lineViewAtTop = [[UIView alloc] initWithFrame:CGRectMake(0, 63, self.view.frame.size.width, 1)];
    self.lineViewAtTop.backgroundColor = RGB(228, 228, 228);
    self.lineViewAtTop.hidden = YES;
    [self.view addSubview:self.lineViewAtTop];
    
    self.eventPeopleScrollView = [[EventPeopleScrollView alloc] initWithEvent:_event];
    self.eventPeopleScrollView.event = _event;
    self.eventPeopleScrollView.userSelectDelegate = self;
    self.eventPeopleScrollView.placesDelegate = self.placesDelegate;
    [self.eventPeopleScrollView updateUI];
    self.eventPeopleScrollView.frame = CGRectMake(0, 10, self.view.frame.size.width, self.eventPeopleScrollView.frame.size.height);
    [self.backgroundScrollview addSubview:self.eventPeopleScrollView];
}

- (void)loadEventTitle {
    UIButton *aroundBackButton = [[UIButton alloc] initWithFrame:CGRectMake(5, 5, 45, 60)];
    [aroundBackButton addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:aroundBackButton];
    UIImageView *backImageView = [[UIImageView alloc] initWithFrame:CGRectMake(15, 30, 9, 15)];
    backImageView.image = [UIImage imageNamed:@"blueBackIcon"];
    [aroundBackButton addSubview:backImageView];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(45, 14, self.view.frame.size.width - 90, 50)];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.numberOfLines = 0;
    titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    titleLabel.text = self.event.name;
    titleLabel.textColor = [FontProperties getBlueColor];
    titleLabel.font = [FontProperties getTitleFont];
    [self.view addSubview:titleLabel];
    
}

- (void)setDetailViewRead {
    if (![self.event.isRead boolValue]) {
        [self.event setRead:^(BOOL success, NSError *error) {
            // Do nothing!
        }];
    }
}

#pragma mark - Button handler

- (void)goBack {
    [self.navigationController popViewControllerAnimated: YES];
}


- (void)sendPressed {
    
    [WGAnalytics tagEvent: @"Event Story Create Highlight Tapped"];

    //not going here
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    self.conversationViewController = [sb instantiateViewControllerWithIdentifier: @"EventConversationViewController"];
    self.conversationViewController.event = self.event;
    if (!eventMessages) self.conversationViewController.eventMessages = [[WGCollection alloc] initWithType:[WGEventMessage class]];
    if ([[WGProfile currentUser].eventAttending.id isEqualToNumber:self.event.id]) {
        self.conversationViewController.eventMessages = [self eventMessagesWithCamera];
    } else {
        self.conversationViewController.eventMessages = [self eventMessagesWithYourFace: NO];
    }
    self.conversationViewController.index = [NSNumber numberWithInteger:self.conversationViewController.eventMessages.count - 1];
    self.conversationViewController.controllerDelegate = self;
    self.conversationViewController.storyDelegate = self;
    
    BOOL isPeeking  = (self.groupNumberID && ![self.groupNumberID isEqualToNumber:[WGProfile currentUser].group.id]);
    self.conversationViewController.isPeeking = isPeeking;

    [self presentViewController:self.conversationViewController animated:YES completion:nil];
}

- (WGCollection *)eventMessagesWithCamera {
    WGCollection *newEventMessages =  [[WGCollection alloc] initWithType:[WGEventMessage class]];
    
    [newEventMessages addObjectsFromCollection:eventMessages];
    
    WGEventMessage *eventMessage = [WGEventMessage serialize:@{
                                                               @"user": [[WGProfile currentUser] deserialize],
                                                               @"created": [NSDate nowStringUTC],
                                                               @"media_mime_type": kCameraType,
                                                               @"media": @""
                                                               }];
    
    [newEventMessages addObject:eventMessage];
    
    return newEventMessages;
}

- (void)fetchEventMessages {
    if (!cancelFetchMessages) {
        cancelFetchMessages = YES;
        __weak typeof(self) weakSelf = self;
        if (!eventMessages) {
            [self.event getMessages:^(WGCollection *collection, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    __strong typeof(self) strongSelf = weakSelf;
                    strongSelf->cancelFetchMessages = NO;
                    if (error) {
                        [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                        return;
                    }
                    strongSelf->eventMessages = collection;
                    [strongSelf->facesCollectionView reloadData];
                });
            }];
        } else if ([eventMessages.hasNextPage boolValue]) {
            [eventMessages addNextPage:^(BOOL success, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    __strong typeof(self) strongSelf = weakSelf;
                    strongSelf->cancelFetchMessages = NO;
                    if (error) {
                        [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                        return;
                    }
                    [strongSelf->facesCollectionView reloadData];
                });
            }];
        }
    }
}



- (void)showEventConversation:(NSNumber *)index {
    
    BOOL isPeeking  = (self.groupNumberID && ![self.groupNumberID isEqualToNumber:[WGProfile currentUser].group.id]);

    NSString *isPeekingString = (isPeeking) ? @"Yes" : @"No";
    [WGAnalytics tagEvent:@"Event Story Highlight Tapped" withDetails: @{ @"isPeeking": isPeekingString }];

    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    self.conversationViewController = [sb instantiateViewControllerWithIdentifier: @"EventConversationViewController"];
    self.conversationViewController.event = self.event;
    self.conversationViewController.index = index;
    
    if (![[WGProfile currentUser].eventAttending.id isEqualToNumber:self.event.id]) {
         self.conversationViewController.eventMessages = [self eventMessagesWithYourFace:NO];
    } else {
        self.conversationViewController.eventMessages = [self eventMessagesWithCamera];
    }
    
    self.conversationViewController.isPeeking = isPeeking;

    self.conversationViewController.storyDelegate = self;
    [self presentViewController:self.conversationViewController animated:YES completion:nil];
}


- (void)readEventMessageIDArray:(NSArray *)eventMessageIDArray {
    dispatch_async(dispatch_get_main_queue(), ^{
        for (int i = 0; i < [eventMessageIDArray count]; i++) {
            NSNumber *eventMessageID = [eventMessageIDArray objectAtIndex:i];
            for (WGEventMessage *eventMessage in eventMessages) {
                if ([eventMessage.id isEqualToNumber:eventMessageID]) {
                    eventMessage.isRead = @YES;
                    break;
                }
            }
        }
        [facesCollectionView reloadData];
    });
}

#pragma mark - IQMediaController Delegate

- (void)mediaPickerController:(IQMediaPickerController *)controller didFinishMediaWithInfo:(NSDictionary *)info {
    
}

- (void)mediaPickerControllerDidCancel:(IQMediaPickerController *)controller {
    
}

#pragma mark - UIScrollViewDelegate 

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    if (scrollView != facesCollectionView) {
        return;
    }
    
    self.lineViewAtTop.hidden = NO;
    
    CGFloat stickHeight = self.eventPeopleScrollView.frame.size.height + self.eventPeopleScrollView.frame.origin.y;

    if (self.backgroundScrollview.contentOffset.y >= stickHeight && facesCollectionView.contentOffset.y > 0) {
        self.backgroundScrollview.contentOffset = CGPointMake(scrollView.contentOffset.x, stickHeight);
    }
    else if (self.backgroundScrollview.contentOffset.y < 0 && scrollView == facesCollectionView) {
        self.backgroundScrollview.contentOffset = CGPointMake(scrollView.contentOffset.x, 0);
    } else {
        
        self.backgroundScrollview.contentOffset = CGPointMake(scrollView.contentOffset.x, self.backgroundScrollview.contentOffset.y + scrollView.contentOffset.y);
        
        currentContentOffset = scrollView.contentOffset;
        facesCollectionView.contentOffset = CGPointMake(0, 0);
    }
    
}


#pragma mark - Places Delegate

- (void)showUser:(WGUser *)user {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    FancyProfileViewController *fancyProfileViewController = [sb instantiateViewControllerWithIdentifier: @"FancyProfileViewController"];
    [fancyProfileViewController setStateWithUser: user];

    if (self.groupNumberID && ![self.groupNumberID isEqualToNumber:[WGProfile currentUser].group.id]) {
        fancyProfileViewController.userState = OTHER_SCHOOL_USER_STATE;
    }
    
    [self.navigationController pushViewController: fancyProfileViewController animated: YES];
}


@end

@implementation StoryFlowLayout

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
    self.itemSize = CGSizeMake(sizeOfEachFaceCell, sizeOfEachFaceCell);
    self.sectionInset = UIEdgeInsetsMake(0, 10, 10, 10);
    self.minimumLineSpacing = 0;
    self.minimumInteritemSpacing = 0;
    self.scrollDirection = UICollectionViewScrollDirectionVertical;
}

@end
