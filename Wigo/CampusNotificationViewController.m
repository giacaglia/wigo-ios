//
//  CampusNotificationViewController.m
//  Wigo
//
//  Created by Alex Grinman on 11/25/14.
//  Copyright (c) 2014 Alex Grinman. All rights reserved.
//

#import "CampusNotificationViewController.h"
#import "Globals.h"
#import "UIButtonAligned.h"


#define MAX_NOTIFICATION_LENGTH 100

@interface CampusNotificationViewController() <UITextViewDelegate> {
    NSString *placeholderText;
}

@property (nonatomic, strong) IBOutlet UILabel *rallyLabel;
@property (nonatomic, strong) IBOutlet UITextView *notificationTextView;
@property (nonatomic, strong) IBOutlet UIButton *sendButton;
@property (nonatomic, strong) IBOutlet UILabel *charCountLabel;

@end


@implementation CampusNotificationViewController


- (void) viewDidLoad {
    [super viewDidLoad];
    self.title = @"Campus Notification";
    self.navigationItem.titleView.tintColor = [FontProperties getOrangeColor];
    self.navigationController.navigationBar.backgroundColor = RGB(235, 235, 235);

    self.tableView.scrollEnabled = NO;
    self.tableView.separatorColor = [UIColor clearColor];
    
    self.tableView.tableFooterView = [[UIView alloc] init];

    [self initializeLeftBarButton];
    placeholderText = self.notificationTextView.text;
    //style text and buttons
    
    self.rallyLabel.font = [FontProperties mediumFont: 17.0f];
    self.charCountLabel.font = [FontProperties lightFont: 12.0f];
    self.charCountLabel.text = [NSString stringWithFormat: @"%i", MAX_NOTIFICATION_LENGTH];
    
    self.notificationTextView.font = [FontProperties mediumFont: 17.0f];
    self.notificationTextView.delegate = self;
    
    [self.sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.sendButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.sendButton.titleLabel.font = [FontProperties mediumFont: 18];
    self.sendButton.layer.borderColor = [FontProperties getOrangeColor].CGColor;
    self.sendButton.layer.borderWidth = 1;
    self.sendButton.layer.cornerRadius = 4;
    self.sendButton.backgroundColor = [FontProperties getOrangeColor];
    
}

- (void) initializeLeftBarButton {
    UIButtonAligned *barBt =[[UIButtonAligned alloc] initWithFrame:CGRectMake(0, 0, 65, 44) andType:@0];
    [barBt setImage:[UIImage imageNamed:@"backIcon"] forState:UIControlStateNormal];
    [barBt setTitle:@" Back" forState:UIControlStateNormal];
    [barBt setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
    barBt.titleLabel.font = [FontProperties getSmallFont];
    [barBt addTarget:self action: @selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barItem =  [[UIBarButtonItem alloc]init];
    [barItem setCustomView:barBt];
    self.navigationItem.leftBarButtonItem = barItem;
}

- (void) goBack {
    [self.navigationController popViewControllerAnimated: YES];
}

- (IBAction)sendForApproval {
    if ([self.notificationTextView.text isEqualToString: @""] || [self.notificationTextView.text isEqualToString: placeholderText]) {
        //TODO: Show error here
        return;
    }
}

# pragma mark - TextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    if ([[textView text] length] - range.length + text.length > MAX_NOTIFICATION_LENGTH) {
        return NO;
    }
    
    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if ([textView.text isEqualToString: placeholderText]) {
        textView.text = @"";
    }
}

- (void) textViewDidEndEditing:(UITextView *)textView {
    if ([self.notificationTextView.text isEqualToString: @""]) {
        textView.text = placeholderText;
    }
}
- (void)textViewDidChange:(UITextView *)textView {
    self.charCountLabel.text = [NSString stringWithFormat: @"%u", MAX_NOTIFICATION_LENGTH - textView.text.length];
}
@end
