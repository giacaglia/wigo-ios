
//
//  EventStoryViewController.m
//  Wigo
//
//  Created by Alex Grinman on 10/24/14.
//  Copyright (c) 2014 Alex Grinman. All rights reserved.
//

#import "EventStoryViewController.h"
#import "InviteViewController.h"
#import "EventMessagesConstants.h"
#import "ProfileViewController.h"
#import "WGProfile.h"
#import "WGEvent.h"
#import "PrivateSwitchView.h"

#define sizeOfEachFaceCell ([[UIScreen mainScreen] bounds].size.width - 20)/3
#define kHeaderLength 64
#define kHeaderFaceCollectionView @"headerFaceCollectionView"
#define kFooterFaceCollectionView @"footerFaceCollectionView"

@interface EventStoryViewController()<UIScrollViewDelegate> {
    UIButton *sendButton;
    UILabel *highlightLabel;
    CGPoint currentContentOffset;
}


@property (nonatomic, strong) UIScrollView *backgroundScrollview;
@property (nonatomic, strong) UIView *lineViewAtTop;
@property (nonatomic, assign) BOOL movingForward;
@property (nonatomic, assign) BOOL loadViewFromFront;
@property (nonatomic, strong) UIButton *highlightButton;
@property (nonatomic, strong) UILabel *noHighlightsLabel;
@property (nonatomic, strong) UIImageView *privateTooltipBanner;
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
    [self initializeToolTipBanner];
    [self initializePrivateTooltipBanner];
    [self initializeOverlayPrivate];
    [self loadConversationViewController];
    [self setDetailViewRead];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    
    BOOL isPeeking  = (self.groupNumberID && ![self.groupNumberID isEqualToNumber:[WGProfile currentUser].group.id]);

    NSString *isPeekingString = (isPeeking) ? @"Yes" : @"No";
    
    [WGAnalytics tagEvent:@"Event Story View" withDetails: @{@"isPeeking": isPeekingString}];
    
    self.eventMessages = nil;
    if (_loadViewFromFront) [self fetchEventMessages];
    else [self.facesCollectionView forceLoad];
    _loadViewFromFront = NO;
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    [self.navigationController setNavigationBarHidden: YES animated: NO];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear: animated];
    if (!_movingForward) {
        [self.navigationController setNavigationBarHidden: NO animated: NO];
    }
    _movingForward = NO;
}


#pragma mark - Refresh Control

- (void)addRefreshToScrollView {
    [WGSpinnerView addDancingGToUIScrollView:self.facesCollectionView
                                   withHandler:^{
                                       self.eventMessages = nil;
                                       [self fetchEventMessages];
                                   }];
}

#pragma mark - Loading Messages

- (void)loadEventDetails {
    UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 273)];
    backgroundView.backgroundColor = RGB(249, 249, 249);
    [self.view addSubview:backgroundView];
    [self.view sendSubviewToBack:backgroundView];
    
    self.numberGoingLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, self.eventPeopleScrollView.frame.origin.y + self.eventPeopleScrollView.frame.size.height + 10, 120, 40)];
    if ([self.event.numAttending intValue] > 1) {
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
    self.inviteButton.hidden = YES;
    self.inviteButton.enabled = NO;
    [self.backgroundScrollview addSubview:self.inviteButton];
    if (self.event.isPrivate && ![self.event.owner isEqual:WGProfile.currentUser]) {
        self.inviteButton.alpha = 0.5f;
        [self.inviteButton addTarget:self action:@selector(showOverlayView) forControlEvents:UIControlEventTouchUpInside];
    }
    else {
        self.inviteButton.alpha = 1.0f;
        [self.inviteButton addTarget:self action:@selector(invitePressed) forControlEvents:UIControlEventTouchUpInside];
    }
    
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
    _movingForward = YES;
    _loadViewFromFront = YES;
    [self presentViewController:[[InviteViewController alloc] initWithEvent:self.event]
                       animated:YES
                     completion:nil];
}

- (void)goHerePressed {
    [WGAnalytics tagEvent: @"Event Story Go Here Tapped"];
    
    // Update data
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@"Places", @"Go Here Source", nil];
    [WGAnalytics tagEvent:@"Go Here" withDetails:options];
    
    [[WGProfile currentUser] goingToEvent:self.event withHandler:^(BOOL success, NSError *error) {
        if (error) {
            [self.event.attendees removeObjectAtIndex:0];
            self.event.numAttending = @([self.event.numAttending intValue] - 1);
            self.eventPeopleScrollView.event = self.event;
            [self.eventPeopleScrollView updateUI];
            
            self.goHereButton.hidden = NO;
            self.goHereButton.enabled = YES;
            self.inviteButton.hidden = YES;
            self.inviteButton.enabled = NO;
            self.numberGoingLabel.text = [NSString stringWithFormat:@"%@ going", [self.event.numAttending stringValue]];
            
            [[WGError sharedInstance] handleError:error actionType:WGActionSave retryHandler:nil];
            [[WGError sharedInstance] logError:error forAction:WGActionSave];
            return;
        }
    }];
    
    [WGProfile currentUser].eventAttending = self.event;
    [WGProfile currentUser].isGoingOut = @YES;
    WGEventAttendee *newAttendee = [[WGEventAttendee alloc] init];
    newAttendee.user = [WGProfile currentUser];
    [self.event.attendees insertObject:newAttendee atIndex:0];
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
}

- (void)presentFirstTimeGoingToEvent {
    GOHERESTATE goHereState = (int)[[NSUserDefaults standardUserDefaults] integerForKey:kGoHereState];

    if (goHereState != DONOTPRESENTANYTHINGSTATE) {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        self.conversationViewController = [sb instantiateViewControllerWithIdentifier: @"EventConversationViewController"];
        self.conversationViewController.event = self.event;
        if (!self.eventMessages) self.conversationViewController.eventMessages = [[WGCollection alloc] initWithType:[WGEventMessage class]];
        if (goHereState == PRESENTFACESTATE) {
            if (self.eventMessages) self.conversationViewController.eventMessages = [self eventMessagesWithYourFace:YES];
        } else {
            if (self.eventMessages) self.conversationViewController.eventMessages = [self eventMessagesWithCamera];
        }
        self.conversationViewController.index = [NSNumber numberWithInteger:self.conversationViewController.eventMessages.count - 1];
        self.conversationViewController.storyDelegate = self;
        
        BOOL isPeeking  = (self.groupNumberID && ![self.groupNumberID isEqualToNumber:[WGProfile currentUser].group.id]);
        self.conversationViewController.isPeeking = isPeeking;
        _movingForward = YES;
        _loadViewFromFront = YES;
        [self presentViewController:self.conversationViewController animated:YES completion:nil];
    }
}


-(WGCollection *) eventMessagesWithYourFace:(BOOL)faceBool {
    WGCollection *newEventMessages =  [[WGCollection alloc] initWithType:[WGEventMessage class]];
    
    [newEventMessages addObjectsFromCollection:self.eventMessages];

    NSString *type = faceBool ? kFaceImage : kNotAbleToPost;
    WGEventMessage *eventMessage = [WGEventMessage serialize:@{
                                      @"user": [WGProfile currentUser],
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
    
    self.facesCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, yOrigin, self.view.frame.size.width, self.view.frame.size.height - yOrigin + 60) collectionViewLayout:flow];
    [self.facesCollectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kHeaderFaceCollectionView];
    [self.facesCollectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier: kFooterFaceCollectionView];

    self.facesCollectionView.backgroundColor = UIColor.whiteColor;
    self.facesCollectionView.showsHorizontalScrollIndicator = NO;
    self.facesCollectionView.showsVerticalScrollIndicator = NO;
    
    [self.facesCollectionView setCollectionViewLayout: flow];
    self.facesCollectionView.pagingEnabled = NO;
    [self.facesCollectionView registerClass:[FaceCell class] forCellWithReuseIdentifier:@"FaceCell"];
    
    self.facesCollectionView.dataSource = self;
    self.facesCollectionView.delegate = self;
    
    
    UIView *line = [[UIView alloc] initWithFrame: CGRectMake(0, yOrigin - 1, self.view.frame.size.width, 1)];
    line.backgroundColor = RGB(228, 228, 228);
    [self.backgroundScrollview addSubview: line];
    
    [self.backgroundScrollview addSubview: self.facesCollectionView];
    [self.backgroundScrollview sendSubviewToBack:self.facesCollectionView];
    
    CGRect frame = self.facesCollectionView.bounds;
    frame.origin.y = -frame.size.height;
    UIView* whiteView = [[UIView alloc] initWithFrame:frame];
    whiteView.backgroundColor = UIColor.whiteColor;
    [self.facesCollectionView addSubview:whiteView];
    
    self.facesCollectionView.showsVerticalScrollIndicator = NO;
    self.facesCollectionView.scrollEnabled = YES;
    self.facesCollectionView.alwaysBounceVertical = YES;
    self.facesCollectionView.bounces = YES;
    
    [self addRefreshToScrollView];
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
    FaceCell *myCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"FaceCell" forIndexPath: indexPath];
    myCell.contentView.frame = CGRectMake(0, 0, sizeOfEachFaceCell, sizeOfEachFaceCell);
    myCell.faceAndMediaTypeView.frame = myCell.contentView.frame;
    
    myCell.leftLine.backgroundColor = RGB(237, 237, 237);
    myCell.leftLineEnabled = (indexPath.row %3 > 0) && (indexPath.row > 0);
    
    myCell.rightLine.backgroundColor = RGB(237, 237, 237);
    myCell.rightLineEnabled = (indexPath.row % 3 < 2) && (indexPath.row < self.eventMessages.count - 1);
    
    if ([indexPath row] + 1 == self.eventMessages.count && [self.eventMessages.hasNextPage boolValue]) {
        [self fetchEventMessages];
    }
    myCell.timeLabel.frame = CGRectMake(0, 0.75*sizeOfEachFaceCell + 3, sizeOfEachFaceCell, 30);
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
    __weak FaceCell *weakCell = myCell;
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

- (void)collectionView:(UICollectionView *)collectionView
    didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self showEventConversation:[NSNumber numberWithUnsignedInteger:indexPath.row]];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    if ([self shouldShowToolTip]) return CGSizeMake(collectionView.bounds.size.width, 85);
    else return CGSizeMake(collectionView.bounds.size.width, 52);
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        UICollectionViewCell *cell = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                        withReuseIdentifier:kHeaderFaceCollectionView
                                                                               forIndexPath:indexPath];

        
        if (highlightLabel == nil) {
            highlightLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 54)];
            highlightLabel.text = @"Highlights";
            highlightLabel.textAlignment = NSTextAlignmentCenter;
            highlightLabel.font = [FontProperties lightFont:20.0f];
            highlightLabel.textColor = RGB(162, 162, 162);
            [cell addSubview:highlightLabel];
            
            UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 30, 52 - 1, 60, 1)];
            lineView.backgroundColor = RGB(228, 228, 228);
            [cell addSubview:lineView];
            
            _noHighlightsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 70, self.view.frame.size.width, 20)];
            NSString *str = @"0001F627";
            NSScanner *hexScan = [NSScanner scannerWithString:str];
            unsigned int hexNum;
            [hexScan scanHexInt:&hexNum];
            UTF32Char inputChar = hexNum;
            NSString *res = [[NSString alloc] initWithBytes:&inputChar length:4 encoding:NSUTF32LittleEndianStringEncoding];
            _noHighlightsLabel.text = [NSString stringWithFormat:@"No highlights yet %@", res];
            _noHighlightsLabel.textAlignment = NSTextAlignmentCenter;
            _noHighlightsLabel.font = [FontProperties lightFont:15.0f];
            _noHighlightsLabel.textColor = RGB(170, 170, 170);
            _noHighlightsLabel.alpha = 0.0f;
            [cell addSubview:_noHighlightsLabel];
        }
        

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
    int widthButton = [[UIScreen mainScreen] bounds].size.width/5.33;
    sendButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - widthButton - 15, self.view.frame.size.height - widthButton - 15, widthButton, widthButton)];
    [sendButton addTarget:self action:@selector(sendPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:sendButton];
    [self.view bringSubviewToFront:sendButton];

    UIImageView *sendOvalImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, widthButton, widthButton)];
    sendOvalImageView.image = [UIImage imageNamed:@"cameraPlus"];
    [sendButton addSubview:sendOvalImageView];
}

#warning NEED to show tooltip only for creator
- (void)initializePrivateTooltipBanner {
    self.privateTooltipBanner = [[UIImageView alloc] initWithFrame:CGRectMake(self.inviteButton.center.x - 115 - 30, self.inviteButton.frame.origin.y + self.inviteButton.frame.size.height, 230, 91)];
    self.privateTooltipBanner.image = [UIImage imageNamed:@"privateTooltipImageView"];
    self.privateTooltipBanner.hidden = !self.event.isPrivate || ![self.event.owner isEqual:WGProfile.currentUser];
    [self.backgroundScrollview bringSubviewToFront:self.privateTooltipBanner];
    [self.backgroundScrollview addSubview:self.privateTooltipBanner];
    
    UILabel *inviteFriendsLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 19, self.privateTooltipBanner.frame.size.width - 20, self.privateTooltipBanner.frame.size.height - 19)];
    NSMutableAttributedString * string = [[NSMutableAttributedString alloc] initWithString:@"Invite friends to your\nprivate party!"];
    [string addAttribute:NSForegroundColorAttributeName value:UIColor.grayColor range:NSMakeRange(0,string.length)];
    [string addAttribute:NSForegroundColorAttributeName value:[FontProperties getBlueColor] range:NSMakeRange(0, 6)];
    inviteFriendsLabel.attributedText = string;
    inviteFriendsLabel.numberOfLines = 2;
    inviteFriendsLabel.lineBreakMode = NSLineBreakByWordWrapping;
    inviteFriendsLabel.textAlignment = NSTextAlignmentLeft;
    [self.privateTooltipBanner addSubview:inviteFriendsLabel];
    
    UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(self.privateTooltipBanner.frame.size.width - 30 - 6, self.privateTooltipBanner.frame.size.height/2 + 10 - 6, 12, 12)];
    [closeButton setTitle:@"x" forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(closePrivateTooltip) forControlEvents:UIControlEventTouchUpInside];
    [closeButton setTitleColor:RGB(162, 162, 162) forState:UIControlStateNormal];
    [self.privateTooltipBanner addSubview:closeButton];
}

- (void)closePrivateTooltip {
    self.privateTooltipBanner.hidden = YES;
}

- (void)initializeOverlayPrivate {
    UIVisualEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
    self.visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    self.visualEffectView.frame = self.view.frame;
    self.visualEffectView.alpha = 0.0f;
    [self.view addSubview:self.visualEffectView];
    [self.view bringSubviewToFront:self.visualEffectView];
    
    UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 40 - 18, 30, 40, 40)];
    UIImageView *closeButtonImageView = [[UIImageView alloc] initWithFrame:CGRectMake(16, 0, 24, 24)];
    closeButtonImageView.image = [UIImage imageNamed:@"blueCloseButton"];
    [closeButton addSubview:closeButtonImageView];
    [closeButton addTarget:self action:@selector(closeOverlay) forControlEvents:UIControlEventTouchUpInside];
    [self.visualEffectView addSubview:closeButton];
    
    UILabel *eventOnlyLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 190, self.view.frame.size.width, 20)];
    eventOnlyLabel.text = @"This event is invite-only";
    eventOnlyLabel.font = [FontProperties mediumFont:18];
    eventOnlyLabel.textColor = [FontProperties getBlueColor];
    eventOnlyLabel.textAlignment = NSTextAlignmentCenter;
    [self.visualEffectView addSubview:eventOnlyLabel];
    
    UILabel *explanationLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height/2 - 32, self.view.frame.size.width, 75)];
    if ([self.event.owner isEqual:WGProfile.currentUser]) {
        explanationLabel.text = @"Only people you invite can see the\nevent and what is going on and only you\ncan invite people. You can change the\ntype of the event:";
    }
    else {
        explanationLabel.text = @"Only invited people can see whats going on. Only creator can invite people.";
    }
    explanationLabel.font = [FontProperties mediumFont:15];
    explanationLabel.textColor = [FontProperties getBlueColor];
    explanationLabel.textAlignment = NSTextAlignmentCenter;
    explanationLabel.numberOfLines = 0;
    explanationLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [self.visualEffectView addSubview:explanationLabel];
    
    PrivateSwitchView *privateSwitchView = [[PrivateSwitchView alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 120, self.view.frame.size.height/2 + 66, 240, 40)];
    privateSwitchView.hidden = ![self.event.owner isEqual:WGProfile.currentUser];
    [self.visualEffectView addSubview:privateSwitchView];
    
    UIImageView *lockImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 12, self.view.frame.size.height/2 + 66, 24, 32)];
    lockImageView.image = [UIImage imageNamed:@"lockImage"];
    lockImageView.hidden = [self.event.owner isEqual:WGProfile.currentUser];
    [self.visualEffectView addSubview:lockImageView];
}

- (void)closeOverlay {
    [UIView animateWithDuration:0.4 animations:^{
        self.visualEffectView.alpha = 0.0f;
    }];
}

- (void)initializeToolTipBanner {
    int widthButton = [[UIScreen mainScreen] bounds].size.width/5.33;
    _highlightButton = [[UIButton alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 89 - widthButton - 15, 233, 89)];
    _highlightButton.center = CGPointMake(self.view.center.x, _highlightButton.center.y);
    [_highlightButton addTarget:self action:@selector(sendPressed) forControlEvents:UIControlEventTouchUpInside];
    _highlightButton.alpha = 0.0f;
    _highlightButton.hidden = self.event.isPrivate;
    _highlightButton.enabled = NO;
    [self.view addSubview:_highlightButton];
    
    UIImageView *highlightImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 233, 89)];
    highlightImageView.image = [UIImage imageNamed:@"highlightBubble"];
    [_highlightButton addSubview:highlightImageView];

    UILabel *postHighglightLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, highlightImageView.frame.size.width, highlightImageView.frame.size.height - 15)];
    NSMutableAttributedString * string = [[NSMutableAttributedString alloc] initWithString:@"Post a highlight to get\nthe party started"];
    [string addAttribute:NSForegroundColorAttributeName value:UIColor.grayColor range:NSMakeRange(0,string.length)];
    [string addAttribute:NSForegroundColorAttributeName value:[FontProperties getOrangeColor] range:NSMakeRange(7, 9)];
    postHighglightLabel.attributedText = string;
    postHighglightLabel.numberOfLines = 2;
    postHighglightLabel.lineBreakMode = NSLineBreakByWordWrapping;
    postHighglightLabel.textAlignment = NSTextAlignmentCenter;
    [_highlightButton addSubview:postHighglightLabel];
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
    
    UIButton *privateLogoButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 20 - 19 - 15, 15, 42, 46)];
    privateLogoButton.hidden = !self.event.isPrivate;
    privateLogoButton.enabled = self.event.isPrivate;
    [privateLogoButton addTarget:self action:@selector(showOverlayView) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:privateLogoButton];
    UIImageView *privacyImageView = [[UIImageView alloc] initWithFrame:CGRectMake(15, 15, 12, 16)];
    privacyImageView.image = [UIImage imageNamed:@"veryBlueLockClosed"];
    [privateLogoButton addSubview:privacyImageView];
}

- (void)showOverlayView {
    [UIView animateWithDuration:0.5f animations:^{
        self.visualEffectView.alpha = 1.0f;
    }];
}

- (void)setDetailViewRead {
    if (![self.event.isRead boolValue]) {
        [self.event setRead:^(BOOL success, NSError *error) {
            if (error) {
                [[WGError sharedInstance] logError:error forAction:WGActionSave];
            }
        }];
    }
}

#pragma mark - Button handler

- (void)goBack {
    [self.eventPeopleScrollView saveScrollPosition];
    [self.navigationController popViewControllerAnimated: YES];
}


- (void)sendPressed {
    [WGAnalytics tagEvent: @"Event Story Create Highlight Tapped"];

    //not going here
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    self.conversationViewController = [sb instantiateViewControllerWithIdentifier: @"EventConversationViewController"];
    self.conversationViewController.event = self.event;
    if (!self.eventMessages) self.conversationViewController.eventMessages = [[WGCollection alloc] initWithType:[WGEventMessage class]];
    if ([[WGProfile currentUser].eventAttending.id isEqualToNumber:self.event.id]) {
        self.conversationViewController.eventMessages = [self eventMessagesWithCamera];
    } else {
        self.conversationViewController.eventMessages = [self eventMessagesWithYourFace: NO];
    }
    self.conversationViewController.index = [NSNumber numberWithInteger:self.conversationViewController.eventMessages.count - 1];
    self.conversationViewController.storyDelegate = self;
    
    BOOL isPeeking  = (self.groupNumberID && ![self.groupNumberID isEqualToNumber:[WGProfile currentUser].group.id]);
    self.conversationViewController.isPeeking = isPeeking;

    _movingForward = YES;
    _loadViewFromFront = YES;
    [self presentViewController:self.conversationViewController animated:YES completion:nil];
}

- (WGCollection *)eventMessagesWithCamera {
    WGCollection *newEventMessages =  [[WGCollection alloc] initWithType:[WGEventMessage class]];
    
    [newEventMessages addObjectsFromCollection:self.eventMessages];
    
    WGEventMessage *eventMessage = [WGEventMessage serialize:@{
                                                               @"user": [WGProfile currentUser],
                                                               @"created": [NSDate nowStringUTC],
                                                               @"media_mime_type": kCameraType,
                                                               @"media": @""
                                                               }];
    
    [newEventMessages addObject:eventMessage];
    
    return newEventMessages;
}

- (void)fetchEventMessages {
    if (!self.cancelFetchMessages) {
        self.cancelFetchMessages = YES;
        __weak typeof(self) weakSelf = self;
        if (!self.eventMessages) {
            [self.event getMessages:^(WGCollection *collection, NSError *error) {
                __strong typeof(self) strongSelf = weakSelf;
                strongSelf.cancelFetchMessages = NO;
                [strongSelf.facesCollectionView didFinishPullToRefresh];
                if (error) {
                    [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                    [[WGError sharedInstance] logError:error forAction:WGActionLoad];
                    return;
                }
                strongSelf.eventMessages = collection;
                [strongSelf showOrNotShowToolTip];
                [strongSelf.facesCollectionView reloadData];
            }];
        } else if ([self.eventMessages.hasNextPage boolValue]) {
            [self.eventMessages addNextPage:^(BOOL success, NSError *error) {
                __strong typeof(self) strongSelf = weakSelf;
                strongSelf.cancelFetchMessages = NO;
                [strongSelf.facesCollectionView didFinishPullToRefresh];
                if (error) {
                    [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                    [[WGError sharedInstance] logError:error forAction:WGActionLoad];
                    return;
                }
                [strongSelf.facesCollectionView reloadData];
            }];
        } else {
            self.cancelFetchMessages = NO;
            [self.facesCollectionView didFinishPullToRefresh];
        }
    }
}


- (void)showOrNotShowToolTip {
    if (![self shouldShowToolTip]) {
        _highlightButton.alpha = 0.0f;
        _highlightButton.enabled = NO;
        _noHighlightsLabel.alpha = 0.0f;
    }
    else {
        [UIView animateWithDuration:1.5 animations:^{
            _highlightButton.alpha = 1.0f;
            _highlightButton.enabled = YES;
            _noHighlightsLabel.alpha = 1.0f;
        }];
    }
}

- (BOOL)shouldShowToolTip {
    BOOL isPeeking = (self.groupNumberID && ![self.groupNumberID isEqualToNumber:[WGProfile currentUser].group.id]);
    return (self.eventMessages.count == 0) && !isPeeking;
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
    _movingForward = YES;
    _loadViewFromFront = YES;
    [self presentViewController:self.conversationViewController animated:YES completion:nil];
}


- (void)readEventMessageIDArray:(NSArray *)eventMessageIDArray {
    dispatch_async(dispatch_get_main_queue(), ^{
        for (int i = 0; i < [eventMessageIDArray count]; i++) {
            NSNumber *eventMessageID = [eventMessageIDArray objectAtIndex:i];
            for (WGEventMessage *eventMessage in self.eventMessages) {
                if ([eventMessage.id isEqualToNumber:eventMessageID]) {
                    eventMessage.isRead = @YES;
                    break;
                }
            }
        }
        [self.facesCollectionView reloadData];
    });
}

#pragma mark - UIScrollViewDelegate 

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView != self.facesCollectionView) {
        return;
    }
    
    self.lineViewAtTop.hidden = NO;
    
    if (self.facesCollectionView.contentOffset.y < 0 && self.backgroundScrollview.contentOffset.y == 0) {
        return;
    }
    
    CGFloat stickHeight = self.eventPeopleScrollView.frame.size.height + self.eventPeopleScrollView.frame.origin.y;

    if (self.backgroundScrollview.contentOffset.y >= stickHeight && self.facesCollectionView.contentOffset.y > 0) {
        self.backgroundScrollview.contentOffset = CGPointMake(scrollView.contentOffset.x, stickHeight);
    } else if (self.backgroundScrollview.contentOffset.y < 0 && scrollView == self.facesCollectionView) {
        self.backgroundScrollview.contentOffset = CGPointMake(scrollView.contentOffset.x, 0);
    } else {
        
        self.backgroundScrollview.contentOffset = CGPointMake(scrollView.contentOffset.x, self.backgroundScrollview.contentOffset.y + scrollView.contentOffset.y);
        
        currentContentOffset = scrollView.contentOffset;
        self.facesCollectionView.contentOffset = CGPointMake(0, 0);
    }
}


#pragma mark - Places Delegate

- (void)showUser:(WGUser *)user {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ProfileViewController *profileViewController = [sb instantiateViewControllerWithIdentifier: @"ProfileViewController"];
    [profileViewController setStateWithUser: user];

    if (self.groupNumberID && ![self.groupNumberID isEqualToNumber:[WGProfile currentUser].group.id]) {
        profileViewController.userState = OTHER_SCHOOL_USER_STATE;
    }
    _loadViewFromFront = YES;
    [self.navigationController pushViewController: profileViewController animated: YES];
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
