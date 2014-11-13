//
//  EventStoryViewController.m
//  Wigo
//
//  Created by Alex Grinman on 10/24/14.
//  Copyright (c) 2014 Alex Grinman. All rights reserved.
//

#import "EventStoryViewController.h"
#import "EventConversationViewController.h"
#import "EventPeopleScrollView.h"
#import "IQMediaPickerController.h"
#import "AWSUploader.h"

UIView *chatTextFieldWrapper;
UITextView *messageTextView;
UIButton *sendButton;
NSArray *eventMessages;

@implementation EventStoryViewController

#pragma mark - UIViewController Delegate
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.event.name;
  
    [self loadEventDetails];
    [self loadEventStory];
    [self loadTextViewAndSendButton];
}



- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    
    [self loadEventMessages];
    
    UIButton *aroundBackButton = [[UIButton alloc] initWithFrame:CGRectMake(20, 30, 40, 40)];
    [aroundBackButton addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:aroundBackButton];
    UIImageView *backImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 9, 15)];
    backImageView.image = [UIImage imageNamed:@"blueBackIcon"];
    [aroundBackButton addSubview:backImageView];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(45, 24, self.view.frame.size.width - 90, 36)];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.text = self.event.name;
    titleLabel.textColor = [FontProperties getBlueColor];
    titleLabel.font = [FontProperties getTitleFont];
    [self.view addSubview:titleLabel];
    
    UILabel *numberGoingLabel = [[UILabel alloc] initWithFrame:CGRectMake(110, 60, self.view.frame.size.width - 220, 20)];
    if ([self.event.numberAttending intValue] == 1) {
        numberGoingLabel.text = [NSString stringWithFormat:@"%@ is going", [self.event.numberAttending stringValue]];
    }
    else {
        numberGoingLabel.text = [NSString stringWithFormat:@"%@ are going", [self.event.numberAttending stringValue]];
    }
    numberGoingLabel.textColor = RGB(195, 195, 195);
    numberGoingLabel.textAlignment = NSTextAlignmentCenter;
    numberGoingLabel.font = [FontProperties mediumFont:15];
    [self.view addSubview:numberGoingLabel];
}

#pragma mark - Loading Messages

- (void)loadEventDetails {
    EventPeopleScrollView *eventScrollView = [[EventPeopleScrollView alloc] initWithEvent:self.event];
    [self.view addSubview:eventScrollView];
    
    UIButton *invitePeopleButton = [[UIButton alloc] initWithFrame:CGRectMake(70, 190, self.view.frame.size.width - 140, 30)];
    [invitePeopleButton setTitle:@"INVITE MORE PEOPLE" forState:UIControlStateNormal];
    [invitePeopleButton setTitleColor:[FontProperties getBlueColor] forState:UIControlStateNormal];
    invitePeopleButton.titleLabel.font = [FontProperties mediumFont:15];
    invitePeopleButton.layer.borderColor = [FontProperties getBlueColor].CGColor;
    invitePeopleButton.layer.borderWidth = 1.0f;
    invitePeopleButton.layer.cornerRadius = 5.0f;
    [self.view addSubview:invitePeopleButton];
}

- (void)loadEventStory {
    UILabel *eventStoryLabel = [[UILabel alloc] initWithFrame:CGRectMake(100, 220, self.view.frame.size.width - 200, 50)];
    eventStoryLabel.text = @"Event Story";
    eventStoryLabel.textColor = RGB(208, 208, 208);
    eventStoryLabel.textAlignment = NSTextAlignmentCenter;
    eventStoryLabel.font = [FontProperties mediumFont:20];
    [self.view addSubview:eventStoryLabel];
}

- (void)loadConversationViewController {
    StoryFlowLayout *flow = [[StoryFlowLayout alloc] init];
    UICollectionView *facesCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 260, self.view.frame.size.width, 260) collectionViewLayout:flow];
    
    facesCollectionView.backgroundColor = RGBAlpha(248, 253, 255, 100);
    facesCollectionView.showsHorizontalScrollIndicator = NO;
    facesCollectionView.showsVerticalScrollIndicator = NO;
    
    [facesCollectionView setCollectionViewLayout: flow];
    facesCollectionView.pagingEnabled = NO;
    [facesCollectionView registerClass:[FaceCell class] forCellWithReuseIdentifier:@"FaceCell"];
    
    facesCollectionView.dataSource = self;
    facesCollectionView.delegate = self;
    
    [self.view addSubview:facesCollectionView];
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
    myCell.isActive = YES;

    myCell.leftLine.backgroundColor = RGB(237, 237, 237);
    myCell.leftLineEnabled = (indexPath.row %3 > 0) && (indexPath.row > 0);
    
    myCell.rightLine.backgroundColor = RGB(237, 237, 237);
    myCell.rightLineEnabled = (indexPath.row % 3 < 2) && (indexPath.row < eventMessages.count - 1);

    User *user;
    NSDictionary *eventMessage = [eventMessages objectAtIndex:[indexPath row]];
    user = [[User alloc] initWithDictionary:[eventMessage objectForKey:@"user"]];
    if ([user isEqualToUser:[Profile user]]) {
        user = [Profile user];
    }
    if (user) [myCell.faceImageView setCoverImageForUser:user completed:nil];
    if ([[eventMessage objectForKey:@"media_mime_type"] isEqualToString:@"image/jpeg"]) {
        myCell.mediaTypeImageView.image = [UIImage imageNamed:@"imageType"];
    }
    else if ([[eventMessage objectForKey:@"media_mime_type"] isEqualToString:@"video/mp4"]) {
        myCell.mediaTypeImageView.image = [UIImage imageNamed:@"videoType"];
    }
    else {
        myCell.mediaTypeImageView.image = [UIImage imageNamed:@"textType"];
    }
    
    return myCell;
}

- (void)collectionView:(UICollectionView *)collectionView
    didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self showEventConversation:[NSNumber numberWithUnsignedInteger:indexPath.row]];
}


- (void)loadTextViewAndSendButton {
    chatTextFieldWrapper = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 50, self.view.frame.size.width, 60)];
    [self.view addSubview:chatTextFieldWrapper];

    messageTextView = [[UITextView alloc] initWithFrame:CGRectMake(10, 10, chatTextFieldWrapper.frame.size.width - 70, 35)];
    //    _messageTextView.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Message" attributes:@{NSFontAttributeName:[FontProperties getSmallFont]}];
    messageTextView.tintColor = [FontProperties getOrangeColor];
    messageTextView.delegate = self;
    messageTextView.returnKeyType = UIReturnKeySend;
    messageTextView.backgroundColor = [UIColor whiteColor];
    messageTextView.layer.borderColor = RGB(147, 147, 147).CGColor;
    messageTextView.layer.borderWidth = 0.5f;
    messageTextView.layer.cornerRadius = 4.0f;
    messageTextView.font = [FontProperties mediumFont:18.0f];
    messageTextView.textColor = RGB(102, 102, 102);
    messageTextView.delegate = self;
    [[UITextView appearance] setTintColor:RGB(102, 102, 102)];
    [chatTextFieldWrapper addSubview:messageTextView];
    [chatTextFieldWrapper bringSubviewToFront:messageTextView];
    
    sendButton = [[UIButton alloc] initWithFrame:CGRectMake(chatTextFieldWrapper.frame.size.width - 50, 10, 45, 35)];
    [sendButton addTarget:self action:@selector(sendPressed) forControlEvents:UIControlEventTouchUpInside];
    sendButton.backgroundColor = [FontProperties getOrangeColor];
    sendButton.layer.borderWidth = 1.0f;
    sendButton.layer.borderColor = [UIColor clearColor].CGColor;
    sendButton.layer.cornerRadius = 5;
    [chatTextFieldWrapper addSubview:sendButton];

    UIImageView *sendOvalImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 5, 25, 25)];
    sendOvalImageView.image = [UIImage imageNamed:@"sendOval"];
    [sendButton addSubview:sendOvalImageView];
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    EventConversationViewController *conversationController = [self.storyboard instantiateViewControllerWithIdentifier: @"EventConversationViewController"];
    conversationController.event = self.event;
    if (eventMessages) conversationController.eventMessages = [self eventMessagesWithText];
    else conversationController.eventMessages = [NSMutableArray new];
    conversationController.index = [NSNumber numberWithInt:eventMessages.count];
    
    IQMediaPickerController *controller = [[IQMediaPickerController alloc] init];
    [controller setMediaType:IQMediaPickerControllerMediaTypePhoto];
    controller.delegate = self;
    conversationController.controller = controller;
    
    [self presentViewController:conversationController animated:YES completion:nil];
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
    conversationController.index = [NSNumber numberWithInteger:conversationController.eventMessages.count];
    
    IQMediaPickerController *controller = [[IQMediaPickerController alloc] init];
    [controller setMediaType:IQMediaPickerControllerMediaTypePhoto];
    controller.delegate = self;
    conversationController.controller = controller;
    
    [self presentViewController:conversationController animated:YES completion:nil];
}

- (void)mediaPickerController:(IQMediaPickerController *)controller
       didFinishMediaWithInfo:(NSDictionary *)info {
    [self dismissViewControllerAnimated:YES completion:nil];
    NSDictionary *options;
    if ([[info allKeys] containsObject:IQMediaTypeImage]) {
        UIImage *image = [[[info objectForKey:IQMediaTypeImage] objectAtIndex:0] objectForKey:IQMediaImage];
        NSData *fileData = UIImageJPEGRepresentation(image, 1.0);
        if ([[info allKeys] containsObject:IQMediaTypeText]) {
            NSString *text = [[[info objectForKey:IQMediaTypeText] objectAtIndex:0] objectForKey:IQMediaText];
            NSNumber *yPosition = [[[info objectForKey:IQMediaTypeText] objectAtIndex:0] objectForKey:IQMediaYPosition];
            NSDictionary *properties = @{@"yPosition": yPosition};
            options =  @{
                         @"event": [self.event eventID],
                         @"message": text,
                         @"properties": properties,
                         @"media_mime_type": @"image/jpeg"
                         };
        }
        else {
            options =  @{
                         @"event": [self.event eventID],
                         @"media_mime_type": @"image/jpeg"
                         };
        }
      
        [self uploadContentWithFile:fileData
                        andFileName:@"image0.jpg"
                         andOptions:options];

    }
   
    else if ( [[info allKeys] containsObject:@"IQMediaTypeVideo"]) {
        NSLog(@"Video Taken");
        NSURL *videoURL = [[[info objectForKey:@"IQMediaTypeVideo"] objectAtIndex:0] objectForKey:@"IQMediaURL"];
        
        NSError *error;
        NSData *fileData = [NSData dataWithContentsOfURL: videoURL options: NSDataReadingMappedIfSafe error: &error];
        
        if ([[info allKeys] containsObject:IQMediaTypeText]) {
            NSString *text = [[[info objectForKey:IQMediaTypeText] objectAtIndex:0] objectForKey:IQMediaText];
            NSNumber *yPosition = [[[info objectForKey:IQMediaTypeText] objectAtIndex:0] objectForKey:IQMediaYPosition];
            NSDictionary *properties = @{@"yPosition": yPosition};
            options =  @{
                         @"event": [self.event eventID],
                         @"message": text,
                         @"properties": properties,
                         @"media_mime_type": @"video/mp4"
                         };
        }
        else {
            options =  @{
                         @"event": [self.event eventID],
                         @"media_mime_type": @"video/mp4"
                         };
        }
        
        [self uploadContentWithFile:fileData
                        andFileName:@"video0.mp4"
                         andOptions:options];
    }
}

- (NSMutableArray *)eventMessagesWithText {
    NSMutableArray *mutableEventMessages =  [NSMutableArray arrayWithArray:eventMessages];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    [dateFormatter setTimeZone:timeZone];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    [mutableEventMessages addObject:@{
                                      @"user": [[Profile user] dictionary],
                                      @"created": [dateFormatter stringFromDate:[NSDate date]],
                                      @"media_mime_type": @"newText",
                                      @"media": @""
                                      }];
    
    return mutableEventMessages;
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
                                      @"media_mime_type": @"new",
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
                                        
                                    } withOptions:[NSDictionary dictionaryWithDictionary:eventMessageOptions]];
        });

    }];
}

- (void)mediaPickerControllerDidCancel:(IQMediaPickerController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)loadEventMessages {
    [Network sendAsynchronousHTTPMethod:GET
                            withAPIName:@"eventmessages/?ordering=id"
                            withHandler:^(NSDictionary *jsonResponse, NSError *error) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    eventMessages = (NSArray *)[jsonResponse objectForKey:@"objects"];
                                    [self loadConversationViewController];
                                });
                            }];
}




- (void)showEventConversation:(NSNumber *)index {
    EventConversationViewController *conversationController = [self.storyboard instantiateViewControllerWithIdentifier: @"EventConversationViewController"];
    conversationController.event = self.event;
    conversationController.index = index;
    if (eventMessages) conversationController.eventMessages = [self eventMessagesWithCamera];
    else conversationController.eventMessages = [NSMutableArray new];
    
    IQMediaPickerController *controller = [[IQMediaPickerController alloc] init];
    [controller setMediaType:IQMediaPickerControllerMediaTypePhoto];
    controller.delegate = self;
    conversationController.controller = controller;
    
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
//    self.sectionInset = UIEdgeInsetsMake(0, 50, 0, 0);
    self.itemSize = CGSizeMake(100, 100);
    self.minimumLineSpacing = 0;
    self.minimumInteritemSpacing = 0;
    self.scrollDirection = UICollectionViewScrollDirectionVertical;
}

@end
