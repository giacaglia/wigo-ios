//
//  WigoConfirmationViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 9/12/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "WigoConfirmationViewController.h"
#import "Globals.h"
#import "ContactsViewController.h"

@implementation WigoConfirmationViewController


- (id)init {
    self = [super init];
    if (self) {
        self.view.backgroundColor = RGB(250, 250, 250);
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [self initializeTitle];

}

- (void) initializeTitle {
    UIImageView *wigoIconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 70 , 75, 140, 140)];
    wigoIconImageView.image = [UIImage imageNamed:@"iconFlashScreen"];
    [self.view addSubview:wigoIconImageView];
    
    UILabel *wigoLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 230, self.view.frame.size.width - 40, 60)];
    wigoLabel.text = @"WiGo is better with friends";
    wigoLabel.textAlignment = NSTextAlignmentCenter;
    wigoLabel.font = [FontProperties mediumFont:23.0f];
    [self.view addSubview:wigoLabel];
    
    UIImageView *evenMoreImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 145, 220 , 62, 31)];
    evenMoreImageView.image = [UIImage imageNamed:@"evenMore"];
    [self.view addSubview:evenMoreImageView];
    
    UILabel *tapFriendsLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 280, self.view.frame.size.width - 20, 50)];
    tapFriendsLabel.text = @"Tap some friends from your contacts \n to get them going on WiGo";
    tapFriendsLabel.textAlignment = NSTextAlignmentCenter;
    tapFriendsLabel.font = [FontProperties mediumFont:18.0f];
    tapFriendsLabel.textColor = RGB(100, 100, 100);
    tapFriendsLabel.numberOfLines = 0;
    tapFriendsLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [self.view addSubview:tapFriendsLabel];
    
    UIButton *allowButton = [[UIButton alloc] initWithFrame:CGRectMake(20, 400, self.view.frame.size.width - 40, 70)];
    allowButton.backgroundColor = [FontProperties getOrangeColor];
    [allowButton setTitle:@"Allow one time access\n to contacts" forState:UIControlStateNormal];
    [allowButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    allowButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    allowButton.titleLabel.font = [FontProperties scMediumFont:20.0f];
    allowButton.titleLabel.numberOfLines = 0;
    allowButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    allowButton.layer.cornerRadius = 14.0f;
    allowButton.layer.borderColor = [UIColor clearColor].CGColor;
    allowButton.layer.borderWidth = 1;
    [allowButton addTarget:self action:@selector(giveOneTimeAccess) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:allowButton];
 
    UIButton *notRightNowButton = [[UIButton alloc] initWithFrame:CGRectMake(30, 480, self.view.frame.size.width - 60, 20)];
    [notRightNowButton setTitle:@"NOT RIGHT NOW" forState:UIControlStateNormal];
    [notRightNowButton setTitleColor:RGB(185, 185, 185) forState:UIControlStateNormal];
    notRightNowButton.titleLabel.font = [FontProperties scMediumFont:10];
    [notRightNowButton addTarget:self action:@selector(notRightNowPressed) forControlEvents:UIControlEventTouchUpInside];
//    NSMutableAttributedString * string = [[NSMutableAttributedString alloc] initWithString:@"NOT RIGHT NOW"];
//    NSDictionary *attrs = @{ NSFontAttributeName : [FontProperties scMediumFont:12],
//                             NSForegroundColorAttributeName : RGB(185, 185, 185),
//                             NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle) };
//    [string addAttributes:attrs range:NSRangeFromString(string.string)];
//    notRightNowButton.titleLabel.attributedText = [[NSAttributedString alloc] initWithAttributedString:string];
    [self.view addSubview:notRightNowButton];
}

- (void)giveOneTimeAccess {
//    NSLog(@"here");
    [self.navigationController pushViewController:[ContactsViewController new] animated:YES];
//    [self presentViewController:[ContactsViewController new] animated:yes completion:^{}];
}

- (void)notRightNowPressed {
//    NSLog(@"here");
//    [self.navigationController dismissViewControllerAnimated:YES completion:^{}];
}



@end
