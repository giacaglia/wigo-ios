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
#import "OnboardFollowViewController.h"

@interface LockScreenViewController ()
@property Party *everyoneParty;
@end

SLComposeViewController *mySLComposerSheet;
NSNumber *numberOfPeopleSignedUp;
NSMutableArray *alreadyGeneratedNumbers;
BOOL pushed;
OnboardFollowViewController *onboardFollowViewController;

@implementation LockScreenViewController


- (id)init
{
    self = [super init];
    if (self) {
        self.view.backgroundColor = [UIColor whiteColor];
        self.navigationController.navigationBar.hidden = YES;
        self.navigationItem.hidesBackButton = YES;
        [self.navigationController setNavigationBarHidden: YES animated:YES];
        pushed = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    numberOfPeopleSignedUp = [[Profile user] numberOfGroupMembers];
    _everyoneParty = [[Party alloc] initWithObjectType:USER_TYPE];
    alreadyGeneratedNumbers = [[NSMutableArray alloc] init];
    [self initializeTopLabel];
    [self initializeShareButton];
    [self initializeLockPeopleButtons];
    if (isiPhone5) [self initializeBottomLabel];
    [self fetchEveryone];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self fetchUserInfo];
    [EventAnalytics tagEvent:@"Lock Screen View"];
}

- (void)dismissIfGroupUnlocked {
    if (![[Profile user] isGroupLocked] && !pushed) {
//        onboardFollowViewController = [OnboardFollowViewController new];
//        [self.navigationController pushViewController:onboardFollowViewController animated:YES];
    }
}


- (void)initializeTopLabel {
    UILabel *topLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 30, self.view.frame.size.width, 20)];
    topLabel.text = @"WiGo is better with friends.";
    [self setPropertiesofLabel:topLabel];
    [self.view addSubview:topLabel];
    
    UILabel *spreadLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 40, self.view.frame.size.width, 60)];
    spreadLabel.numberOfLines = 0;
    spreadLabel.lineBreakMode = NSLineBreakByWordWrapping;
    spreadLabel.text = [NSString stringWithFormat:@"Spread the word to unlock WiGo\n at %@!", [[Profile user] groupName]];
    [self setPropertiesofLabel:spreadLabel];
    [self.view addSubview:spreadLabel];
}

- (void)initializeLockPeopleButtons {
    CGSize origin = CGSizeMake(25, 110);
    for (int i = 1 ; i <= 100; i++) {
        if (i == [numberOfPeopleSignedUp intValue]) {
            UIButton *lockPersonIconButton = [[UIButton alloc] initWithFrame:CGRectMake(origin.width - 10, origin.height - 10, 15 + 20, 15 + 20)];
            UIImageViewShake *lockPersonImageView = [[UIImageViewShake alloc] initWithFrame:CGRectMake(0, 0, 15 + 20, 15 + 20)];
            lockPersonImageView.tag = i;
            [lockPersonImageView setImageWithURL:[NSURL URLWithString:[[Profile user] coverImageURL]]];
            lockPersonImageView.layer.borderWidth = 1;
            lockPersonImageView.layer.borderColor = [FontProperties getOrangeColor].CGColor;
            lockPersonImageView.layer.cornerRadius = 17;
            lockPersonImageView.layer.masksToBounds = YES;
            lockPersonImageView.contentMode = UIViewContentModeScaleAspectFill;
            lockPersonImageView.clipsToBounds = YES;
            [lockPersonIconButton addSubview:lockPersonImageView];
            [self.view addSubview:lockPersonIconButton];
        }
        else {
            UIButton *lockPersonIconButton = [[UIButton alloc] initWithFrame:CGRectMake(origin.width, origin.height, 15 + 4, 15 + 4)];
            UIImageViewShake *lockPersonImageView = [[UIImageViewShake alloc] initWithFrame:CGRectMake(0, 0, 15, 15)];
            lockPersonImageView.tag = i;
            if (i < [numberOfPeopleSignedUp intValue]) lockPersonImageView.image = [UIImage imageNamed:@"lockPersonIcon"];
            else lockPersonImageView.image = [UIImage imageNamed:@"grayLockSelectedIcon"];
            [lockPersonIconButton addSubview:lockPersonImageView];
            [self.view addSubview:lockPersonIconButton];
        }
        if (i %10 == 0) origin = CGSizeMake(25, origin.height + 31);
        else origin = CGSizeMake(origin.width + 28, origin.height);
       
    }
}

- (void)initializeBottomLabel {
    UILabel *unlockLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, self.view.frame.size.height - 145, self.view.frame.size.width - 40, 65)];
    unlockLabel.numberOfLines = 0;
    unlockLabel.lineBreakMode = NSLineBreakByWordWrapping;
    unlockLabel.text = [NSString stringWithFormat:@"WiGo will unlock when %d more people from %@ sign up.", 100 - [numberOfPeopleSignedUp intValue] ,[Profile user].groupName];
    [self setPropertiesofLabel:unlockLabel];
    [self.view addSubview:unlockLabel];

}

- (void)initializeShareButton {
    UIButton *shareButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 125, self.view.frame.size.height - 65, 250, 48)];
    shareButton.backgroundColor = [FontProperties getOrangeColor];
    [shareButton setTitle:@"Share WiGo" forState:UIControlStateNormal];
    [shareButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    shareButton.titleLabel.font = [FontProperties getBigButtonFont];
    shareButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    shareButton.layer.borderColor = [UIColor whiteColor].CGColor;
    shareButton.layer.borderWidth = 1;
    shareButton.layer.cornerRadius = 15;
    [shareButton addTarget:self action:@selector(sharedPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:shareButton];
}

- (void) imagePressed:(id)sender {
    UIButton *buttonSender = (UIButton *)sender;
    for (UIView *subview in buttonSender.subviews)
    {
        if ([subview isMemberOfClass:[UIImageViewShake class]]) {
            UIImageViewShake *imageView = (UIImageViewShake *)subview;
            int i = imageView.tag - 1;
            int numberOfPeopleInParty = [[_everyoneParty getObjectArray] count];
            if (i < numberOfPeopleInParty) {
                if (numberOfPeopleInParty != 0 && numberOfPeopleSignedUp > 0 && [_everyoneParty getObjectArray]) {
                    User *user = [[_everyoneParty getObjectArray] objectAtIndex:i];
                    [imageView setImageWithURL:[NSURL URLWithString:[user coverImageURL]]];
                    imageView.backgroundColor = [FontProperties getOrangeColor];
                    imageView.layer.borderWidth = 1;
                    imageView.layer.borderColor = [FontProperties getOrangeColor].CGColor;
                    imageView.layer.cornerRadius = 7;
                    imageView.layer.masksToBounds = YES;
                }
            }
            [imageView newShake];
        }
    }
}
- (void)sharedPressed {
    NSArray *activityItems = @[@"Who is going out tonight? #WiGo http://wigo.us/app",[UIImage imageNamed:@"wigoApp" ]];
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    activityVC.excludedActivityTypes = @[UIActivityTypeCopyToPasteboard, UIActivityTypePrint, UIActivityTypeAssignToContact, UIActivityTypeAirDrop, UIActivityTypeSaveToCameraRoll];
    [self presentViewController:activityVC animated:YES completion:nil];
}

#pragma mark - Helper functions

-(void)setPropertiesofLabel:(UILabel *)label {
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [FontProperties getSmallFont];
}

- (void)fetchEveryone {
    _everyoneParty = [[Party alloc] initWithObjectType:USER_TYPE];
    NSString *queryString = [NSString stringWithFormat:@"users/?limit=%@",numberOfPeopleSignedUp];
    [Network queryAsynchronousAPI:queryString withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
        }
        else {
            NSArray *arrayOfUsers = [jsonResponse objectForKey:@"objects"];
            [_everyoneParty addObjectsFromArray:arrayOfUsers];
            [_everyoneParty removeUser:[Profile user]];
            [self initializeRandomArray];
        }
    }];
}


- (void) fetchUserInfo {
    [Network queryAsynchronousAPI:@"users/me" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        User *user = [[User alloc] initWithDictionary:jsonResponse];
        [Profile setUser:user];
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self dismissIfGroupUnlocked];
        });
    }];
}

- (int)generateRandomNumber:(int)TOTAL_NUMBER{
    int low_bound = 1;
    int high_bound = TOTAL_NUMBER;
    int width = high_bound - low_bound;
    int randomNumber = low_bound + arc4random() % width;
    
    return randomNumber;
}


- (void)initializeRandomArray
{
    int TOTAL_NUMBER = (int)[[_everyoneParty getObjectArray] count];
    while ([alreadyGeneratedNumbers count] < TOTAL_NUMBER) {
        NSNumber *generatedNumber = [NSNumber numberWithInt:[self generateRandomNumber:TOTAL_NUMBER]];
        if (![alreadyGeneratedNumbers containsObject:generatedNumber]) {
            [alreadyGeneratedNumbers addObject:generatedNumber];
        }
    }    
}

#pragma mark - Delegate Function 
- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UIView* view = [self.view hitTest: [[touches anyObject] locationInView: self.view] withEvent: nil];
	if (view != nil && view != self.view ) {
        [self imagePressed:view];
	}
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UIView* view = [self.view hitTest: [[touches anyObject] locationInView: self.view] withEvent: nil];
	if (view != nil && view != self.view) {
        [self imagePressed:view];
	}
}

@end
