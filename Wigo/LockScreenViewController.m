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
Party *everyoneParty;
NSMutableArray *alreadyGeneratedNumbers;
BOOL pushed;

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
    everyoneParty = [[Party alloc] initWithObjectType:USER_TYPE];
    alreadyGeneratedNumbers = [[NSMutableArray alloc] init];
    [self initializeTopLabel];
    [self initializeShareButton];
    [self initializeLockPeopleButtons];
    [self initializeBottomLabel];
    [self fetchEveryone];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self fetchUserInfo];
}

- (void)dismissIfGroupUnlocked {
    if (![[Profile user] isGroupLocked] && !pushed) {
        [self dismissViewControllerAnimated:YES completion:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"loadViewAfterSigningUser" object:self];
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
    CGSize origin = CGSizeMake(25, 120);
    for (int i = 1 ; i <= 100; i++) {
        if (i == [numberOfPeopleSignedUp intValue]) {
            UIButton *lockPersonIconButton = [[UIButton alloc] initWithFrame:CGRectMake(origin.width - 10, origin.height - 10, 15 + 20, 15 + 20)];
            UIImageViewShake *lockPersonIcon = [[UIImageViewShake alloc] initWithFrame:CGRectMake(0, 0, 15 + 20, 15 + 20)];
            lockPersonIcon.tag = i;
            [lockPersonIcon setImageWithURL:[NSURL URLWithString:[[Profile user] coverImageURL]]];
            lockPersonIcon.layer.borderWidth = 1;
            lockPersonIcon.layer.borderColor = [FontProperties getOrangeColor].CGColor;
            lockPersonIcon.layer.cornerRadius = 17;
            lockPersonIcon.layer.masksToBounds = YES;
            [lockPersonIconButton addSubview:lockPersonIcon];
            [self.view addSubview:lockPersonIconButton];
        }
        else {
            UIButton *lockPersonIconButton = [[UIButton alloc] initWithFrame:CGRectMake(origin.width, origin.height, 15 + 4, 15 + 4)];
            UIImageViewShake *lockPersonIcon = [[UIImageViewShake alloc] initWithFrame:CGRectMake(0, 0, 15, 15)];
            lockPersonIcon.tag = i;
            if (i < [numberOfPeopleSignedUp intValue]) lockPersonIcon.image = [UIImage imageNamed:@"lockPersonIcon"];
            else lockPersonIcon.image = [UIImage imageNamed:@"grayLockSelectedIcon"];
            [lockPersonIconButton addSubview:lockPersonIcon];
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
    UIButton *shareButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 125, self.view.frame.size.height - 70, 250, 48)];
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
            if (imageView.tag < [numberOfPeopleSignedUp intValue]) {
                if ([[everyoneParty getObjectArray] count] != 0) {
                    int TOTAL_NUMBER = [[everyoneParty getObjectArray] count];
                    User *user = [[everyoneParty getObjectArray] objectAtIndex:[self generateRandomNumber:TOTAL_NUMBER]];
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

- (void)fetchEveryone {
    [Network queryAsynchronousAPI:@"users/" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (error) {
        }
        else {
            NSArray *arrayOfUsers = [jsonResponse objectForKey:@"objects"];
            [everyoneParty addObjectsFromArray:arrayOfUsers];
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


- (void)randomNumbers
{
    int TOTAL_NUMBER = [[everyoneParty getObjectArray] count] - 1;

    NSMutableArray *shuffle = [[NSMutableArray alloc] initWithCapacity:5];
    
    BOOL contains = YES;
    while ([shuffle count] < 5) {
        NSNumber *generatedNumber=[NSNumber numberWithInt:[self generateRandomNumber:TOTAL_NUMBER]];
        if (![alreadyGeneratedNumbers containsObject:generatedNumber]) {
            [shuffle addObject:generatedNumber];
            contains=NO;
            [alreadyGeneratedNumbers addObject:generatedNumber];
        }
    }
    
    if ([alreadyGeneratedNumbers count] >= TOTAL_NUMBER) {
        [alreadyGeneratedNumbers removeAllObjects];
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
