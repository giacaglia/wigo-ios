//
//  EventStoryViewController.m
//  Wigo
//
//  Created by Alex Grinman on 10/24/14.
//  Copyright (c) 2014 Alex Grinman. All rights reserved.
//

#import "EventStoryViewController.h"
#import "EventConversationViewController.h"
#import "IQMediaPickerController.h"
#import "AWSUploader.h"
#import "InviteViewController.h"
#import "ProfileViewController.h"
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
  
    [self loadEventDetails];
    [self loadTextViewAndSendButton];
    EventPeopleScrollView *eventPeopleScrollView = [[EventPeopleScrollView alloc] initWithEvent:_event];
    eventPeopleScrollView.event = _event;
    eventPeopleScrollView.frame = CGRectMake(0, 80, self.view.frame.size.width, 100);
    [self.view addSubview:eventPeopleScrollView];
}



- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    
    [self loadEventMessages];
    
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
    
    UILabel *numberGoingLabel = [[UILabel alloc] initWithFrame:CGRectMake(110, 184, self.view.frame.size.width - 220, 20)];
    if ([self.event.numberAttending intValue] == 1) {
        numberGoingLabel.text = [NSString stringWithFormat:@"%@ is going", [self.event.numberAttending stringValue]];
    }
    else {
        numberGoingLabel.text = [NSString stringWithFormat:@"%@ are going", [self.event.numberAttending stringValue]];
    }
    numberGoingLabel.textColor = RGB(170, 170, 170);
    numberGoingLabel.textAlignment = NSTextAlignmentCenter;
    numberGoingLabel.font = [FontProperties mediumFont:15];
    [self.view addSubview:numberGoingLabel];
}

#pragma mark - Loading Messages

- (void)loadEventDetails {
    if ([[[Profile user] attendingEventID] isEqualToNumber:[self.event eventID]]) {
        UIButton *invitePeopleButton = [[UIButton alloc] initWithFrame:CGRectMake(70, 214, self.view.frame.size.width - 140, 30)];
        [invitePeopleButton setTitle:@"INVITE MORE PEOPLE" forState:UIControlStateNormal];
        [invitePeopleButton setTitleColor:[FontProperties getBlueColor] forState:UIControlStateNormal];
        invitePeopleButton.titleLabel.font = [FontProperties scMediumFont:14.0f];
        invitePeopleButton.layer.borderColor = [FontProperties getBlueColor].CGColor;
        invitePeopleButton.layer.borderWidth = 1.0f;
        invitePeopleButton.layer.cornerRadius = 5.0f;
        [invitePeopleButton addTarget:self action:@selector(invitePressed) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:invitePeopleButton];
    }
    else {
        UIButton *aroundGoOutButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 50, 214, 100, 30)];
        aroundGoOutButton.tag = [(NSNumber *)[self.event eventID] intValue];
        [aroundGoOutButton addTarget:self action:@selector(goHerePressed) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:aroundGoOutButton];
        
        UIButton *goOutButton = [[UIButton alloc] initWithFrame:CGRectMake(5, 5, 85, 25)];
        goOutButton.enabled = NO;
        [goOutButton setTitle:@"GO HERE" forState:UIControlStateNormal];
        [goOutButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        goOutButton.backgroundColor = [FontProperties getBlueColor];
        goOutButton.titleLabel.font = [FontProperties scMediumFont:12.0f];
        goOutButton.layer.cornerRadius = 5;
        goOutButton.layer.borderWidth = 1;
        goOutButton.layer.borderColor = [FontProperties getBlueColor].CGColor;
        [aroundGoOutButton addSubview:goOutButton];
    }
}

- (void)invitePressed {
    [self presentViewController:[[InviteViewController alloc] initWithEventName:self.event.name andID:[self.event eventID]]
                       animated:YES
                     completion:nil];
}

- (void)goHerePressed {
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@"Places", @"Go Here Source", nil];
    [EventAnalytics tagEvent:@"Go Here" withDetails:options];
    [[Profile user] setIsAttending:YES];
    [[Profile user] setIsGoingOut:YES];
    [[Profile user] setAttendingEventID:[self.event eventID]];
    [[Profile user] setEventID:[self.event eventID]];
    [Network postGoingToEventNumber:[[self.event eventID] intValue]];
}


- (void)loadConversationViewController {
    StoryFlowLayout *flow = [[StoryFlowLayout alloc] init];
    facesCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 235, self.view.frame.size.width, self.view.frame.size.height - 260) collectionViewLayout:flow];
    
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

#pragma mark - Button handler

- (void)goBack {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)sendPressed {
    EventConversationViewController *conversationController = [self.storyboard instantiateViewControllerWithIdentifier: @"EventConversationViewController"];
    conversationController.event = self.event;
    if (eventMessages) conversationController.eventMessages = [self eventMessagesWithCamera];
    else conversationController.eventMessages = [NSMutableArray new];
    conversationController.index = [NSNumber numberWithInteger:conversationController.eventMessages.count - 1];
    conversationController.controllerDelegate = self;
    
    [self presentViewController:conversationController animated:YES completion:nil];
}

- (void)mediaPickerController:(IQMediaPickerController *)controller
       didFinishMediaWithInfo:(NSDictionary *)info {
    [self dismissViewControllerAnimated:YES completion:nil];
    NSDictionary *options;
    NSString *type = @"";
    if ([[info allKeys] containsObject:IQMediaTypeImage]) {
        UIImage *image = [[[info objectForKey:IQMediaTypeImage] objectAtIndex:0] objectForKey:IQMediaImage];
        NSData *fileData = UIImageJPEGRepresentation(image, 1.0);
        type = kImageEventType;
        if ([[info allKeys] containsObject:IQMediaTypeText]) {
            NSString *text = [[[info objectForKey:IQMediaTypeText] objectAtIndex:0] objectForKey:IQMediaText];
            NSNumber *yPosition = [[[info objectForKey:IQMediaTypeText] objectAtIndex:0] objectForKey:IQMediaYPosition];
            NSDictionary *properties = @{@"yPosition": yPosition};
            options =  @{
                         @"event": [self.event eventID],
                         @"message": text,
                         @"properties": properties,
                         @"media_mime_type": type
                         };
        }
        else {
            options =  @{
                         @"event": [self.event eventID],
                         @"media_mime_type": type
                         };
        }
        [self uploadContentWithFile:fileData
                        andFileName:@"image0.jpg"
                         andOptions:options];

    }
   
    else if ( [[info allKeys] containsObject:@"IQMediaTypeVideo"]) {
        type = kVideoEventType;
        NSURL *videoURL = [[[info objectForKey:@"IQMediaTypeVideo"] objectAtIndex:0] objectForKey:@"IQMediaURL"];
        self.moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:videoURL];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(thumbnailGenerated:)
                                                     name:MPMoviePlayerThumbnailImageRequestDidFinishNotification
                                                   object:self.moviePlayer];

        [self.moviePlayer requestThumbnailImagesAtTimes:@[@0.0f] timeOption:MPMovieTimeOptionNearestKeyFrame];
        
        NSError *error;
        self.fileData = [NSData dataWithContentsOfURL: videoURL options: NSDataReadingMappedIfSafe error: &error];
        
        if ([[info allKeys] containsObject:IQMediaTypeText]) {
            NSString *text = [[[info objectForKey:IQMediaTypeText] objectAtIndex:0] objectForKey:IQMediaText];
            NSNumber *yPosition = [[[info objectForKey:IQMediaTypeText] objectAtIndex:0] objectForKey:IQMediaYPosition];
            NSDictionary *properties = @{@"yPosition": yPosition};
            self.options =  @{
                         @"event": [self.event eventID],
                         @"message": text,
                         @"properties": properties,
                         @"media_mime_type": type
                         };
        }
        else {
            self.options =  @{
                         @"event": [self.event eventID],
                         @"media_mime_type": type
                         };
        }
        
        
    }
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    [dateFormatter setTimeZone:timeZone];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    NSDictionary *eventMessage =  @{
                                    @"user": [Profile user].dictionary,
                                    @"created": [dateFormatter stringFromDate:[NSDate date]],
                                    @"media_mime_type": type,
                                    @"loading": @YES
                                    };
    NSMutableArray *mutableEventMessages = [NSMutableArray arrayWithArray:eventMessages];
    [mutableEventMessages addObject:eventMessage];
    eventMessages = [NSArray arrayWithArray:mutableEventMessages];
    [facesCollectionView reloadData];
    cancelFetchMessages = YES;
}

- (void)thumbnailGenerated:(NSNotification *)notification {
//    NSLog(@"thumbnail generated");
    NSDictionary *userInfo = [notification userInfo];
    UIImage *image = [userInfo valueForKey:MPMoviePlayerThumbnailImageKey];
    [self uploadVideo:self.fileData
        withVideoName:@"video0.mp4"
          andThumnail:UIImageJPEGRepresentation(image, 1.0f)
      andThumnailName:@"thumnail0.jpeg"
           andOptions:self.options];
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

- (void)uploadContentWithFile:(NSData *)fileData
                  andFileName:(NSString *)filename
                   andOptions:(NSDictionary *)options
{
    [Network sendAsynchronousHTTPMethod:GET
                            withAPIName:[NSString stringWithFormat: @"uploads/photos/?filename=%@", filename]
                            withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{

            NSArray *fields = [jsonResponse objectForKey:@"fields"];
            NSString *actionString = [jsonResponse objectForKey:@"action"];
            [AWSUploader uploadFields:fields
                        withActionURL:actionString
                             withFile:fileData
                          andFileName:filename];
            NSDictionary *eventMessageOptions = [[NSMutableDictionary alloc] initWithDictionary:options];
            [eventMessageOptions setValue:[AWSUploader valueOfFieldWithName:@"key" ofDictionary:fields] forKey:@"media"];
            [Network sendAsynchronousHTTPMethod:POST
                                    withAPIName:@"eventmessages/"
                                    withHandler:^(NSDictionary *jsonResponse, NSError *error) {
                                        if (!error) {
                                            NSMutableArray *mutableEventMessages = [NSMutableArray arrayWithArray:eventMessages];
                                            [mutableEventMessages replaceObjectAtIndex:(eventMessages.count - 1) withObject:jsonResponse];
                                            eventMessages = [NSArray arrayWithArray:mutableEventMessages];
                                            [facesCollectionView reloadData];
                                        }
                                        else {
                                            NSMutableArray *mutableEventMessages = [NSMutableArray arrayWithArray:eventMessages];
                                            [mutableEventMessages removeLastObject];
                                            eventMessages = [NSArray arrayWithArray:mutableEventMessages];
                                            [facesCollectionView reloadData];
                                        }
                                    } withOptions:[NSDictionary dictionaryWithDictionary:eventMessageOptions]];
        });

    }];
}

- (void)uploadVideo:(NSData *)fileData
      withVideoName:(NSString *)filename
        andThumnail:(NSData *)thumbnailData
    andThumnailName:(NSString *)thumnailFilename
        andOptions:(NSDictionary *)options
{
    [Network sendAsynchronousHTTPMethod:GET
                            withAPIName:[NSString stringWithFormat: @"uploads/videos/?filename=%@", filename]
                            withHandler:^(NSDictionary *jsonResponse, NSError *error) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    NSDictionary *videoDictionary = [jsonResponse objectForKey:@"video"];
                                    NSArray *videoFields = [videoDictionary objectForKey:@"fields"];
                                    NSString *videoActionString = [videoDictionary objectForKey:@"action"];
                                    
                                    [AWSUploader uploadFields:videoFields
                                                withActionURL:videoActionString
                                                     withFile:fileData
                                                  andFileName:filename
                                     withCompletion:^{
                                        NSDictionary *thumbnailDictionary = [jsonResponse objectForKey:@"thumbnail"];
                                        NSArray *fields = [thumbnailDictionary objectForKey:@"fields"];
                                        NSString *actionString = [thumbnailDictionary objectForKey:@"action"];
                                        [AWSUploader uploadFields:fields
                                                    withActionURL:actionString
                                                         withFile:thumbnailData
                                                      andFileName:thumnailFilename];
                                         
                                         NSDictionary *eventMessageOptions = [[NSMutableDictionary alloc] initWithDictionary:options];
                                         [eventMessageOptions setValue:[AWSUploader valueOfFieldWithName:@"key" ofDictionary:videoFields] forKey:@"media"];
                                         [eventMessageOptions setValue:[AWSUploader valueOfFieldWithName:@"key" ofDictionary:fields] forKey:@"thumbnail"];
                                         [Network sendAsynchronousHTTPMethod:POST
                                                                 withAPIName:@"eventmessages/"
                                                                 withHandler:^(NSDictionary *jsonResponse, NSError *error) {
                                                                     if (!error) {
                                                                         NSMutableArray *mutableEventMessages = [NSMutableArray arrayWithArray:eventMessages];
                                                                         [mutableEventMessages replaceObjectAtIndex:(eventMessages.count - 1) withObject:jsonResponse];
                                                                         eventMessages = [NSArray arrayWithArray:mutableEventMessages];
                                                                         [facesCollectionView reloadData];
                                                                     }
                                                                     else {
                                                                         NSMutableArray *mutableEventMessages = [NSMutableArray arrayWithArray:eventMessages];
                                                                         [mutableEventMessages removeLastObject];
                                                                         eventMessages = [NSArray arrayWithArray:mutableEventMessages];
                                                                         [facesCollectionView reloadData];
                                                                     }
                                                                 } withOptions:[NSDictionary dictionaryWithDictionary:eventMessageOptions]];
                                     }];
                                });
                            }];
}


- (void)mediaPickerControllerDidCancel:(IQMediaPickerController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)loadEventMessages {
    if (!cancelFetchMessages) {
        [Network sendAsynchronousHTTPMethod:GET
                                withAPIName:[NSString stringWithFormat:@"eventmessages/?event=%@&ordering=id", [self.event eventID]]
                                withHandler:^(NSDictionary *jsonResponse, NSError *error) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        eventMessages = (NSArray *)[jsonResponse objectForKey:@"objects"];
                                        [self loadConversationViewController];
                                    });
                                }];
    }
    cancelFetchMessages = NO;
}




- (void)showEventConversation:(NSNumber *)index {
    EventConversationViewController *conversationController = [self.storyboard instantiateViewControllerWithIdentifier: @"EventConversationViewController"];
    conversationController.event = self.event;
    conversationController.index = index;
    if (eventMessages) conversationController.eventMessages = [self eventMessagesWithCamera];
    else conversationController.eventMessages = [NSMutableArray new];
    conversationController.controllerDelegate = self;
    
    [self presentViewController:conversationController animated:YES completion:nil];
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
