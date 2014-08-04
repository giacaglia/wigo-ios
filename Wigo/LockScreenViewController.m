//
//  LockScreenUIViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 8/4/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "LockScreenViewController.h"
#import "Globals.h"
#import <Social/Social.h>
#import "UIImageViewShake.h"

SLComposeViewController *mySLComposerSheet;
NSNumber *numberOfPeopleSignedUp;

@implementation LockScreenViewController


- (id)init
{
    self = [super init];
    if (self) {
        self.view.backgroundColor = [UIColor whiteColor];
        self.navigationController.navigationBar.hidden = YES;
        self.navigationItem.hidesBackButton = YES;
//        [[self navigationController] setNavigationBarHidden:YES animated:NO];

        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    numberOfPeopleSignedUp = @0;
    [self fetchSummary];
    // Do any additional setup after loading the view.
    [self initializeTopLabel];
    [self initializeBottomLabel];
    [self initializeShareButton];
}


- (void)initializeTopLabel {
    UILabel *topLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 64 + 10, self.view.frame.size.width, 20)];
    topLabel.text = @"WiGo is better with friends.";
    [self setPropertiesofLabel:topLabel];
    [self.view addSubview:topLabel];
    
    UILabel *spreadLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 64 + 20, self.view.frame.size.width, 60)];
    spreadLabel.numberOfLines = 0;
    spreadLabel.lineBreakMode = NSLineBreakByWordWrapping;
    spreadLabel.text = [NSString stringWithFormat:@"Spread the word to unlock WiGo\n at %@!", [[Profile user] groupName]];
    [self setPropertiesofLabel:spreadLabel];
    [self.view addSubview:spreadLabel];
}

- (void)initializeLockPeopleButtons {
    CGSize origin = CGSizeMake(25, 150);
    for (int i = 1 ; i <= 100; i++) {
        if (i == 43) {
            UIButton *lockPersonIconButton = [[UIButton alloc] initWithFrame:CGRectMake(origin.width - 2, origin.height - 2, 15 + 4, 15 + 4)];
            UIImageViewShake *lockPersonIcon = [[UIImageViewShake alloc] initWithFrame:CGRectMake(0, 0, 15 + 4, 15 + 4)];
            [lockPersonIcon setImageWithURL:[NSURL URLWithString:[[Profile user] coverImageURL]]];
            lockPersonIcon.layer.borderWidth = 1;
            lockPersonIcon.layer.borderColor = [FontProperties getOrangeColor].CGColor;
            lockPersonIcon.layer.cornerRadius = 10;
            lockPersonIcon.layer.masksToBounds = YES;
            [lockPersonIconButton addTarget:self action:@selector(imagePressed:) forControlEvents:UIControlEventTouchDown | UIControlEventTouchDragExit];
            [lockPersonIconButton addSubview:lockPersonIcon];
            [self.view addSubview:lockPersonIconButton];
        }
        else {
            UIButton *lockPersonIconButton = [[UIButton alloc] initWithFrame:CGRectMake(origin.width, origin.height, 15 + 4, 15 + 4)];
            UIImageViewShake *lockPersonIcon = [[UIImageViewShake alloc] initWithFrame:CGRectMake(0, 0, 15, 15)];
            if (i < 43) lockPersonIcon.image = [UIImage imageNamed:@"lockPersonIcon"];
            else lockPersonIcon.image = [UIImage imageNamed:@"grayLockSelectedIcon"];
            [lockPersonIconButton addTarget:self action:@selector(imagePressed:) forControlEvents:UIControlEventTouchDown | UIControlEventTouchDragExit];
            [lockPersonIconButton addSubview:lockPersonIcon];
            [self.view addSubview:lockPersonIconButton];
        }
        if (i %10 == 0) origin = CGSizeMake(25, origin.height + 31);
        else origin = CGSizeMake(origin.width + 28, origin.height);
       
    }
}

- (void)initializeBottomLabel {
    UILabel *unlockLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, self.view.frame.size.height - 70 - 55, self.view.frame.size.width - 40, 65)];
    unlockLabel.numberOfLines = 0;
    unlockLabel.lineBreakMode = NSLineBreakByWordWrapping;
    unlockLabel.text = [NSString stringWithFormat:@"WiGo will unlock when %d more people from %@ sign up.", 100 - [numberOfPeopleSignedUp intValue] ,[Profile user].groupName];
    [self setPropertiesofLabel:unlockLabel];
    [self.view addSubview:unlockLabel];

}

- (void)initializeShareButton {
    UIButton *shareButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 125, self.view.frame.size.height - 60, 250, 48)];
    shareButton.backgroundColor = [FontProperties getOrangeColor];
    [shareButton setTitle:@"Share WiGo" forState:UIControlStateNormal];
    [shareButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    shareButton.titleLabel.font = [FontProperties getBigButtonFont];
    shareButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    shareButton.layer.borderColor = [UIColor whiteColor].CGColor;
    shareButton.layer.borderWidth = 1;
    shareButton.layer.cornerRadius = 5;
    [shareButton addTarget:self action:@selector(sharedPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:shareButton];
}

- (void) imagePressed:(id)sender {
    UIButton *buttonSender = (UIButton *)sender;
    for (UIView *subview in buttonSender.subviews)
    {
        if ([subview isMemberOfClass:[UIImageViewShake class]]) {
            UIImageViewShake *imageView = (UIImageViewShake *)subview;
            [imageView newShake];
        }
    }
}
- (void)sharedPressed {
    if([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook])
    {
        mySLComposerSheet = [[SLComposeViewController alloc] init];
        mySLComposerSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
        [mySLComposerSheet setInitialText:@"Want to know who is going out tonight at your school? http://blade.net/_wigo"];
        [mySLComposerSheet addImage:[UIImage imageNamed:@"wigoApp" ]]; //an image you could post
        [self presentViewController:mySLComposerSheet animated:YES completion:nil];
    }
}

#pragma mark - Helper functions

-(void)setPropertiesofLabel:(UILabel *)label {
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [FontProperties getSmallFont];
}

-(void)fetchSummary {
    [Network queryAsynchronousAPI:@"groups/summary" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            if ([[jsonResponse allKeys] containsObject:@"total"]) {
                numberOfPeopleSignedUp = (NSNumber *)[jsonResponse objectForKey:@"total"];
                [self initializeLockPeopleButtons];
            }
        });
    }];
}


@end
