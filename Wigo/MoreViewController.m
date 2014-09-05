//
//  MoreViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 7/28/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "MoreViewController.h"
#import "Globals.h"
#import "RWBlurPopover.h"


BOOL once;
User *user;
STATE state;
UIButton *unfollowButton;
UIButton *blockButton;
UIButton *cancelButton;

@implementation MoreViewController

- (id)initWithState:(STATE)newState
{
    self = [super init];
    if (self) {
        state = newState;
    }
    return self;
}

- (id)initWithUser:(User *)newUser {
    self = [super init];
    if (self) {
        user = newUser;
        state = [user getUserState];
    }
    return self;
}

- (id)init
{
    self = [super init];
    return self;
}

- (void)viewDidLoad
{
    once = YES;
    [super viewDidLoad];
    
    if (state == FOLLOWING_USER ||
        state == ACCEPTED_PRIVATE_USER ||
        state == ATTENDING_EVENT_FOLLOWING_USER ||
        state == ATTENDING_EVENT_ACCEPTED_PRIVATE_USER) {
        unfollowButton = [[UIButton alloc] initWithFrame:CGRectMake(35, 100 + 248 + 50, 248, 42)];
        unfollowButton.backgroundColor = RGB(246, 143, 30);
        [unfollowButton setTitle:@"UNFOLLOW" forState:UIControlStateNormal];
        [unfollowButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        unfollowButton.titleLabel.font = [FontProperties getTitleFont];
        unfollowButton.layer.borderWidth = 1;
//        unfollowButton.layer.cornerRadius = 12;
        unfollowButton.layer.borderColor = [UIColor clearColor].CGColor;
        [unfollowButton addTarget:self action:@selector(unfollowPressed) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:unfollowButton];
    }
    
    blockButton = [[UIButton alloc] initWithFrame:CGRectMake(35, 100 + 248 + 50 + 42 + 12, 248, 42)];
    blockButton.backgroundColor = [UIColor redColor];
    [blockButton addTarget:self action:@selector(blockButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [blockButton setTitle:@"BLOCK OR REPORT" forState:UIControlStateNormal];
    [blockButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    blockButton.titleLabel.font = [FontProperties getTitleFont];
    blockButton.layer.borderWidth = 0.5;
//    blockButton.layer.cornerRadius = 12;
    blockButton.layer.borderColor = [UIColor clearColor].CGColor;
    [self.view addSubview:blockButton];

    cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(35, 100 + 248 + 50 + 42 + 12 + 42 + 12, 248, 42)];
    cancelButton.backgroundColor = [UIColor whiteColor];
    [cancelButton addTarget:self action:@selector(cancelPressed) forControlEvents:UIControlEventTouchUpInside];
    [cancelButton setTitle:@"CANCEL" forState:UIControlStateNormal];
    [cancelButton setTitleColor:RGB(214, 45, 58) forState:UIControlStateNormal];
    cancelButton.titleLabel.font = [FontProperties getTitleFont];
    cancelButton.layer.borderColor = RGB(214, 45, 58).CGColor;
    cancelButton.layer.borderWidth = 0.5;
//    cancelButton.layer.cornerRadius = 12;
    [self.view addSubview:cancelButton];
}


- (void)unfollowPressed {
    if (once) {
        once = NO;
        [[RWBlurPopover instance] dismissViewControllerAnimated:YES completion:^(void){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"unfollowPressed" object:nil];

        }];
    }
}

- (void)submitBlockPressed {
    if (once) {
        once = NO;
        [[RWBlurPopover instance] dismissViewControllerAnimated:YES completion:^(void) {
            int type = (blockButton.tag / 10)  - 1;
            NSDictionary *userInfo = @{@"user": [user dictionary], @"type":[NSNumber numberWithInt:type]};
            [[NSNotificationCenter defaultCenter] postNotificationName:@"blockPressed" object:nil userInfo:userInfo];
        }];
    }
}

- (void)blockButtonPressed {
    [UIView animateWithDuration:1 animations:^(void) {
        if (unfollowButton) unfollowButton.alpha = 1.0f;
        
    } completion:^(BOOL finished){
        if (unfollowButton) unfollowButton.alpha = 0.0f;
        [self addOptions];
        UIButton *firstBox = (UIButton *)[self.view viewWithTag:1];
        [self checkedBox:firstBox];
    }];
}

- (void)cancelPressed {
    if (once) {
        once = NO;
        [[RWBlurPopover instance] dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)addOptions {
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.view.bounds;
    gradient.colors = [NSArray arrayWithObjects:(id)[RGBAlpha(0, 0, 0, 0.3) CGColor], (id)[[UIColor clearColor] CGColor], nil];
    [self.view.layer insertSublayer:gradient atIndex:0];
    
    UILabel *blockLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 20, self.view.frame.size.width - 30, 60)];
    blockLabel.text = [NSString stringWithFormat:@"Block %@", [user fullName]];
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
    [self addCheckBoxWithTag:1 atYPosition:150];
    [self addLabelWithText:[NSString stringWithFormat:@"%@ is just annoying to me.", [user firstName]]
                    andTag:1
               atYPosition:150 - 15];
    
    [self addCheckBoxWithTag:3 atYPosition:220];
    [self addLabelWithText:[NSString stringWithFormat:@"%@ is not a student at my school.", [user firstName]]
                    andTag:3
               atYPosition:220 - 15];
    
 
    [self addCheckBoxWithTag:5 atYPosition:290];
    [self addLabelWithText:[NSString stringWithFormat:@"%@ is abusive and should be banned for all users", [user firstName]] andTag:5
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
    int tag = ((UIButton *)sender).tag;
    UIButton *checkedBoxSender = (UIButton *)[self.view viewWithTag:tag];
    [self checkedBox:checkedBoxSender];
}

- (void)checkedBox:(id)sender {
    UIButton *buttonSender = (UIButton *)sender;
    int tag = buttonSender.tag;
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

