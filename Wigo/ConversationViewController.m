//
//  ConversationViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/27/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "ConversationViewController.h"
#import "FontProperties.h"
#import "UIButtonAligned.h"
#import <QuartzCore/QuartzCore.h>

@interface ConversationViewController ()

@property UIScrollView *scrollView;
@property int positionOfLastMessage;
@property UIView *chatTextFieldWrapper;
@property UITextField *messageTextBox;

@property UIButton *sendButton;

@end

@implementation ConversationViewController

static inline UIViewAnimationOptions animationOptionsWithCurve(UIViewAnimationCurve curve)
{
    return (UIViewAnimationOptions)curve << 16;
}

- (id)init
{
    self = [super init];
    if (self) {
        // Custom initialization
        self.view.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    
    // Title setup
    
    self.title = @"Alice Banger";
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName:[FontProperties getOrangeColor], NSFontAttributeName:[FontProperties getTitleFont]};
    
    [self initializeLeftBarButton];
    [self initializeScrollView];
    [self initializeTapHandler];
    [self addMessageFromSenderWithText:@"I am going out to MeadHall with Katie and Rob. Wanna join?"];
    [self addMessageFromReceiverWithText:@"See you at MeadHall tonight!"];
    [self addTextBox];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];}

- (void) initializeScrollView {
    _positionOfLastMessage = 10;
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 50)];
    [self.view addSubview:_scrollView];
    _scrollView.contentSize = CGSizeMake(self.view.frame.size.width, _positionOfLastMessage);
}

- (void) initializeLeftBarButton {
    UIButtonAligned *barBt =[[UIButtonAligned alloc] initWithFrame:CGRectMake(0, 0, 65, 44) andType:@0];
    [barBt setImage:[UIImage imageNamed:@"backIcon"] forState:UIControlStateNormal];
    [barBt setTitle:@" Back" forState:UIControlStateNormal];
    [barBt setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
    barBt.titleLabel.font = [FontProperties getSubtitleFont];
    [barBt addTarget:self action: @selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barItem =  [[UIBarButtonItem alloc]init];
    [barItem setCustomView:barBt];
    self.navigationItem.leftBarButtonItem = barItem;
}

- (void) goBack {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) initializeTapHandler {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                action:@selector(dismissKeyboard)];
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];
}

-(void)dismissKeyboard {
    [self.view endEditing:YES];
}

- (void)addMessageFromSenderWithText:(NSString *)messageText {
    UIView *messageWrapper = [[UIView alloc] initWithFrame:CGRectMake(10, _positionOfLastMessage, 2*self.view.frame.size.width/3, 50)];
    messageWrapper.backgroundColor = RGB(234, 234, 234);
    [messageWrapper.layer setCornerRadius:5];
    messageWrapper.clipsToBounds = YES;
    [_scrollView addSubview:messageWrapper];
    
    UILabel *messageFromSender = [[UILabel alloc] initWithFrame:CGRectMake(10, 10 , 2*self.view.frame.size.width/3 , 50)];
    messageFromSender.backgroundColor = RGB(234, 234, 234);
    messageFromSender.text = messageText;
    messageFromSender.font = [UIFont fontWithName:@"Whitney-Light" size:15.0f];
    messageFromSender.numberOfLines = 0;
    messageFromSender.lineBreakMode = NSLineBreakByWordWrapping;
    [messageFromSender sizeToFit];
    
    CGSize sizeOfMessage = messageFromSender.frame.size;
    messageWrapper.frame = CGRectMake(10, _positionOfLastMessage , MAX(sizeOfMessage.width + 20, 100+ 20), sizeOfMessage.height + 20);
    [messageWrapper addSubview:messageFromSender];

    
    [self addTimerToView:messageWrapper];
    
    // left Image view for the chat
    UIImageView *leftBarBeforeMessage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"leftBeforeChatIcon"]];
    leftBarBeforeMessage.frame = CGRectMake(0, _positionOfLastMessage + messageFromSender.frame.size.height + 20 - 5, 10, 15);
    [_scrollView addSubview:leftBarBeforeMessage];
    _scrollView.contentSize = CGSizeMake(self.view.frame.size.width, _scrollView.contentSize.height + messageWrapper.frame.size.height + 10);
    _positionOfLastMessage += messageWrapper.frame.size.height + 10;
}


- (void)addMessageFromReceiverWithText:(NSString *)messageText {
    UIView *messageWraper = [[UIView alloc] initWithFrame:CGRectMake(10, _positionOfLastMessage, 2*self.view.frame.size.width/3, 50)];
    messageWraper.backgroundColor = RGB(250, 233, 212);
    [messageWraper.layer setCornerRadius:5];
    messageWraper.clipsToBounds = YES;
    [_scrollView addSubview:messageWraper];
    
    // Add text to the wrapper
    UILabel *messageFromReceiver = [[UILabel alloc] initWithFrame:CGRectMake(10, 10 , 2*self.view.frame.size.width/3, 50)];
    messageFromReceiver.text = messageText;
    messageFromReceiver.textAlignment = NSTextAlignmentRight;
    messageFromReceiver.font = [UIFont fontWithName:@"Whitney-Light" size:15.0f];
    [messageFromReceiver sizeToFit];
    
    // Adjust the size of the wrapper
    CGSize sizeOfMessage = messageFromReceiver.frame.size;
    messageWraper.frame = CGRectMake(self.view.frame.size.width - sizeOfMessage.width - 10 - 20,_positionOfLastMessage , MAX(sizeOfMessage.width + 20, 100 + 20), sizeOfMessage.height + 20);
    [messageWraper addSubview:messageFromReceiver];
    [self addTimerToView:messageWraper];
    
    // image at the right of the message
    UIImageView *rightBarAfterMessage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"rightAfterChatIcon"]];
    rightBarAfterMessage.frame = CGRectMake(self.view.frame.size.width - 10, _positionOfLastMessage +  messageFromReceiver.frame.size.height + 20 - 5, 10, 15);
    [_scrollView addSubview:rightBarAfterMessage];
    _scrollView.contentSize = CGSizeMake(self.view.frame.size.width, _scrollView.contentSize.height + messageWraper.frame.size.height + 10);
    _positionOfLastMessage += messageWraper.frame.size.height + 10;
}

- (void) addTimerToView:(UIView *)messageWrapper {
    messageWrapper.frame = CGRectMake(messageWrapper.frame.origin.x, messageWrapper.frame.origin.y, messageWrapper.frame.size.width, messageWrapper.frame.size.height + 20);
    
    UILabel *timerLabel = [[UILabel alloc] initWithFrame:CGRectMake(messageWrapper.frame.size.width - 110, messageWrapper.frame.size.height - 28, 100, 20)];
    NSDateFormatter *DateFormatter = [[NSDateFormatter alloc] init];
    [DateFormatter setDateFormat:@"hh:mm a"];
    
    timerLabel.text = [DateFormatter stringFromDate:[NSDate date]];
    timerLabel.font = [UIFont fontWithName:@"Whitney-Medium" size:13.0f];
    timerLabel.textAlignment = NSTextAlignmentRight;
    timerLabel.textColor = RGB(179, 179, 179);
    [messageWrapper addSubview:timerLabel];
}

- (void)addTextBox {
    _chatTextFieldWrapper = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 50, self.view.frame.size.width, 50)];
    [self.view addSubview:_chatTextFieldWrapper];
    [self.view bringSubviewToFront:_chatTextFieldWrapper];
    [_chatTextFieldWrapper setBackgroundColor:RGB(234, 234, 234)];
    
    UILabel *whiteLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, _chatTextFieldWrapper.frame.size.width - 70, _chatTextFieldWrapper.frame.size.height - 20)];
    whiteLabel.backgroundColor = [UIColor whiteColor];
    whiteLabel.layer.cornerRadius = 5;
    whiteLabel.layer.masksToBounds = YES;
    [_chatTextFieldWrapper addSubview:whiteLabel];
    
    _messageTextBox.tintColor = [FontProperties getOrangeColor];
    _messageTextBox = [[UITextField alloc] initWithFrame:CGRectMake(15, 10, _chatTextFieldWrapper.frame.size.width - 80, _chatTextFieldWrapper.frame.size.height - 20)];
    _messageTextBox.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Message" attributes:@{NSFontAttributeName:[FontProperties getTitleFont]}];
    _messageTextBox.delegate = self;
    _messageTextBox.returnKeyType = UIReturnKeySend;
    _messageTextBox.backgroundColor = [UIColor whiteColor];
    [[UITextField appearance] setTintColor:[FontProperties getOrangeColor]];
    [_chatTextFieldWrapper addSubview:_messageTextBox];
    [_chatTextFieldWrapper bringSubviewToFront:_messageTextBox];
    
    _sendButton = [[UIButton alloc] initWithFrame:CGRectMake(_chatTextFieldWrapper.frame.size.width - 60, 10, 60, 30)];
    [_sendButton addTarget:self action:@selector(sendMessage) forControlEvents:UIControlEventTouchDown];
    [_sendButton setTitle:@"Send" forState:UIControlStateNormal];
    [_sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _sendButton.backgroundColor = [UIColor clearColor];
    _sendButton.titleLabel.font = [FontProperties getTitleFont];
    [_chatTextFieldWrapper addSubview:_sendButton];
    
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [_sendButton setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
//    [UIView animateWithDuration:0.5 animations:^{
//        _chatTextFieldWrapper.transform = CGAffineTransformMakeTranslation(0, -216);
//    }];
    [self.view bringSubviewToFront:_chatTextFieldWrapper];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [_sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _chatTextFieldWrapper.transform = CGAffineTransformMakeTranslation(0, 0);
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    [theTextField resignFirstResponder];
    //    theTextField.text = @"";
    [self sendMessage];
    return YES;
}

- (void)sendMessage {
    [self addMessageFromSenderWithText:_messageTextBox.text];
    _messageTextBox.text = @"";
    [_scrollView scrollRectToVisible:CGRectMake(_scrollView.frame.origin.x, _scrollView.frame.origin.y , _scrollView.contentSize.width, _scrollView.contentSize.height) animated:YES];
}

- (void)keyboardWillShow:(NSNotification*)notification
{
    [self moveControls:notification up:YES];
}

- (void)keyboardWillBeHidden:(NSNotification*)notification
{
    [self moveControls:notification up:NO];
}

- (void)moveControls:(NSNotification*)notification up:(BOOL)up
{
    NSDictionary* userInfo = [notification userInfo];
    CGRect newFrame = [self getNewControlsFrame:userInfo up:up];
    
    [self animateControls:userInfo withFrame:newFrame];
}

- (CGRect)getNewControlsFrame:(NSDictionary*)userInfo up:(BOOL)up
{
    CGRect kbFrame = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    kbFrame = [self.view convertRect:kbFrame fromView:nil];
    
    CGRect newFrame = _chatTextFieldWrapper.frame;
    newFrame.origin.y += kbFrame.size.height * (up ? -1 : 1);
    
    return newFrame;
}

- (void)animateControls:(NSDictionary*)userInfo withFrame:(CGRect)newFrame
{
    NSTimeInterval duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    [UIView animateWithDuration:duration
                          delay:0
                        options:animationOptionsWithCurve(animationCurve)
                     animations:^{
                         _chatTextFieldWrapper.frame = newFrame;
                     }
                     completion:^(BOOL finished){}];
}


@end
