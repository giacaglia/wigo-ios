//
//  MoreViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 7/28/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "MoreViewController.h"
#import "Globals.h"


UIButton *unfollowButton;
UIButton *blockButton;
UIButton *cancelButton;

@implementation MoreViewController

-(void) viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.clearColor;

    if (self.user.state == FRIEND_USER_STATE) {
        unfollowButton = [[UIButton alloc] initWithFrame:CGRectMake(35, self.view.frame.size.height - 60 - 2*54, self.view.frame.size.width - 70, 42)];
        unfollowButton.backgroundColor = RGB(246, 143, 30);
        [unfollowButton setTitle:@"UNFOLLOW" forState:UIControlStateNormal];
        [unfollowButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        unfollowButton.titleLabel.font = [FontProperties getTitleFont];
        unfollowButton.layer.borderWidth = 1;
        unfollowButton.layer.borderColor = [UIColor clearColor].CGColor;
        [unfollowButton addTarget:self action:@selector(unfollowPressed) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:unfollowButton];
    }
    
    blockButton = [[UIButton alloc] initWithFrame:CGRectMake(35, self.view.frame.size.height - 60 - 54, self.view.frame.size.width - 70, 42)];
    blockButton.backgroundColor = [UIColor redColor];
    [blockButton addTarget:self action:@selector(blockButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [blockButton setTitle:@"BLOCK/REPORT" forState:UIControlStateNormal];
    [blockButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    blockButton.titleLabel.font = [FontProperties getTitleFont];
    blockButton.layer.borderWidth = 0.5;
    blockButton.layer.borderColor = UIColor.clearColor.CGColor;
    [self.view addSubview:blockButton];

    cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(35, self.view.frame.size.height - 60, self.view.frame.size.width - 70, 42)];
    cancelButton.backgroundColor = UIColor.clearColor;
    [cancelButton addTarget:self action:@selector(cancelPressed) forControlEvents:UIControlEventTouchUpInside];
    [cancelButton setTitle:@"CANCEL" forState:UIControlStateNormal];
    [cancelButton setTitleColor:RGB(214, 45, 58) forState:UIControlStateNormal];
    cancelButton.titleLabel.font = [FontProperties getTitleFont];
    cancelButton.layer.borderColor = RGB(214, 45, 58).CGColor;
    cancelButton.layer.borderWidth = 0.5;
    [self.view addSubview:cancelButton];
}


-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    self.parentViewController.navigationController.navigationBar.alpha = 0.0f;
    self.navigationItem.titleView.tintColor = [FontProperties getOrangeColor];
    self.navigationController.navigationBar.backgroundColor = RGB(235, 235, 235);
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [FontProperties getOrangeColor], NSFontAttributeName:[FontProperties getTitleFont]};
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.view addSubview:self.bgView];
    [self.view sendSubviewToBack:self.bgView];
}

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.parentViewController.navigationController.navigationBar.alpha = 1.0f;
    [self.parentViewController.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                  forBarMetrics:UIBarMetricsDefault];
    self.parentViewController.navigationController.navigationBar.shadowImage = [UIImage new];
    self.parentViewController.navigationController.navigationBar.barTintColor = UIColor.clearColor;
}

-(void) goBack {
    [UIView animateWithDuration:0.15 animations:^{
        self.view.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [self.profileDelegate removeMoreVc];
    }];
}

-(void) unfollowPressed {
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
        if (unfollowButton) unfollowButton.alpha = 1.0f;
    } completion:^(BOOL finished){
        if (unfollowButton) unfollowButton.alpha = 0.0f;
        [self addOptions];
        UIButton *firstBox = (UIButton *)[self.view viewWithTag:1];
        [self checkedBox:firstBox];
    }];
}

- (void)cancelPressed {
    [self goBack];
}

- (void)addOptions {
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.view.bounds;
    gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor blackColor] CGColor], (id)[[UIColor clearColor] CGColor], nil];
    gradient.opacity = 0.5f;
    [self.view.layer insertSublayer:gradient atIndex:0];
    
    CAGradientLayer *newGradient = [CAGradientLayer layer];
    newGradient.frame = self.view.bounds;
    newGradient.colors = [NSArray arrayWithObjects:(id)[[UIColor clearColor] CGColor], (id)[[UIColor blackColor] CGColor], nil];
    newGradient.opacity = 0.5f;
    [self.view.layer insertSublayer:newGradient atIndex:0];
    
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

