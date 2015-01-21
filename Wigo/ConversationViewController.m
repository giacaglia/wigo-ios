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
#import "FancyProfileViewController.h"

@interface ConversationViewController ()

@property UIScrollView *scrollView;
@property int positionOfLastMessage;
@property UIView *chatTextFieldWrapper;
@property CGRect frameOfChatField;
@property UITextView *messageTextView;

@property UIButton *sendButton;
@property WGUser *user;
@property WGCollection *messages;
@property UIView *viewForEmptyConversation;
@property UILabel *whiteLabelForTextField;

@end

NSNumber *page;
BOOL fetching;
FancyProfileViewController *profileViewController;
BOOL didBeginEditing;

@implementation ConversationViewController

static inline UIViewAnimationOptions animationOptionsWithCurve(UIViewAnimationCurve curve)
{
    return (UIViewAnimationOptions)curve << 16;
}

- (id)initWithUser: (WGUser *)user
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



    [self initializeLeftBarButton];
    [self initializeRightBarButton];
    [self initializeScrollView];
    [self initializeTapHandler];
    [self initializeTextBox];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    
    // Title setup
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName:[FontProperties getOrangeColor], NSFontAttributeName:[FontProperties getTitleFont]};
    self.navigationController.navigationBar.barTintColor = [FontProperties getOrangeColor];
    self.navigationController.navigationBar.tintColor = [FontProperties getOrangeColor];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [FontProperties getOrangeColor]}];
    self.navigationController.navigationBar.titleTextAttributes = [NSDictionary dictionaryWithObject:[FontProperties getOrangeColor] forKey:NSForegroundColorAttributeName];
    
    self.title = [self.user fullName];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [WGAnalytics tagEvent:@"Conversation View"];
    [self fetchFirstPageMessages];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    didBeginEditing = NO;
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

- (void) addFirstPageMessages {
    _positionOfLastMessage = 5;
    _scrollView.contentSize = CGSizeMake(self.view.frame.size.width, _positionOfLastMessage + 50);
    [[_scrollView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    for (WGMessage *message in _messages) {
        if ([message.user isCurrentUser]) {
            [self addMessageFromSender:message];
        } else {
            [self addMessageFromReceiver:message];
        }
    }
    if ([_messages count] == 0) {
        [self initializeMessageForEmptyConversation];
    }
    [_scrollView scrollRectToVisible:CGRectMake(_scrollView.frame.origin.x, _scrollView.frame.origin.y , _scrollView.contentSize.width, _scrollView.contentSize.height) animated:NO];
}

- (void) addMessages:(WGCollection *)messages {
    int oldContentSize = _scrollView.contentSize.height;
    _positionOfLastMessage = 5;
    _scrollView.contentSize = CGSizeMake(self.view.frame.size.width, _positionOfLastMessage);
    for (WGMessage *message in messages) {
        _positionOfLastMessage = 0;
        if ([message.user isCurrentUser])
            [self addMessageFromSender:message];
        else
            [self addMessageFromReceiver:message];
    }
    _scrollView.contentOffset = CGPointMake(0, _scrollView.contentSize.height);
    _scrollView.contentSize = CGSizeMake(self.view.frame.size.width, _scrollView.contentSize.height + oldContentSize);
}

- (void) initializeScrollView {
    self.automaticallyAdjustsScrollViewInsets = NO;
    _positionOfLastMessage = 10;
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64)];
    _scrollView.contentSize = CGSizeMake(self.view.frame.size.width, _positionOfLastMessage);
    _scrollView.delegate = self;
    [self.view addSubview:_scrollView];
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
    [profileButton addTarget:self action:@selector(showUser) forControlEvents:UIControlEventTouchUpInside];
    UIImageView *profileImageView = [[UIImageView alloc] initWithFrame:profileFrame];
    profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    profileImageView.clipsToBounds = YES;
    [profileImageView setImageWithURL:self.user.smallCoverImageURL imageArea:[self.user smallCoverImageArea]];
    [profileButton addSubview:profileImageView];
    [profileButton setShowsTouchWhenHighlighted:NO];
    UIBarButtonItem *profileBarButton =[[UIBarButtonItem alloc] initWithCustomView:profileButton];
    self.navigationItem.rightBarButtonItem = profileBarButton;
}

- (void)showUser {
    FancyProfileViewController* profileViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier: @"FancyProfileViewController"];
    [profileViewController setStateWithUser: self.user];
    profileViewController.user = self.user;
    [self.navigationController pushViewController:profileViewController animated:YES];}

- (void) goBack {
    [self.user readConversation:^(BOOL success, NSError *error) {
        // Do nothing?
    }];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) initializeTapHandler {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                action:@selector(dismissKeyboard)];
    tap.cancelsTouchesInView = YES;
    [_scrollView addGestureRecognizer:tap];
}

-(void)dismissKeyboard {
    [self.view endEditing:YES];
}

- (void)addMessageFromReceiver:(WGMessage *)message {
    UIView *messageWrapper = [[UIView alloc] initWithFrame:CGRectMake(10, _positionOfLastMessage, 2*self.view.frame.size.width/3, 50)];
    messageWrapper.backgroundColor = RGB(234, 234, 234);
    [messageWrapper.layer setCornerRadius:5];
    messageWrapper.clipsToBounds = YES;
    [_scrollView addSubview:messageWrapper];
    
    // Add text to the wrapper
    UILabel *messageFromReceiver = [[UILabel alloc] initWithFrame:CGRectMake(10, 10 , 2*self.view.frame.size.width/3 , 50)];
    messageFromReceiver.backgroundColor = RGB(234, 234, 234);
    messageFromReceiver.text = [message message];
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
    if ([page intValue] > 2) {
        for (UIView *messageView in [_scrollView subviews]) {
            messageView.frame = CGRectMake(messageView.frame.origin.x, messageView.frame.origin.y + messageWrapper.frame.size.height + 10, messageView.frame.size.width, messageView.frame.size.height);
        }
    }
}


- (void)addMessageFromSender:(WGMessage *)message {
    UIView *messageWrapper = [[UIView alloc] initWithFrame:CGRectMake(10, _positionOfLastMessage, 2*self.view.frame.size.width/3, 50)];
    messageWrapper.backgroundColor = RGB(250, 233, 212);
    [messageWrapper.layer setCornerRadius:5];
    messageWrapper.clipsToBounds = YES;
    [_scrollView addSubview:messageWrapper];
    
    // Add text to the wrapper
    UILabel *messageFromSender = [[UILabel alloc] initWithFrame:CGRectMake(10, 10 , 2*self.view.frame.size.width/3, 50)];
    messageFromSender.text = [message message];
    messageFromSender.textAlignment = NSTextAlignmentRight;
    messageFromSender.font = [FontProperties lightFont:15.0f];
    messageFromSender.numberOfLines = 0;
    messageFromSender.lineBreakMode = NSLineBreakByWordWrapping;
    [messageFromSender sizeToFit];
    
    // Adjust the size of the wrapper
    CGSize sizeOfMessage = messageFromSender.frame.size;
    int widthOfMessage = MAX(sizeOfMessage.width + 20, 60 + 20);
    messageWrapper.frame = CGRectMake(self.view.frame.size.width - 10 - widthOfMessage, _positionOfLastMessage , widthOfMessage, sizeOfMessage.height + 20);
    [messageWrapper addSubview:messageFromSender];
    [self addTimerOfMessage:message ToView:messageWrapper];
    
    // image at the right of the message
    UIImageView *rightBarAfterMessage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"rightAfterChatIcon"]];
    rightBarAfterMessage.frame = CGRectMake(self.view.frame.size.width - 10, _positionOfLastMessage +  messageFromSender.frame.size.height + 20 - 5, 10, 15);
    [_scrollView addSubview:rightBarAfterMessage];
    _scrollView.contentSize = CGSizeMake(self.view.frame.size.width, _scrollView.contentSize.height + messageWrapper.frame.size.height + 10);
    _positionOfLastMessage += messageWrapper.frame.size.height + 10;
    if ([page intValue] > 2) {
        for (UIView *messageView in [_scrollView subviews]) {
            messageView.frame = CGRectMake(messageView.frame.origin.x, messageView.frame.origin.y + messageWrapper.frame.size.height + 10, messageView.frame.size.width, messageView.frame.size.height);
        }
    }
}


- (void) addTimerOfMessage:(WGMessage *)message ToView:(UIView *)messageWrapper {
    messageWrapper.frame = CGRectMake(messageWrapper.frame.origin.x, messageWrapper.frame.origin.y, messageWrapper.frame.size.width, messageWrapper.frame.size.height + 20);
    
    UILabel *timerLabel = [[UILabel alloc] initWithFrame:CGRectMake(messageWrapper.frame.size.width - 110, messageWrapper.frame.size.height - 28, 100, 20)];
    timerLabel.text = [message.created getUTCTimeStringToLocalTimeString];
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
    if (!didBeginEditing) {
        _viewForEmptyConversation = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 30)];
        _viewForEmptyConversation.center = self.view.center;
        [self.view addSubview:_viewForEmptyConversation];
        
        UILabel *everyDayLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0 , self.view.frame.size.width, 30)];
        everyDayLabel.text = @"Start a new chat today.";
        everyDayLabel.textColor = [FontProperties getOrangeColor];
        everyDayLabel.textAlignment = NSTextAlignmentCenter;
        everyDayLabel.font = [FontProperties getBigButtonFont];
        [_viewForEmptyConversation addSubview:everyDayLabel];
    }
}


- (void)sendMessage {
    if (![_messageTextView.text isEqualToString:@""]) {
        WGMessage *message = [[WGMessage alloc] init];
        message.message = _messageTextView.text;
        message.created = [NSDate date];
        message.toUser = self.user;
        [message create:^(BOOL success, NSError *error) {
            if (error) {
                [[WGError sharedInstance] handleError:error actionType:WGActionPost retryHandler:nil];
                return;
            }
        }];
        
        [self addMessageFromSender:message];
        _messageTextView.text = @"";
        [_sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self textView:_messageTextView shouldChangeTextInRange:NSMakeRange(0, [_messageTextView.text length]) replacementText:@""];

    }
    CGPoint bottomOffset = CGPointMake(0, _scrollView.contentSize.height - _scrollView.bounds.size.height);
    if (bottomOffset.y < 0) [_scrollView setContentOffset:CGPointZero animated:YES];
    else [_scrollView setContentOffset:bottomOffset animated:YES];
    
}

- (void)updateLastMessagesRead:(WGMessage *)message {
    if ([message.id intValue] > [[WGProfile currentUser].lastMessageRead intValue]) {
        [WGProfile currentUser].lastMessageRead = message.id;
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
    //HACK For predictive shit
    if (CGRectEqualToRect(newFrame, CGRectMake(0, 12, [[UIScreen mainScreen] bounds].size.width, 50))) {
        newFrame =  CGRectMake(0, 303, [[UIScreen mainScreen] bounds].size.width, 50);
    }
    [self animateControls:userInfo withFrame:newFrame];
}

- (void)animateScrollViewUp:(BOOL)up withInfo:(NSDictionary *)userInfo {
    CGRect kbFrame = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    kbFrame = [self.view convertRect:kbFrame fromView:nil];

    if (CGRectEqualToRect(kbFrame,CGRectMake(0, 315, [[UIScreen mainScreen] bounds].size.width, 253))) {
        kbFrame =CGRectZero;
    }
    CGRect frame = _scrollView.frame;
    frame.size.height += kbFrame.size.height * (up ? -1 : 1);
    NSTimeInterval duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    _scrollView.frame = frame;
    [UIView animateWithDuration:duration
                          delay:0
                        options:animationOptionsWithCurve(animationCurve)
                     animations:^{
                         CGPoint bottomOffset = CGPointMake(0, _scrollView.contentSize.height - _scrollView.bounds.size.height);
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

- (void)addMessage:(NSNotification *)notification {
    NSNumber *fromUserID = [[notification userInfo] valueForKey:@"id"];
    if (fromUserID && [fromUserID isEqualToNumber:self.user.id]) {
        NSString *messageString = [[notification userInfo] valueForKey:@"message"];
        
        WGMessage *message = [[WGMessage alloc] init];
        message.message = messageString;
        message.created = [NSDate date];
        
        [self addMessageFromReceiver:message];
        CGPoint bottomOffset = CGPointMake(0, _scrollView.contentSize.height - _scrollView.bounds.size.height + 50);
        [_scrollView setContentOffset:bottomOffset animated:YES];
    }
}
        
# pragma mark - UITextView Delegate.

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqual:@"\n"]) {
        [self sendMessage];
        return NO;
    }
   
    if (([text isEqualToString:@""] && range.location == 0 && range.length == 1))
        [_sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    else if ([text length] != 0 || [textView.text length] != 0)
        [_sendButton setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];

    CGFloat requiredWidth = [textView sizeThatFits:CGSizeMake(HUGE_VALF, HUGE_VALF)].width;
    int numberOfRows = (int)(requiredWidth/textView.frame.size.width) + 1;
    _chatTextFieldWrapper.frame = CGRectMake(_chatTextFieldWrapper.frame.origin.x, _frameOfChatField.origin.y - 30*(numberOfRows - 1), _chatTextFieldWrapper.frame.size.width, _frameOfChatField.size.height + 30*(numberOfRows -1));
    _messageTextView.frame = CGRectMake(15, 10, _chatTextFieldWrapper.frame.size.width - 80, _chatTextFieldWrapper.frame.size.height - 20);
    _whiteLabelForTextField.frame = CGRectMake(10, 10, _chatTextFieldWrapper.frame.size.width - 70, _chatTextFieldWrapper.frame.size.height - 20);
    _sendButton.frame = CGRectMake(_chatTextFieldWrapper.frame.size.width - 60, _chatTextFieldWrapper.frame.size.height - 40, 60, 30);
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    [_sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _chatTextFieldWrapper.transform = CGAffineTransformMakeTranslation(0, 0);
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    didBeginEditing = YES;
    if (_viewForEmptyConversation) _viewForEmptyConversation.hidden = YES;
    [self.view bringSubviewToFront:_chatTextFieldWrapper];
}



# pragma mark - UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.contentOffset.y == 0)
        if ([_messages count] > 0 && [_messages.hasNextPage boolValue]) {
            [self fetchMessages];
        }
}


# pragma mark - Network functions

- (void)fetchFirstPageMessages {
    fetching = NO;
    [self fetchMessages];
}

- (void)fetchMessages {
    if (!fetching) {
        fetching = YES;
        [WiGoSpinnerView showOrangeSpinnerAddedTo:self.view];
        if (!_messages) {
            [self.user getConversation:^(WGCollection *collection, NSError *error) {
                if (error) {
                    [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                    fetching = NO;
                    return;
                }
                _messages = collection;
                [self addFirstPageMessages];
                [WiGoSpinnerView hideSpinnerForView:self.view];
                fetching = NO;
            }];
        } else if ([_messages.hasNextPage boolValue]) {
            [_messages getNextPage:^(WGCollection *collection, NSError *error) {
                if (error) {
                    [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                    fetching = NO;
                    return;
                }
                
                [_messages addObjectsFromCollection:collection];
                _messages.hasNextPage = collection.hasNextPage;
                _messages.nextPage = collection.nextPage;
                
                [self addMessages:collection];
                [WiGoSpinnerView hideSpinnerForView:self.view];
                fetching = NO;
            }];
        } else {
            fetching = NO;
            [WiGoSpinnerView hideSpinnerForView:self.view];
        }
    }
}
        

@end
