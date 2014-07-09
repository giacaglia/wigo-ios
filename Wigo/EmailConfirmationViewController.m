//
//  EmailConfirmationViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/28/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "EmailConfirmationViewController.h"
#import "FontProperties.h"
#import "Profile.h"
#import "SDWebImage/UIImageView+WebCache.h"

@implementation EmailConfirmationViewController

- (id)init
{
    self = [super init];
    if (self) {
        self.view.backgroundColor = [UIColor whiteColor];
        self.navigationController.navigationBar.hidden = YES;
        self.navigationItem.hidesBackButton = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(login) name:UIApplicationWillEnterForegroundNotification object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self initializeEmailConfirmationLabel];
    [self initializeFaceAndNameLabel];
    [self initializeEmailLabel];
    [self initializeNumberOfPeopleLabel];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"fheahre");
    [self login];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSLog(@"Called here");
}

- (void) initializeEmailConfirmationLabel {
    UILabel *emailConfirmationLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 37, self.view.frame.size.width, 28)];
    emailConfirmationLabel.text = @"EMAIL CONFIRMATION";
    emailConfirmationLabel.textColor = [FontProperties getOrangeColor];
    emailConfirmationLabel.font = [FontProperties getTitleFont];
    emailConfirmationLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:emailConfirmationLabel];
}

- (void)initializeFaceAndNameLabel {
    UIView *faceAndNameView = [[UIView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, 68)];
    faceAndNameView.backgroundColor = [FontProperties getLightOrangeColor];
    
    UIImageView *faceImageView = [[UIImageView alloc] init];
    [faceImageView setImageWithURL:[NSURL URLWithString:[[[Profile user] imagesURL] objectAtIndex:0]]];
    faceImageView.frame = CGRectMake(15, 10, 47, 47);
    faceImageView.layer.cornerRadius = 3;
    faceImageView.layer.borderWidth = 1;
    faceImageView.backgroundColor = [UIColor whiteColor];
    faceImageView.layer.masksToBounds = YES;
    [faceAndNameView addSubview:faceImageView];
    
    UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(75, 24, 200, 22)];
    nameLabel.textAlignment = NSTextAlignmentLeft;
    nameLabel.text = [[Profile user] fullName];
    nameLabel.font = [FontProperties getSmallFont];
    [faceAndNameView addSubview:nameLabel];
    
    [self.view addSubview:faceAndNameView];
}

- (void) initializeEmailLabel {
    UILabel *openLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 225, self.view.frame.size.width, 30)];
    openLabel.textAlignment = NSTextAlignmentCenter;
    openLabel.text = @"Please open the link in the email";
    openLabel.font = [FontProperties getSmallFont];
    [self.view addSubview:openLabel];
    
    UILabel *justSentLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 255, self.view.frame.size.width, 30)];
    justSentLabel.textAlignment = NSTextAlignmentCenter;
    justSentLabel.text = @"that we just sent to";
    justSentLabel.font = [FontProperties getSmallFont];
    [self.view addSubview:justSentLabel];
    
    UILabel *emailLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 285, self.view.frame.size.width, 30)];
    emailLabel.textAlignment = NSTextAlignmentCenter;
    emailLabel.text = [[Profile user] email];
    emailLabel.font = [FontProperties getSmallFont];
    emailLabel.textColor = [FontProperties getOrangeColor];
    [self.view addSubview:emailLabel];

    UILabel *holyCrossLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 430, self.view.frame.size.width, 30)];
    holyCrossLabel.textAlignment = NSTextAlignmentCenter;
    holyCrossLabel.text = @"@ Holy Cross";
    holyCrossLabel.font = [FontProperties getSmallFont];
    holyCrossLabel.textColor = [UIColor grayColor];
    [self.view addSubview:holyCrossLabel];
}

- (void) initializeNumberOfPeopleLabel {
    UILabel *numberOfPeopleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 100, self.view.frame.size.width, 50)];
    numberOfPeopleLabel.text = @"17 students are going out";
    numberOfPeopleLabel.font = [FontProperties getSmallFont];
    numberOfPeopleLabel.backgroundColor = [FontProperties getLightOrangeColor];
    numberOfPeopleLabel.textColor = [UIColor blackColor];
    numberOfPeopleLabel.textAlignment = NSTextAlignmentCenter;
    NSMutableAttributedString *text =
    [[NSMutableAttributedString alloc]
     initWithAttributedString: numberOfPeopleLabel.attributedText];
    [text addAttribute:NSForegroundColorAttributeName
                 value:[FontProperties getOrangeColor]
                 range:NSMakeRange(0, 2)];
    [numberOfPeopleLabel setAttributedText: text];
    [self.view addSubview:numberOfPeopleLabel];
    
    
    UILabel *lastWeekLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 50, self.view.frame.size.width, 50)];
    lastWeekLabel.text = @"253 students are going out";
    lastWeekLabel.font = [FontProperties getSmallFont];
    lastWeekLabel.backgroundColor = [FontProperties getLightOrangeColor];
    lastWeekLabel.textColor = [UIColor blackColor];
    lastWeekLabel.textAlignment = NSTextAlignmentCenter;
    
    NSMutableAttributedString *textWeekLabel =
    [[NSMutableAttributedString alloc]
     initWithAttributedString: lastWeekLabel.attributedText];
    [textWeekLabel addAttribute:NSForegroundColorAttributeName
                 value:[FontProperties getOrangeColor]
                 range:NSMakeRange(0, 3)];
    [lastWeekLabel setAttributedText: textWeekLabel];
    [self.view addSubview:lastWeekLabel];
}

#pragma mark - Login

- (void) login {
    User *userProfile = [Profile user];
    NSString *response = [userProfile login];
    [Profile setUser:userProfile];
    
    if ([response isEqualToString:@"error"] || [response isEqualToString:@"email_not_validated"]) {
    }
    else {
        [self dismissViewControllerAnimated:YES  completion:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"loadViewAfterSigningUser" object:self];
    }
}

@end
