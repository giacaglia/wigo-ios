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
  
    [self loadEventMessages];
    [self loadEventDetails];
    [self loadMessages];
    [self loadEventStory];
    [self loadTextViewAndSendButton];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    
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

- (void)loadMessages {
}

- (void)loadTextViewAndSendButton {
    chatTextFieldWrapper = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 50, self.view.frame.size.width, 60)];
    [self.view addSubview:chatTextFieldWrapper];

    messageTextView.tintColor = [FontProperties getOrangeColor];
    messageTextView = [[UITextView alloc] initWithFrame:CGRectMake(10, 10, chatTextFieldWrapper.frame.size.width - 70, 35)];
    //    _messageTextView.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Message" attributes:@{NSFontAttributeName:[FontProperties getSmallFont]}];
    messageTextView.delegate = self;
    messageTextView.returnKeyType = UIReturnKeySend;
    messageTextView.backgroundColor = [UIColor whiteColor];
    messageTextView.layer.borderColor = RGB(147, 147, 147).CGColor;
    messageTextView.layer.borderWidth = 0.5f;
    messageTextView.layer.cornerRadius = 4.0f;
    messageTextView.font = [FontProperties mediumFont:18.0f];
    messageTextView.textColor = RGB(102, 102, 102);
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



#pragma mark - Button handler

- (void)goBack {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)sendPressed {
    IQMediaPickerController *controller = [[IQMediaPickerController alloc] init];
    [controller setMediaType:IQMediaPickerControllerMediaTypePhoto];
    controller.allowsPickingMultipleItems = YES;
    controller.delegate = self;
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)mediaPickerController:(IQMediaPickerController *)controller
       didFinishMediaWithInfo:(NSDictionary *)info {
    
    NSString *message = @"So much beer";
    NSDictionary *options;
    if ([[info allKeys] containsObject:@"IQMediaTypeImage"]) {
        NSString *imageURL = [[[info objectForKey:@"IQMediaTypeImage"] objectAtIndex:0] objectForKey:@"IQMediaURL" ];
        options =  @{
                     @"event": [self.event eventID],
                     @"message": message,
                     @"media_mime_type": @"image/jpeg"
                     };
        [self uploadContentWithFile:imageURL
                        andFileName:@"" andOptions:options];

    }
    else if ( [[info allKeys] containsObject:@"IQMediaTypeVideo"]) {
        NSString *videoURL = [[[info objectForKey:@"IQMediaTypeVideo"] objectAtIndex:0] objectForKey:@"IQMediaURL"];
        options =  @{
                     @"event": [self.event eventID],
                     @"message": message,
                     @"media_mime_type": @"video/mp4"
                     };
        [self uploadContentWithFile:videoURL
                        andFileName:@"" andOptions:options];
    }
}

- (void)uploadContentWithFile:(NSString *)filePath
                  andFileName:(NSString *)filename
                   andOptions:(NSDictionary *)options
{
    [Network sendAsynchronousHTTPMethod:GET
                            withAPIName:@"uploads/photos/?filename=image.jpg"
                            withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        NSArray *fields = [jsonResponse objectForKey:@"fields"];
        NSString *actionString = [jsonResponse objectForKey:@"action"];
        [AWSUploader uploadFields:fields
                    withActionURL:actionString
                         withFile:filePath
                      andFileName:filename];
        [Network sendAsynchronousHTTPMethod:POST
                                withAPIName:@"eventmessages/"
                                withHandler:^(NSDictionary *jsonResponse, NSError *error) {
                                    
                                } withOptions:options];

    }];
}

- (void)mediaPickerControllerDidCancel:(IQMediaPickerController *)controller {
    
}

- (void)loadEventMessages {
    [Network sendAsynchronousHTTPMethod:GET
                            withAPIName:@"eventmessages/"
                            withHandler:^(NSDictionary *jsonResponse, NSError *error) {
                                eventMessages = (NSArray *)[jsonResponse objectForKey:@"objects"];
                            }];
}


- (IBAction)showEventConversation:(id)sender {
    EventConversationViewController *conversationController = [self.storyboard instantiateViewControllerWithIdentifier: @"EventConversationViewController"];
    conversationController.event = self.event;
    if (eventMessages) conversationController.eventMessages = [NSMutableArray arrayWithArray:eventMessages];
    else conversationController.eventMessages = [NSMutableArray new];
    [self presentViewController:conversationController animated:YES completion:nil];
}





@end
