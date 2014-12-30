
//
//  EventStoryViewController.m
//  Wigo
//
//  Created by Alex Grinman on 10/24/14.
//  Copyright (c) 2014 Alex Grinman. All rights reserved.
//

#import "EventStoryViewController.h"
#import "IQMediaPickerController.h"
#import "AWSUploader.h"
#import "InviteViewController.h"
#import "ReProfileViewController.h"
#import "EventMessagesConstants.h"
#import "FancyProfileViewController.h"

#define sizeOfEachFaceCell ([[UIScreen mainScreen] bounds].size.width - 20)/3
#define kHeaderLength 64
#define kHeaderFaceCollectionView @"headerFaceCollectionView"
#define kFooterFaceCollectionView @"footerFaceCollectionView"

@interface EventStoryViewController()<UIScrollViewDelegate> {
    UIButton *sendButton;
    NSArray *eventMessages;
    UICollectionView *facesCollectionView;
    BOOL cancelFetchMessages;
    NSDictionary *metaInfo;
    
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

    if (!self.groupNumberID || [self.groupNumberID isEqualToNumber:[[Profile user] groupID]]) {
        [self loadTextViewAndSendButton];
    }

    [self loadConversationViewController];
    [self setDetailViewRead];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    metaInfo = nil;

    if (facesCollectionView) [facesCollectionView reloadData];
    [self fetchEventMessages];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    [self.navigationController setNavigationBarHidden: YES animated: NO];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear: animated];
    
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
    if ([[self.event numberAttending] intValue] > 0) {
        self.numberGoingLabel.text = [NSString stringWithFormat:@"%@ are going", [self.event.numberAttending stringValue]];
    }
    else {
        self.numberGoingLabel.text = [NSString stringWithFormat:@"%@ is going", [self.event.numberAttending stringValue]];
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
    
    
    if (self.groupNumberID && ![self.groupNumberID isEqualToNumber:[[Profile user] groupID]]) {
        self.inviteButton.hidden = YES;
        self.inviteButton.enabled = NO;
        self.goHereButton.hidden = YES;
        self.goHereButton.enabled = NO;
    }
    else {
        if ([[[Profile user] attendingEventID] isEqualToNumber:[self.event eventID]]) {
            self.inviteButton.hidden = NO;
            self.inviteButton.enabled = YES;
        }
        else {
            self.goHereButton.hidden = NO;
            self.goHereButton.enabled = YES;
        }
    }
}

- (void)invitePressed {
    [self presentViewController:[[InviteViewController alloc] initWithEventName:self.event.name andID:[self.event eventID]]
                       animated:YES
                     completion:nil];
}

- (void)goHerePressed {
    // Update data
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@"Places", @"Go Here Source", nil];
    [EventAnalytics tagEvent:@"Go Here" withDetails:options];
    [[Profile user] setIsAttending:YES];
    [[Profile user] setIsGoingOut:YES];
    [[Profile user] setAttendingEventID:[self.event eventID]];
    [[Profile user] setEventID:[self.event eventID]];
    [Network postGoingToEventNumber:[[self.event eventID] intValue]];
    [self.event addUser:[Profile user]];
    [self.event setNumberAttending:@([self.event.numberAttending intValue] + 1)];

    // Update UI
    self.eventPeopleScrollView.event = self.event;
    [self.eventPeopleScrollView updateUI];
    self.goHereButton.hidden = YES;
    self.goHereButton.enabled = NO;
    self.inviteButton.hidden = NO;
    self.inviteButton.enabled = YES;
    self.numberGoingLabel.text = [NSString stringWithFormat:@"%@ going", [self.event.numberAttending stringValue]];
    
    [self presentFirstTimeGoingToEvent];

}

- (void)presentFirstTimeGoingToEvent {
    GOHERESTATE goHereState = (int)[[NSUserDefaults standardUserDefaults] integerForKey:kGoHereState];

    if (goHereState != DONOTPRESENTANYTHINGSTATE) {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        self.conversationViewController = [sb instantiateViewControllerWithIdentifier: @"EventConversationViewController"];
        self.conversationViewController.event = self.event;
        if (!eventMessages) self.conversationViewController.eventMessages = [NSMutableArray new];
        if (goHereState == PRESENTFACESTATE) {
            if (eventMessages) self.conversationViewController.eventMessages = [self eventMessagesWithYourFace:YES];
        }
        else {
            if (goHereState == FIRSTTIMEPRESENTCAMERASTATE) [[NSUserDefaults standardUserDefaults] setInteger:SECONDTIMEPRESENTCAMERASTATE forKey:kGoHereState];
            if (goHereState == SECONDTIMEPRESENTCAMERASTATE) [[NSUserDefaults standardUserDefaults] setInteger:DONOTPRESENTANYTHINGSTATE forKey:kGoHereState];
            if (eventMessages) self.conversationViewController.eventMessages = [self eventMessagesWithCamera];
        }
        self.conversationViewController.index = [NSNumber numberWithInteger:self.conversationViewController.eventMessages.count - 1];
        self.conversationViewController.controllerDelegate = self;
        self.conversationViewController.storyDelegate = self;
        [self presentViewController:self.conversationViewController animated:YES completion:nil];
    }
}


- (NSMutableArray *)eventMessagesWithYourFace:(BOOL)faceBool {
    NSMutableArray *mutableEventMessages =  [NSMutableArray arrayWithArray:eventMessages];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    [dateFormatter setTimeZone:timeZone];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *type = faceBool ? kFaceImage : kNotAbleToPost;
    [mutableEventMessages addObject:@{
                                      @"user": [[Profile user] dictionary],
                                      @"created": [dateFormatter stringFromDate:[NSDate date]],
                                      @"media_mime_type": type,
                                      @"media": @""
                                      }];
    
    return mutableEventMessages;
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
    
    if ([indexPath row] + 1 == eventMessages.count && [[metaInfo objectForKey:@"has_next_page"] boolValue]) {
        [self fetchEventMessages];
    }
    myCell.timeLabel.frame = CGRectMake(0, 0.75*sizeOfEachFaceCell + 3, sizeOfEachFaceCell, 30);
    myCell.mediaTypeImageView.hidden = NO;
    myCell.faceImageView.layer.borderColor = UIColor.blackColor.CGColor;
    
    User *user;
    NSDictionary *eventMessage = [eventMessages objectAtIndex:[indexPath row]];
    user = [[User alloc] initWithDictionary:[eventMessage objectForKey:@"user"]];
    if ([user isEqualToUser:[Profile user]]) {
        user = [Profile user];
    }
    [myCell.mediaTypeImageView setImageWithURL:[NSURL URLWithString:[user coverImageURL] ] imageArea:[user coverImageArea]];

    NSString *contentURL;
    if ([[eventMessage allKeys] containsObject:@"thumbnail"]) contentURL = [eventMessage objectForKey:@"thumbnail"];
    else  contentURL = [eventMessage objectForKey:@"media"];
    NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/%@", [Profile cdnPrefix], contentURL]];
    [myCell.spinner startAnimating];
    __weak FaceCell *weakCell = myCell;
    [myCell.faceImageView setImageWithURL:imageURL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakCell.spinner stopAnimating];
        });
    }];

    myCell.timeLabel.text = [Time getUTCTimeStringToLocalTimeString:[eventMessage objectForKey:@"created"]];
    myCell.timeLabel.textColor = RGB(59, 59, 59);
    myCell.faceAndMediaTypeView.alpha = 1.0f;
    
    if ([[eventMessage allKeys] containsObject:@"is_read"]) {
        if ([[eventMessage objectForKey:@"is_read"] boolValue]) {
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
    if (![[[self.event dictionary] objectForKey:@"is_read"] boolValue]) {
        [Network sendAsynchronousHTTPMethod:POST
                                withAPIName:@"events/read/"
                                withHandler:^(NSDictionary *jsonResponse, NSError *error) {
                                    if (!error) {
                                        NSLog(@"json response %@", jsonResponse);
                                    }
                                    else {
                                        NSLog(@"error %@", error);
                                    }
                                }
                                withOptions:(id)@[[self.event eventID]]
         ];
    }
}

#pragma mark - Button handler

- (void)goBack {
    [self.navigationController setNavigationBarHidden: NO animated: NO];
    [self.navigationController popViewControllerAnimated: YES];
}

- (void)sendPressed {
    
    //not going here
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    self.conversationViewController = [sb instantiateViewControllerWithIdentifier: @"EventConversationViewController"];
    self.conversationViewController.event = self.event;
    if (!eventMessages) self.conversationViewController.eventMessages = [NSMutableArray new];
    if ([[[Profile user] attendingEventID] isEqualToNumber:[self.event eventID]]) {
        self.conversationViewController.eventMessages = [self eventMessagesWithCamera];
    }
    else {
        self.conversationViewController.eventMessages = [self eventMessagesWithYourFace: NO];
    }
    self.conversationViewController.index = [NSNumber numberWithInteger:self.conversationViewController.eventMessages.count - 1];
    self.conversationViewController.controllerDelegate = self;
    self.conversationViewController.storyDelegate = self;
    [self presentViewController:self.conversationViewController animated:YES completion:nil];
}

- (NSMutableArray *)eventMessagesWithCamera {
    NSMutableArray *mutableEventMessages =  [NSMutableArray arrayWithArray:eventMessages];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    [dateFormatter setTimeZone:timeZone];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    [mutableEventMessages addObject:@{
                                      @"user": [[Profile user] dictionary],
                                      @"created": [dateFormatter stringFromDate:[NSDate date]],
                                      @"media_mime_type": kCameraType,
                                      @"media": @""
                                      }];

    return mutableEventMessages;
}


- (void)fetchEventMessages {
    if (!cancelFetchMessages) {
        cancelFetchMessages = YES;
        NSString *queryString;
        
        if ([[metaInfo objectForKey:@"has_next_page"] boolValue]) {
            NSString *nextAPIString = (NSString *)[metaInfo objectForKey:@"next"] ;
            queryString = [nextAPIString substringWithRange:NSMakeRange(5, nextAPIString.length - 5)];
        }
        else {
            queryString = [NSString stringWithFormat:@"eventmessages/?event=%@&limit=100", [self.event eventID]];
        }
        [Network sendAsynchronousHTTPMethod:GET
                                withAPIName:queryString
                                withHandler:^(NSDictionary *jsonResponse, NSError *error) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        if (metaInfo) {
                                            NSMutableArray *mutableEventMessages = [NSMutableArray arrayWithArray:eventMessages];
                                            [mutableEventMessages addObjectsFromArray:(NSArray *)[jsonResponse objectForKey:@"objects"]];
                                            eventMessages = [NSArray arrayWithArray:mutableEventMessages];
                                        }
                                        else {
                                            eventMessages = [NSMutableArray arrayWithArray:(NSArray *)[jsonResponse objectForKey:@"objects"]];
                                        }
                                        metaInfo = [jsonResponse objectForKey:@"meta"];
                                        [facesCollectionView reloadData];
                                        cancelFetchMessages = NO;
                                    });
                                }];
    }
}



- (void)showEventConversation:(NSNumber *)index {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    self.conversationViewController = [sb instantiateViewControllerWithIdentifier: @"EventConversationViewController"];
    self.conversationViewController.event = self.event;
    self.conversationViewController.index = index;
    if (!eventMessages) self.conversationViewController.eventMessages = [NSMutableArray new];
    if (![[[Profile user] attendingEventID] isEqualToNumber:[self.event eventID]]) {
         self.conversationViewController.eventMessages = [self eventMessagesWithYourFace:NO];
    }
    else {
        self.conversationViewController.eventMessages = [self eventMessagesWithCamera];
    }
    self.conversationViewController.storyDelegate = self;
    [self presentViewController:self.conversationViewController animated:YES completion:nil];
}


- (void)readEventMessageIDArray:(NSArray *)eventMessageIDArray {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableArray *mutableEventMessages = [NSMutableArray arrayWithArray:eventMessages];
        for (int i = 0; i < [eventMessageIDArray count]; i++) {
            NSNumber *eventMessageID = [eventMessageIDArray objectAtIndex:i];
            for (int j = 0; j < [eventMessages count]; j++) {
                NSMutableDictionary *eventMessage = [NSMutableDictionary dictionaryWithDictionary:[eventMessages objectAtIndex:j]];
                if ([[eventMessage objectForKey:@"id"] isEqualToNumber:eventMessageID]) {
                    [eventMessage setObject:@YES forKey:@"is_read"];
                    [mutableEventMessages setObject:eventMessage atIndexedSubscript:i];
                    break;
                }
            }
        }
        eventMessages = [NSArray arrayWithArray:mutableEventMessages];
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
    }
    else {
        
        self.backgroundScrollview.contentOffset = CGPointMake(scrollView.contentOffset.x, self.backgroundScrollview.contentOffset.y + scrollView.contentOffset.y);
        
        currentContentOffset = scrollView.contentOffset;
        facesCollectionView.contentOffset = CGPointMake(0, 0);
    }
    
}


#pragma mark - Places Delegate

- (void)showUser:(User *)user {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    FancyProfileViewController *fancyProfileViewController = [sb instantiateViewControllerWithIdentifier: @"FancyProfileViewController"];
    [fancyProfileViewController setStateWithUser: user];

    [self.navigationController setNavigationBarHidden: NO animated: NO];

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
