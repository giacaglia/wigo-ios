//
//  MoreViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 7/28/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "MoreViewController.h"
#import "Globals.h"


UIButton *unfriendButton;
UIButton *blockButton;
UIButton *cancelButton;

@implementation MoreViewController

-(void) viewDidLoad
{
    [super viewDidLoad];
    
    float heighBkgButtonsView;
    if (self.user.state == FRIEND_USER_STATE)
        heighBkgButtonsView = 3*68 +2*6 + 7;
    else
        heighBkgButtonsView = 2*68 + 2*6 + 7;
    UIView *bkgButtonsView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - heighBkgButtonsView, self.view.frame.size.width, heighBkgButtonsView)];
    bkgButtonsView.backgroundColor = RGB(247, 247, 247);
    [self.view addSubview:bkgButtonsView];

    if (self.user.state == FRIEND_USER_STATE) {
        unfriendButton = [[UIButton alloc] initWithFrame:CGRectMake(6, self.view.frame.size.height - 3*68 - 6 - 7 - 1, self.view.frame.size.width - 12, 68)];
        unfriendButton.backgroundColor = UIColor.whiteColor;
        [unfriendButton setTitle:@"UNFRIEND" forState:UIControlStateNormal];
        [unfriendButton setTitleColor:RGB(236, 61, 83) forState:UIControlStateNormal];
        unfriendButton.titleLabel.font = [FontProperties getTitleFont];
        unfriendButton.layer.borderColor = RGB(177, 177, 177).CGColor;
        unfriendButton.layer.borderWidth = 1.0f;
        [unfriendButton addTarget:self action:@selector(unfriendPressed) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:unfriendButton];
    }
    
    blockButton = [[UIButton alloc] initWithFrame:CGRectMake(6, self.view.frame.size.height - 2*68 - 6 - 7, self.view.frame.size.width - 12, 68)];
    blockButton.backgroundColor = UIColor.whiteColor;
    [blockButton addTarget:self action:@selector(blockButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [blockButton setTitle:@"BLOCK or REPORT" forState:UIControlStateNormal];
    [blockButton setTitleColor:RGB(236, 61, 83) forState:UIControlStateNormal];
    blockButton.titleLabel.font = [FontProperties getTitleFont];
    blockButton.layer.borderColor = RGB(177, 177, 177).CGColor;
    blockButton.layer.borderWidth = 1.0f;
    [self.view addSubview:blockButton];

    cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(6, self.view.frame.size.height - 68 - 6, self.view.frame.size.width - 12, 68)];
    cancelButton.backgroundColor = UIColor.whiteColor;
    [cancelButton addTarget:self action:@selector(cancelPressed) forControlEvents:UIControlEventTouchUpInside];
    [cancelButton setTitle:@"CANCEL" forState:UIControlStateNormal];
    [cancelButton setTitleColor:RGB(74, 74, 74) forState:UIControlStateNormal];
    cancelButton.titleLabel.font = [FontProperties getTitleFont];
    cancelButton.layer.borderColor = RGB(177, 177, 177).CGColor;
    cancelButton.layer.borderWidth = 1.0f;
    [self.view addSubview:cancelButton];
}


-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    self.parentViewController.navigationController.navigationBar.hidden = YES;
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.view addSubview:self.bgView];
    [self.view sendSubviewToBack:self.bgView];
}

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.parentViewController.navigationController.navigationBar.hidden = NO;
}

-(void) goBack {
    [UIView animateWithDuration:0.15 animations:^{
        self.view.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [self.profileDelegate removeMoreVc];
    }];
}

-(void) unfriendPressed {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"unfollowPressed" object:nil userInfo:nil];
    [self goBack];
}

-(void) submitBlockPressed {
    int type = (int)((int)blockButton.tag / 10)  - 1;
    NSDictionary *userInfo = @{@"user": self.user.deserialize, @"type":[NSNumber numberWithInt:type]};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"blockPressed" object:nil userInfo:userInfo];
    
    [self goBack];
}

- (void)blockButtonPressed {
    [UIView animateWithDuration:1 animations:^(void) {
        if (unfriendButton) unfriendButton.alpha = 1.0f;
    } completion:^(BOOL finished){
        if (unfriendButton) unfriendButton.alpha = 0.0f;
        [self addOptions];
        UIButton *firstBox = (UIButton *)[self.view viewWithTag:1];
        [self checkedBox:firstBox];
    }];
}

- (void)cancelPressed {
    [self goBack];
}

- (void)addOptions {
    UILabel *blockLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 20, self.view.frame.size.width - 30, 60)];
    blockLabel.text = [NSString stringWithFormat:@"Block %@", self.user.fullName];
    blockLabel.textColor = [UIColor whiteColor];
    blockLabel.textAlignment = NSTextAlignmentCenter;
    blockLabel.font = [FontProperties mediumFont:24.0f];
    blockLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    blockLabel.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    [self.view addSubview:blockLabel];
    
    UILabel *whyLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 80, self.view.frame.size.width - 30, 40)];
    whyLabel.text = @"Why?";
    whyLabel.textColor = [UIColor whiteColor];
    whyLabel.textAlignment = NSTextAlignmentCenter;
    whyLabel.font = [FontProperties mediumFont:20.0f];
    [self.view addSubview:whyLabel];
    
    [blockButton setTitle:@"SUBMIT" forState:UIControlStateNormal];
    blockButton.backgroundColor = [FontProperties getOrangeColor];
    blockButton.tag = 10;
    [blockButton removeTarget:self action:@selector(blockButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [blockButton addTarget:self action:@selector(submitBlockPressed) forControlEvents:UIControlEventTouchUpInside];
    [cancelButton setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
   
    [self addCheckBoxWithTag:1 atYPosition:220];
    [self addLabelWithText:[NSString stringWithFormat:@"%@ is just annoying to me", self.user.firstName]
                    andTag:1
               atYPosition:220 - 15];
    
 
    [self addCheckBoxWithTag:5 atYPosition:290];
    [self addLabelWithText:[NSString stringWithFormat:@"%@ is abusive and should be banned for all users", self.user.firstName] andTag:5
               atYPosition:290 - 15];
}

- (void)addCheckBoxWithTag:(int)tag atYPosition:(int)yPosition{
    UIButton *checkBox = [[UIButton alloc] initWithFrame:CGRectMake(15, yPosition, 40, 40)];
    checkBox.layer.cornerRadius = 5;
    checkBox.layer.borderWidth = 2;
    checkBox.layer.cornerRadius = 20;
    checkBox.layer.borderColor = [UIColor whiteColor].CGColor;
    checkBox.tag = tag;
    [checkBox addTarget:self
                 action:@selector(checkedBox:)
       forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:checkBox];
}

- (void)addLabelWithText:(NSString *)text andTag:(int)tag atYPosition:(int)yPosition {
    UIButton *labelButton = [[UIButton alloc] initWithFrame:CGRectMake(70, yPosition, self.view.frame.size.width - 15 - 70, 70)];
    labelButton.tag = tag;
    [labelButton addTarget:self action:@selector(pressedCheckBox:) forControlEvents:UIControlEventTouchUpInside];
    UILabel *labelText = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width - 15 - 70, 70)];
    labelText.text = text;
    labelText.textColor = [UIColor whiteColor];
    labelText.font = [FontProperties getSmallFont];
    labelText.textAlignment = NSTextAlignmentLeft;
    labelText.tag = tag + 1;
    labelText.numberOfLines = 0;
    labelText.lineBreakMode = NSLineBreakByWordWrapping;
    [labelButton addSubview:labelText];
    [self.view addSubview:labelButton];
}

- (void)pressedCheckBox:(id)sender {
    int tag = (int)((UIButton *)sender).tag;
    UIButton *checkedBoxSender = (UIButton *)[self.view viewWithTag:tag];
    [self checkedBox:checkedBoxSender];
}

- (void)checkedBox:(id)sender {
    UIButton *buttonSender = (UIButton *)sender;
    int tag = (int)buttonSender.tag;
    blockButton.tag = (tag + 1)/2 * 10; // 10 for the first button, 20 for the second, 30 for the third button
    for (int i = 1; i < 4; i++) {
        int index = 2*i - 1;
        if (index != tag) {
            UIButton *button = (UIButton *)[self.view viewWithTag:index];
            button.layer.borderColor = [UIColor whiteColor].CGColor;
            [[button subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
            UILabel *labelText =  (UILabel*)[self.view viewWithTag:(index + 1)];
            labelText.textColor = [UIColor whiteColor];
        }
    }
    buttonSender.layer.borderColor = [FontProperties getOrangeColor].CGColor;
    UIImageView *checkMarkImageView = [[UIImageView alloc] initWithFrame:CGRectMake(buttonSender.frame.size.width/2 - 10, buttonSender.frame.size.width/2 - 10, 20, 20)];
    checkMarkImageView.image = [UIImage imageNamed:@"checkmark"];
    [buttonSender addSubview:checkMarkImageView];
    
    UILabel *textLabel = (UILabel *)[self.view viewWithTag:(tag + 1)];
    textLabel.textColor = [FontProperties getOrangeColor];

}

@end

