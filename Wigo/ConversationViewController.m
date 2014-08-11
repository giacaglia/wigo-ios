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
#import "ProfileViewController.h"

@interface ConversationViewController ()

@property UIScrollView *scrollView;
@property int positionOfLastMessage;
@property UIView *chatTextFieldWrapper;
@property CGRect frameOfChatField;
@property UITextView *messageTextView;

@property UIButton *sendButton;
@property User *user;
@property Party *messageParty;
@property UIView *viewForEmptyConversation;
@property UILabel *whiteLabelForTextField;

@end

ProfileViewController *profileViewController;

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
        [self initializeNotificationObservers];
        self.view.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self initializeNotificationObservers];
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
    [self initializeTextBox];
    
    [self fetchMessages];
}

- (void) initializeNotificationObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(addMessage:)
                                                 name:@"updateConversation"
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
    if ([[_messageParty getObjectArray] count] == 0) {
        [self initializeMessageForEmptyConversation];
    }
    
    [_scrollView scrollRectToVisible:CGRectMake(_scrollView.frame.origin.x, _scrollView.frame.origin.y , _scrollView.contentSize.width, _scrollView.contentSize.height) animated:NO];
}

- (void) initializeScrollView {
    _positionOfLastMessage = 10;
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
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
    [profileButton addTarget:self action:@selector(profileSegue) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *profileBarButton =[[UIBarButtonItem alloc] initWithCustomView:profileButton];
    self.navigationItem.rightBarButtonItem = profileBarButton;
}

- (void) goBack {
    NSString *queryString = [NSString stringWithFormat:@"conversations/%@/", [self.user objectForKey:@"id"]];
    NSDictionary *options = @{@"read": [NSNumber numberWithBool:YES]};
    [Network sendAsynchronousHTTPMethod:POST
                            withAPIName:queryString
                            withHandler:^(NSDictionary *jsonResponse, NSError *error) {}
                            withOptions:options];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)profileSegue {
    profileViewController = [[ProfileViewController alloc] initWithUser:self.user];
    [self.navigationController pushViewController:profileViewController animated:YES];
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
    messageFromReceiver.font = [FontProperties lightFont:15.0f];
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
    messageFromSender.text = [message messageString];
    messageFromSender.textAlignment = NSTextAlignmentRight;
    messageFromSender.font = [FontProperties lightFont:15.0f];
    messageFromSender.numberOfLines = 0;
    messageFromSender.lineBreakMode = NSLineBreakByWordWrapping;
    [messageFromSender sizeToFit];
    
    // Adjust the size of the wrapper
    CGSize sizeOfMessage = messageFromSender.frame.size;
    int widthOfMessage = MAX(sizeOfMessage.width + 20, 60 + 20);
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
    timerLabel.font = [FontProperties mediumFont:15.0f];
    timerLabel.textAlignment = NSTextAlignmentRight;
    timerLabel.textColor = RGB(179, 179, 179);
    [messageWrapper addSubview:timerLabel];
}

- (void)initializeTextBox {
    _chatTextFieldWrapper = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 50, self.view.frame.size.width, 50)];
    [self.view addSubview:_chatTextFieldWrapper];
    [self.view bringSubviewToFront:_chatTextFieldWrapper];
    [_chatTextFieldWrapper setBackgroundColor:RGB(234, 234, 234)];
    UIView *firstLineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 1)];
    firstLineView.backgroundColor = [FontProperties getLightOrangeColor];
    [_chatTextFieldWrapper addSubview:firstLineView];
    
    _whiteLabelForTextField = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, _chatTextFieldWrapper.frame.size.width - 70, _chatTextFieldWrapper.frame.size.height - 20)];
    _whiteLabelForTextField.layer.cornerRadius = 5;
    _whiteLabelForTextField.layer.masksToBounds = YES;
    [_chatTextFieldWrapper addSubview:_whiteLabelForTextField];
    
    _messageTextView.tintColor = [FontProperties getOrangeColor];
    _messageTextView = [[UITextView alloc] initWithFrame:CGRectMake(15, 10, _chatTextFieldWrapper.frame.size.width - 80, _chatTextFieldWrapper.frame.size.height - 20)];
//    _messageTextView.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Message" attributes:@{NSFontAttributeName:[FontProperties getSmallFont]}];
    _messageTextView.delegate = self;
    _messageTextView.returnKeyType = UIReturnKeySend;
    _messageTextView.backgroundColor = [UIColor whiteColor];
    _messageTextView.font = [FontProperties mediumFont:18.0f];
    _messageTextView.textColor = RGB(102, 102, 102);
    [[UITextView appearance] setTintColor:RGB(102, 102, 102)];
    [_chatTextFieldWrapper addSubview:_messageTextView];
    [_chatTextFieldWrapper bringSubviewToFront:_messageTextView];
    
    _sendButton = [[UIButton alloc] initWithFrame:CGRectMake(_chatTextFieldWrapper.frame.size.width - 60, 10, 60, 30)];
    [_sendButton addTarget:self action:@selector(sendMessage) forControlEvents:UIControlEventTouchUpInside];
    [_sendButton setTitle:@"Send" forState:UIControlStateNormal];
    [_sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _sendButton.backgroundColor = [UIColor clearColor];
    _sendButton.titleLabel.font = [FontProperties getTitleFont];
    [_chatTextFieldWrapper addSubview:_sendButton];
}

- (void)initializeMessageForEmptyConversation {
    _viewForEmptyConversation = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 30)];
    _viewForEmptyConversation.center = self.view.center;
    [self.view addSubview:_viewForEmptyConversation];
    
    UILabel *everyDayLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0 , self.view.frame.size.width, 30)];
    everyDayLabel.text = @"Every day on WiGo is a new day.";
    everyDayLabel.textColor = [FontProperties getOrangeColor];
    everyDayLabel.textAlignment = NSTextAlignmentCenter;
    everyDayLabel.font = [FontProperties getBigButtonFont];
    [_viewForEmptyConversation addSubview:everyDayLabel];
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if (_viewForEmptyConversation) _viewForEmptyConversation.hidden = YES;
    [_sendButton setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];

    [self.view bringSubviewToFront:_chatTextFieldWrapper];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    [_sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _chatTextFieldWrapper.transform = CGAffineTransformMakeTranslation(0, 0);
}

- (void)sendMessage {
    if (![_messageTextView.text isEqualToString:@""]) {
        Message *message = [[Message alloc] init];
        [message setMessageString:_messageTextView.text];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
        [dateFormatter setTimeZone:timeZone];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        [message setTimeOfCreation:[dateFormatter stringFromDate:[NSDate date]]];
        [message setToUser:[self.user objectForKey:@"id"]];
        [self addMessageFromSender:message];
        [message saveAsynchronously];
        _messageTextView.text = @"";
        [_sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self textView:_messageTextView shouldChangeTextInRange:NSMakeRange(0, [_messageTextView.text length]) replacementText:@""];

    }
    CGPoint bottomOffset = CGPointMake(0, _scrollView.contentSize.height - _scrollView.bounds.size.height + 50);
    [_scrollView setContentOffset:bottomOffset animated:YES];
}

- (void)updateLastMessagesRead:(Message *)message {
    User *profileUser = [Profile user];
    if ([(NSNumber *)[message objectForKey:@"id"] intValue] > [(NSNumber *)[[Profile user] lastMessageRead] intValue]) {
        [profileUser setLastMessageRead:[message objectForKey:@"id"]];
    }
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
    
    [self animateScrollViewUp:up withInfo:userInfo];
   
    CGRect newFrame = [self getNewControlsFrame:userInfo up:up forView:_chatTextFieldWrapper];
    [self animateControls:userInfo withFrame:newFrame];
}

- (void)animateScrollViewUp:(BOOL)up withInfo:(NSDictionary *)userInfo {
    CGRect kbFrame = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    kbFrame = [self.view convertRect:kbFrame fromView:nil];
    CGRect frame = _scrollView.frame;
    frame.size.height += kbFrame.size.height * (up ? -1 : 1);
    NSTimeInterval duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    _scrollView.frame = frame;
    [UIView animateWithDuration:duration
                          delay:0
                        options:animationOptionsWithCurve(animationCurve)
                     animations:^{
                         CGPoint bottomOffset = CGPointMake(0, _scrollView.contentSize.height - _scrollView.bounds.size.height + 50);
                         [_scrollView setContentOffset:bottomOffset animated:NO];
                     }
                     completion:^(BOOL finished){}];
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
                         _frameOfChatField = newFrame;
                     }
                     completion:^(BOOL finished){}];
}
        
# pragma mark - UITextView Delegate.

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqual:@"\n"]) {
        [self sendMessage];
        return NO;
    }
    if ([_messageTextView.text length] != 0)
        [_sendButton setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
    else
        [_sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

    CGFloat requiredWidth = [textView sizeThatFits:CGSizeMake(HUGE_VALF, HUGE_VALF)].width;
    int numberOfRows = (int)(requiredWidth/textView.frame.size.width) + 1;
    _chatTextFieldWrapper.frame = CGRectMake(_chatTextFieldWrapper.frame.origin.x, _frameOfChatField.origin.y - 30*(numberOfRows - 1), _chatTextFieldWrapper.frame.size.width, _frameOfChatField.size.height + 30*(numberOfRows -1));
    _messageTextView.frame = CGRectMake(15, 10, _chatTextFieldWrapper.frame.size.width - 80, _chatTextFieldWrapper.frame.size.height - 20);
    _whiteLabelForTextField.frame = CGRectMake(10, 10, _chatTextFieldWrapper.frame.size.width - 70, _chatTextFieldWrapper.frame.size.height - 20);
    _sendButton.frame = CGRectMake(_chatTextFieldWrapper.frame.size.width - 60, _chatTextFieldWrapper.frame.size.height - 40, 60, 30);
    return YES;
}

- (void)addMessage:(NSNotification *)notification {
    NSString *messageString = [[notification userInfo] valueForKey:@"message"];
    Message *message = [[Message alloc] init];
    [message setMessageString:messageString];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    [dateFormatter setTimeZone:timeZone];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [message setTimeOfCreation:[dateFormatter stringFromDate:[NSDate date]]];
    [self addMessageFromReceiver:message];
    CGPoint bottomOffset = CGPointMake(0, _scrollView.contentSize.height - _scrollView.bounds.size.height + 50);
    [_scrollView setContentOffset:bottomOffset animated:YES];
}

# pragma mark - Network functions

- (void)fetchMessages {
    [[_scrollView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [WiGoSpinnerView showOrangeSpinnerAddedTo:self.view];
    NSString *queryString = [NSString stringWithFormat:@"messages/?conversation=%@",[self.user objectForKey:@"id"]];
    [Network queryAsynchronousAPI:queryString withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [WiGoSpinnerView hideSpinnerForView:self.view];
            NSArray *arrayOfMessages = [jsonResponse objectForKey:@"objects"];
            // Reorder them by time stamp
            arrayOfMessages = [[arrayOfMessages reverseObjectEnumerator] allObjects];
            _messageParty = [[Party alloc] initWithObjectType:MESSAGE_TYPE];
            [_messageParty addObjectsFromArray:arrayOfMessages];
            [self addMessages];
        });
    }];
}
        

@end
