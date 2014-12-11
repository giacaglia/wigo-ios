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

UIButton *sendButton;
NSArray *eventMessages;
UICollectionView *facesCollectionView;
BOOL cancelFetchMessages;

@implementation EventStoryViewController

#pragma mark - UIViewController Delegate
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.event.name;
  
    [self loadConversationViewController];
    [self loadEventDetails];
    [self loadTextViewAndSendButton];
    [self loadEventPeopleScrollView];
    [self loadEventTitle];
    [self setDetailViewRead];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    [self loadEventMessages];
}

#pragma mark - Loading Messages

- (void)loadEventDetails {
    self.inviteButton = [[UIButton alloc] initWithFrame:CGRectMake(70, 220, self.view.frame.size.width - 140, 30)];
    [self.inviteButton setTitle:@"INVITE MORE PEOPLE" forState:UIControlStateNormal];
    [self.inviteButton setTitleColor:[FontProperties getBlueColor] forState:UIControlStateNormal];
    self.inviteButton.titleLabel.font = [FontProperties scMediumFont:14.0f];
    self.inviteButton.layer.borderColor = [FontProperties getBlueColor].CGColor;
    self.inviteButton.layer.borderWidth = 1.0f;
    self.inviteButton.layer.cornerRadius = 5.0f;
    [self.inviteButton addTarget:self action:@selector(invitePressed) forControlEvents:UIControlEventTouchUpInside];
    self.inviteButton.hidden = YES;
    self.inviteButton.enabled = NO;
    [self.view addSubview:self.inviteButton];
    
    self.aroundGoHereButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 50, 220, 100, 30)];
    self.aroundGoHereButton.tag = [(NSNumber *)[self.event eventID] intValue];
    [self.aroundGoHereButton addTarget:self action:@selector(goHerePressed) forControlEvents:UIControlEventTouchUpInside];
    self.aroundGoHereButton.hidden = YES;
    self.aroundGoHereButton.enabled = NO;
    [self.view addSubview:self.aroundGoHereButton];
    
    UIButton *goOutButton = [[UIButton alloc] initWithFrame:CGRectMake(5, 5, 85, 25)];
    goOutButton.enabled = NO;
    [goOutButton setTitle:@"GO HERE" forState:UIControlStateNormal];
    [goOutButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    goOutButton.backgroundColor = [FontProperties getBlueColor];
    goOutButton.titleLabel.font = [FontProperties scMediumFont:12.0f];
    goOutButton.layer.cornerRadius = 5;
    goOutButton.layer.borderWidth = 1;
    goOutButton.layer.borderColor = [FontProperties getBlueColor].CGColor;
    [self.aroundGoHereButton addSubview:goOutButton];

    
    if ([[[Profile user] attendingEventID] isEqualToNumber:[self.event eventID]]) {
        self.inviteButton.hidden = NO;
        self.inviteButton.enabled = YES;
    }
    else {
        self.aroundGoHereButton.hidden = NO;
        self.aroundGoHereButton.enabled = YES;
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
    self.aroundGoHereButton.hidden = YES;
    self.aroundGoHereButton.enabled = NO;
    self.inviteButton.hidden = NO;
    self.inviteButton.enabled = YES;
    self.numberGoingLabel.text = [NSString stringWithFormat:@"%@ are going", [self.event.numberAttending stringValue]];
    
    [self presentFirstTimeGoingToEvent];

}

- (void)presentFirstTimeGoingToEvent {
    GOHERESTATE goHereState = [[NSUserDefaults standardUserDefaults] integerForKey:kGoHereState];

    if (goHereState != DONOTPRESENTANYTHINGSTATE) {
        self.conversationViewController = [self.storyboard instantiateViewControllerWithIdentifier: @"EventConversationViewController"];
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
    facesCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 245, self.view.frame.size.width, self.view.frame.size.height - 260) collectionViewLayout:flow];
    
    facesCollectionView.backgroundColor = UIColor.whiteColor;
    facesCollectionView.showsHorizontalScrollIndicator = NO;
    facesCollectionView.showsVerticalScrollIndicator = NO;
    
    [facesCollectionView setCollectionViewLayout: flow];
    facesCollectionView.pagingEnabled = NO;
    [facesCollectionView registerClass:[FaceCell class] forCellWithReuseIdentifier:@"FaceCell"];
    
    facesCollectionView.dataSource = self;
    facesCollectionView.delegate = self;
    
    [self.view addSubview:facesCollectionView];
    [self.view sendSubviewToBack:facesCollectionView];
}




#pragma mark - UICollectionView Data Source

-(NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return eventMessages.count + 1;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    FaceCell *myCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"FaceCell" forIndexPath: indexPath];
    [myCell setToActiveWithNoAnimation];

    myCell.leftLine.backgroundColor = RGB(237, 237, 237);
    myCell.leftLineEnabled = (indexPath.row %3 > 0) && (indexPath.row > 0);
    
    myCell.rightLine.backgroundColor = RGB(237, 237, 237);
    myCell.rightLineEnabled = (indexPath.row % 3 < 2) && (indexPath.row < eventMessages.count);
    
    if ([indexPath row] == eventMessages.count) {
        myCell.faceImageView.image = [UIImage imageNamed:@"addStory"];
        myCell.faceImageView.layer.borderColor = UIColor.clearColor.CGColor;
        myCell.timeLabel.frame = CGRectMake(23, 83, 60, 28);
        myCell.timeLabel.text = @"Add to the story";
        myCell.timeLabel.textColor = RGB(59, 59, 59);
        myCell.timeLabel.layer.shadowColor = [RGB(59, 59, 59) CGColor];
        myCell.mediaTypeImageView.hidden = YES;
        [myCell updateUIToRead:NO];
        return myCell;
    }
    myCell.mediaTypeImageView.hidden = NO;
    myCell.faceImageView.layer.borderColor = UIColor.blackColor.CGColor;
    myCell.mediaTypeImageView.hidden = NO;
    
    User *user;
    NSDictionary *eventMessage = [eventMessages objectAtIndex:[indexPath row]];
    user = [[User alloc] initWithDictionary:[eventMessage objectForKey:@"user"]];
    if ([user isEqualToUser:[Profile user]]) {
        user = [Profile user];
    }
    if (user) [myCell.faceImageView setCoverImageForUser:user completed:nil];
    if ([[eventMessage objectForKey:@"media_mime_type"] isEqualToString:kImageEventType]) {
        myCell.mediaTypeImageView.image = [UIImage imageNamed:@"imageType"];
    }
    else if ([[eventMessage objectForKey:@"media_mime_type"] isEqualToString:kVideoEventType]) {
        myCell.mediaTypeImageView.image = [UIImage imageNamed:@"videoType"];
    }
    myCell.timeLabel.text = [Time getUTCTimeStringToLocalTimeString:[eventMessage objectForKey:@"created"]];
    myCell.timeLabel.textColor = RGB(59, 59, 59);
    if ([[eventMessage allKeys] containsObject:@"loading"]) {
        myCell.spinner.hidden = NO;
        [myCell.spinner startAnimating];
        myCell.faceImageView.alpha = 0.4f;
        myCell.mediaTypeImageView.alpha = 0.4f;
        myCell.userInteractionEnabled = NO;
    }
    else {
        if (myCell.spinner.isAnimating) {
            [myCell.spinner stopAnimating];
            myCell.faceImageView.alpha = 1.0f;
            myCell.mediaTypeImageView.alpha = 1.0f;
        }
    }
    
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


- (void)loadTextViewAndSendButton {
    sendButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 70, self.view.frame.size.height - 70, 60, 60)];
    [sendButton addTarget:self action:@selector(sendPressed) forControlEvents:UIControlEventTouchUpInside];
    sendButton.backgroundColor = [FontProperties getOrangeColor];
    sendButton.layer.borderWidth = 1.0f;
    sendButton.layer.borderColor = [UIColor clearColor].CGColor;
    sendButton.layer.cornerRadius = 30;
    sendButton.layer.shadowColor = [UIColor blackColor].CGColor;
    sendButton.layer.shadowOpacity = 0.4f;
    sendButton.layer.shadowRadius = 8.0f;
    sendButton.layer.shadowOffset = CGSizeMake(0.0f, 3.0f);
    [self.view addSubview:sendButton];
    [self.view bringSubviewToFront:sendButton];

    UIImageView *sendOvalImageView = [[UIImageView alloc] initWithFrame:CGRectMake(20, 20, 20, 20)];
    sendOvalImageView.image = [UIImage imageNamed:@"plusStoryButton"];
    [sendButton addSubview:sendOvalImageView];
}

- (void)loadEventPeopleScrollView {
    self.eventPeopleScrollView = [[EventPeopleScrollView alloc] initWithEvent:_event];
    self.eventPeopleScrollView.sizeOfEachImage = 110;
    self.eventPeopleScrollView.event = _event;
    self.eventPeopleScrollView.userSelectDelegate = self;
    [self.eventPeopleScrollView updateUI];
    self.eventPeopleScrollView.frame = CGRectMake(0, 80, self.view.frame.size.width, 140);
    [self.view addSubview:self.eventPeopleScrollView];
}

- (void)loadEventTitle {
    UIButton *aroundBackButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 25, 50, 50)];
    [aroundBackButton addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:aroundBackButton];
    UIImageView *backImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 9, 15)];
    backImageView.image = [UIImage imageNamed:@"blueBackIcon"];
    [aroundBackButton addSubview:backImageView];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(45, 24, self.view.frame.size.width - 90, 50)];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.numberOfLines = 0;
    titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    titleLabel.text = self.event.name;
    titleLabel.textColor = [FontProperties getBlueColor];
    titleLabel.font = [FontProperties getTitleFont];
    [self.view addSubview:titleLabel];
    
    self.numberGoingLabel = [[UILabel alloc] initWithFrame:CGRectMake(110, 65, self.view.frame.size.width - 220, 20)];
    self.numberGoingLabel.text = [NSString stringWithFormat:@"%@ going", [self.event.numberAttending stringValue]];
    self.numberGoingLabel.textColor = RGB(170, 170, 170);
    self.numberGoingLabel.textAlignment = NSTextAlignmentCenter;
    self.numberGoingLabel.font = [FontProperties mediumFont:15];
    [self.view addSubview:self.numberGoingLabel];
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
                                withOptions:@[[self.event eventID]]
         ];
    }
}

#pragma mark - Button handler

- (void)goBack {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)sendPressed {
    self.conversationViewController = [self.storyboard instantiateViewControllerWithIdentifier: @"EventConversationViewController"];
    self.conversationViewController.event = self.event;
    if (!eventMessages) self.conversationViewController.eventMessages = [NSMutableArray new];
    if ([[[Profile user] attendingEventID] isEqualToNumber:[self.event eventID]]) {
        self.conversationViewController.eventMessages = [self eventMessagesWithCamera];
    }
    else {
        self.conversationViewController.eventMessages = [self eventMessagesWithYourFace:YES];
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


- (void)loadEventMessages {
    if (!cancelFetchMessages) {
        [Network sendAsynchronousHTTPMethod:GET
                                withAPIName:[NSString stringWithFormat:@"eventmessages/?event=%@&ordering=id", [self.event eventID]]
                                withHandler:^(NSDictionary *jsonResponse, NSError *error) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        eventMessages = (NSArray *)[jsonResponse objectForKey:@"objects"];
                                        [facesCollectionView reloadData];
                                    });
                                }];
    }
    cancelFetchMessages = NO;
}



- (void)showEventConversation:(NSNumber *)index {
    self.conversationViewController = [self.storyboard instantiateViewControllerWithIdentifier: @"EventConversationViewController"];
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

#pragma mark - Places Delegate

- (void)showUser:(User *)user {
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController: [[ReProfileViewController alloc] initWithUser:user]];
    
    [self presentViewController: navController animated: YES completion: nil];
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
    self.sectionInset = UIEdgeInsetsMake(0, 10, 10, 10);
    self.itemSize = CGSizeMake(100, 100);
    self.minimumLineSpacing = 0;
    self.minimumInteritemSpacing = 0;
    self.scrollDirection = UICollectionViewScrollDirectionVertical;
}

@end
