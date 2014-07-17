//
//  ConversationViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/27/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "ConversationViewController.h"
#import "Globals.h"
#import "UIButtonAligned.h"
#import "SDWebImage/UIImageView+WebCache.h"


@interface ConversationViewController ()

@property UIScrollView *scrollView;
@property int positionOfLastMessage;
@property UIView *chatTextFieldWrapper;
@property UITextField *messageTextField;

@property UIButton *sendButton;
@property User *user;
@property Party *messageParty;
@property UIActivityIndicatorView *spinner;

@end

@implementation ConversationViewController

static inline UIViewAnimationOptions animationOptionsWithCurve(UIViewAnimationCurve curve)
{
    return (UIViewAnimationOptions)curve << 16;
}

- (id)initWithUser: (User *)user
{
    self = [super init];
    if (self) {
        self.user = user;
        self.view.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.view.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    
    // Title setup
    self.title = [self.user fullName];
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName:[FontProperties getOrangeColor], NSFontAttributeName:[FontProperties getTitleFont]};
    
    [self initializeLeftBarButton];
    [self initializeRightBarButton];
    [self initializeScrollView];
    [self initializeTapHandler];
    
    _spinner = [[UIActivityIndicatorView alloc]initWithFrame:CGRectMake(135,140,80,80)];
    _spinner.center = self.view.center;
    _spinner.transform = CGAffineTransformMakeScale(2, 2);
    _spinner.color = [FontProperties getOrangeColor];
    [_spinner startAnimating];
    [self.view addSubview:_spinner];
    NSString *queryString = [NSString stringWithFormat:@"messages/?conversation=%@",[self.user objectForKey:@"id"]];
    [Network queryAsynchronousAPI:queryString withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [_spinner stopAnimating];
            NSArray *arrayOfMessages = [jsonResponse objectForKey:@"objects"];
            // Reorder them by time stamp
            arrayOfMessages = [[arrayOfMessages reverseObjectEnumerator] allObjects];
            _messageParty = [[Party alloc] initWithObjectName:@"Message"];
            [_messageParty addObjectsFromArray:arrayOfMessages];
            [self addMessages];
        });
    }];

    [self addTextBox];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void) addMessages {
    for (Message *message in [_messageParty getObjectArray]) {
        
        if ([[message fromUser] isEqualToUser:[Profile user]]) {
            [self addMessageFromSender:message];
        }
        else {
            [self addMessageFromReceiver:message];
        }
    }
    [_scrollView scrollRectToVisible:CGRectMake(_scrollView.frame.origin.x, _scrollView.frame.origin.y , _scrollView.contentSize.width, _scrollView.contentSize.height) animated:NO];
}

- (void) initializeScrollView {
    _positionOfLastMessage = 10;
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 50)];
    [self.view addSubview:_scrollView];
    _scrollView.contentSize = CGSizeMake(self.view.frame.size.width, _positionOfLastMessage);
}

- (void) initializeLeftBarButton {
    UIButtonAligned *barBt = [[UIButtonAligned alloc] initWithFrame:CGRectMake(0, 0, 65, 44) andType:@0];
    [barBt setImage:[UIImage imageNamed:@"backIcon"] forState:UIControlStateNormal];
    [barBt setTitle:@" Back" forState:UIControlStateNormal];
    [barBt setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
    barBt.titleLabel.font = [FontProperties getSubtitleFont];
    [barBt addTarget:self action: @selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barItem =  [[UIBarButtonItem alloc]init];
    [barItem setCustomView:barBt];
    self.navigationItem.leftBarButtonItem = barItem;
}

- (void) initializeRightBarButton {
    CGRect profileFrame = CGRectMake(0, 0, 30, 30);
    UIButtonAligned *profileButton = [[UIButtonAligned alloc] initWithFrame:profileFrame andType:@3];
    UIImageView *profileImageView = [[UIImageView alloc] initWithFrame:profileFrame];
    profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    profileImageView.clipsToBounds = YES;
    [profileImageView setImageWithURL:[NSURL URLWithString:[self.user coverImageURL]]];
    [profileButton addSubview:profileImageView];
    [profileButton setShowsTouchWhenHighlighted:YES];
    UIBarButtonItem *profileBarButton =[[UIBarButtonItem alloc] initWithCustomView:profileButton];
    self.navigationItem.rightBarButtonItem = profileBarButton;
}


- (void) goBack {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) initializeTapHandler {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                action:@selector(dismissKeyboard)];
    tap.cancelsTouchesInView = YES;
    [self.view addGestureRecognizer:tap];
}

-(void)dismissKeyboard {
    [self.view endEditing:YES];
}

- (void)addMessageFromReceiver:(Message *)message {
    UIView *messageWrapper = [[UIView alloc] initWithFrame:CGRectMake(10, _positionOfLastMessage, 2*self.view.frame.size.width/3, 50)];
    messageWrapper.backgroundColor = RGB(234, 234, 234);
    [messageWrapper.layer setCornerRadius:5];
    messageWrapper.clipsToBounds = YES;
    [_scrollView addSubview:messageWrapper];
    
    // Add text to the wrapper
    UILabel *messageFromReceiver = [[UILabel alloc] initWithFrame:CGRectMake(10, 10 , 2*self.view.frame.size.width/3 , 50)];
    messageFromReceiver.backgroundColor = RGB(234, 234, 234);
    messageFromReceiver.text = [message messageString];
    messageFromReceiver.font = [UIFont fontWithName:@"Whitney-Light" size:15.0f];
    messageFromReceiver.numberOfLines = 0;
    messageFromReceiver.lineBreakMode = NSLineBreakByWordWrapping;
    [messageFromReceiver sizeToFit];
    
    // Adjust size of the wrapper
    CGSize sizeOfMessage = messageFromReceiver.frame.size;
    messageWrapper.frame = CGRectMake(10, _positionOfLastMessage , MAX(sizeOfMessage.width + 20, 100+ 20), sizeOfMessage.height + 20);
    [messageWrapper addSubview:messageFromReceiver];

    [self addTimerOfMessage:message ToView:messageWrapper];
    
    // Left Image view for the chat
    UIImageView *leftBarBeforeMessage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"leftBeforeChatIcon"]];
    leftBarBeforeMessage.frame = CGRectMake(0, _positionOfLastMessage + messageFromReceiver.frame.size.height + 20 - 5, 10, 15);
    [_scrollView addSubview:leftBarBeforeMessage];
    _scrollView.contentSize = CGSizeMake(self.view.frame.size.width, _scrollView.contentSize.height + messageWrapper.frame.size.height + 10);
    _positionOfLastMessage += messageWrapper.frame.size.height + 10;
}


- (void)addMessageFromSender:(Message *)message {
    UIView *messageWraper = [[UIView alloc] initWithFrame:CGRectMake(10, _positionOfLastMessage, 2*self.view.frame.size.width/3, 50)];
    messageWraper.backgroundColor = RGB(250, 233, 212);
    [messageWraper.layer setCornerRadius:5];
    messageWraper.clipsToBounds = YES;
    [_scrollView addSubview:messageWraper];
    
    // Add text to the wrapper
    UILabel *messageFromSender = [[UILabel alloc] initWithFrame:CGRectMake(10, 10 , 2*self.view.frame.size.width/3, 50)];
    messageFromSender.text = [message messageString];;
    messageFromSender.textAlignment = NSTextAlignmentRight;
    messageFromSender.font = [UIFont fontWithName:@"Whitney-Light" size:15.0f];
    [messageFromSender sizeToFit];
    
    // Adjust the size of the wrapper
    CGSize sizeOfMessage = messageFromSender.frame.size;
    int widthOfMessage = MAX(sizeOfMessage.width + 20, 30 + 20);
    messageWraper.frame = CGRectMake(self.view.frame.size.width - 10 - widthOfMessage, _positionOfLastMessage , widthOfMessage, sizeOfMessage.height + 20);
    [messageWraper addSubview:messageFromSender];
    [self addTimerOfMessage:message ToView:messageWraper];
    
    // image at the right of the message
    UIImageView *rightBarAfterMessage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"rightAfterChatIcon"]];
    rightBarAfterMessage.frame = CGRectMake(self.view.frame.size.width - 10, _positionOfLastMessage +  messageFromSender.frame.size.height + 20 - 5, 10, 15);
    [_scrollView addSubview:rightBarAfterMessage];
    _scrollView.contentSize = CGSizeMake(self.view.frame.size.width, _scrollView.contentSize.height + messageWraper.frame.size.height + 10);
    _positionOfLastMessage += messageWraper.frame.size.height + 10;
}

- (void) addTimerOfMessage:(Message *)message ToView:(UIView *)messageWrapper {
    messageWrapper.frame = CGRectMake(messageWrapper.frame.origin.x, messageWrapper.frame.origin.y, messageWrapper.frame.size.width, messageWrapper.frame.size.height + 20);
    
    UILabel *timerLabel = [[UILabel alloc] initWithFrame:CGRectMake(messageWrapper.frame.size.width - 110, messageWrapper.frame.size.height - 28, 100, 20)];
    timerLabel.text = [message timeOfCreation];
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
    UIView *firstLineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 1)];
    firstLineView.backgroundColor = [FontProperties getLightOrangeColor];
    [_chatTextFieldWrapper addSubview:firstLineView];
    
    UILabel *whiteLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, _chatTextFieldWrapper.frame.size.width - 70, _chatTextFieldWrapper.frame.size.height - 20)];
    whiteLabel.backgroundColor = [UIColor whiteColor];
    whiteLabel.layer.cornerRadius = 5;
    whiteLabel.layer.masksToBounds = YES;
    [_chatTextFieldWrapper addSubview:whiteLabel];
    
    _messageTextField.tintColor = [FontProperties getOrangeColor];
    _messageTextField = [[UITextField alloc] initWithFrame:CGRectMake(15, 10, _chatTextFieldWrapper.frame.size.width - 80, _chatTextFieldWrapper.frame.size.height - 20)];
    _messageTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Message" attributes:@{NSFontAttributeName:[FontProperties getSmallFont]}];
    _messageTextField.delegate = self;
    _messageTextField.returnKeyType = UIReturnKeySend;
    _messageTextField.backgroundColor = [UIColor whiteColor];
    _messageTextField.font = [UIFont fontWithName:@"Whitney-Medium" size:18.0];;
    [_messageTextField setTextColor:RGB(102, 102, 102)];
    [[UITextField appearance] setTintColor:RGB(102, 102, 102)];
    [_chatTextFieldWrapper addSubview:_messageTextField];
    [_chatTextFieldWrapper bringSubviewToFront:_messageTextField];
    
    _sendButton = [[UIButton alloc] initWithFrame:CGRectMake(_chatTextFieldWrapper.frame.size.width - 60, 10, 60, 30)];
    [_sendButton addTarget:self action:@selector(sendMessage) forControlEvents:UIControlEventTouchUpInside];
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
    [self sendMessage];
    return YES;
}

- (void)sendMessage {
    if (![_messageTextField.text isEqualToString:@""]) {
        Message *message = [[Message alloc] init];
        [message setMessageString:_messageTextField.text];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
        [dateFormatter setTimeZone:timeZone];
        [dateFormatter setDateFormat:@"yyyy-MM-d hh:mm:ss"];
        [message setTimeOfCreation:[dateFormatter stringFromDate:[NSDate date]]];
        [message setToUser:[self.user objectForKey:@"id"]];
        [self addMessageFromSender:message];
        [message save];
        _messageTextField.text = @"";
    }
    [_scrollView scrollRectToVisible:CGRectMake(_scrollView.frame.origin.x, _scrollView.frame.origin.y , _scrollView.contentSize.width, _scrollView.contentSize.height) animated:YES];
    [self dismissKeyboard];
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
    
    // SCROLL VIEW resize
    CGRect kbFrame = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    kbFrame = [self.view convertRect:kbFrame fromView:nil];
    CGRect frame = _scrollView.frame;
    frame.size.height += kbFrame.size.height * (up ? -1 : 1);
    _scrollView.frame = frame;
    CGPoint bottomOffset = CGPointMake(0, self.scrollView.contentSize.height - self.scrollView.bounds.size.height);
    [_scrollView setContentOffset:bottomOffset animated:YES];
    
    CGRect newFrame = [self getNewControlsFrame:userInfo up:up forView:_chatTextFieldWrapper];
    [self animateControls:userInfo withFrame:newFrame];
}

- (CGRect)getNewControlsFrame:(NSDictionary*)userInfo up:(BOOL)up forView:(UIView *)view
{
    CGRect kbFrame = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    kbFrame = [self.view convertRect:kbFrame fromView:nil];
    
    CGRect newFrame = view.frame;
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
