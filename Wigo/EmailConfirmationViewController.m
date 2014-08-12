//
//  EmailConfirmationViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/28/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "EmailConfirmationViewController.h"
#import "Globals.h"
#import "OnboardFollowViewController.h"

UITextField *emailTextField;
OnboardFollowViewController *onboardFollowViewController;

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
    [self initializeOtherButtons];
//    [self initializeNumberOfPeopleLabel];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [EventAnalytics tagEvent:@"Email Confirmation View"];
    [self login];
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
    
    UIImageView *faceImageView = [[UIImageView alloc] initWithFrame:CGRectMake(15, 10, 47, 47)];
    faceImageView.contentMode = UIViewContentModeScaleAspectFill;
    faceImageView.clipsToBounds = YES;
    [faceImageView setImageWithURL:[NSURL URLWithString:[[Profile user] coverImageURL]]];
    faceImageView.layer.cornerRadius = 3;
    faceImageView.layer.borderWidth = 1;
    faceImageView.layer.borderColor = [UIColor clearColor].CGColor;
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
    
    emailTextField = [[UITextField alloc] initWithFrame:CGRectMake(40, 285, self.view.frame.size.width - 80, 30)];
    emailTextField.textAlignment = NSTextAlignmentCenter;
    emailTextField.text = [[Profile user] email];
    emailTextField.font = [FontProperties getSmallFont];
    emailTextField.textColor = [FontProperties getOrangeColor];
    emailTextField.enabled = NO;
    emailTextField.layer.borderColor = [UIColor clearColor].CGColor;
    emailTextField.layer.borderWidth = 1;
    emailTextField.layer.cornerRadius = 5;
    emailTextField.tintColor = [FontProperties getOrangeColor];
    emailTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    emailTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    emailTextField.delegate = self;
    [self.view addSubview:emailTextField];

//    UILabel *holyCrossLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 430, self.view.frame.size.width, 30)];
//    holyCrossLabel.textAlignment = NSTextAlignmentCenter;
//    holyCrossLabel.text = @"@ Holy Cross";
//    holyCrossLabel.font = [FontProperties getSmallFont];
//    holyCrossLabel.textColor = [UIColor grayColor];
//    [self.view addSubview:holyCrossLabel];
}

- (void)initializeOtherButtons {
    UIButton *resendButton = [[UIButton alloc] init];
    resendButton.frame = CGRectMake(22, 350, self.view.frame.size.width*0.4, 47);
    resendButton.backgroundColor = RGBAlpha(246, 143, 30, 0.3f);
    [resendButton setTitle:@"Resend" forState:UIControlStateNormal];
    [resendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    resendButton.layer.borderColor = [UIColor whiteColor].CGColor;
    resendButton.layer.borderWidth = 3;
    resendButton.layer.cornerRadius = 5;
    [resendButton addTarget:self action:@selector(resendEmail) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:resendButton];

    
    UIButton *changeButton = [[UIButton alloc] init];
    changeButton.frame = CGRectMake(22 + self.view.frame.size.width*0.4 + 20, 350, self.view.frame.size.width*0.4, 47);
    changeButton.backgroundColor = RGBAlpha(246, 143, 30, 0.3f);
    [changeButton setTitle:@"Change Email" forState:UIControlStateNormal];
    [changeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    changeButton.layer.borderColor = [UIColor whiteColor].CGColor;
    changeButton.layer.borderWidth = 3;
    changeButton.layer.cornerRadius = 5;
    [changeButton addTarget:self action:@selector(changeEmailPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:changeButton];
}

- (void) initializeNumberOfPeopleLabel {
    self.numberOfPeopleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 50, self.view.frame.size.width, 50)];
    self.numberOfPeopleLabel.hidden = YES;
    self.numberOfPeopleLabel.font = [FontProperties getSmallFont];
    self.numberOfPeopleLabel.backgroundColor = [FontProperties getLightOrangeColor];
    self.numberOfPeopleLabel.textColor = [UIColor blackColor];
    self.numberOfPeopleLabel.textAlignment = NSTextAlignmentCenter;
    NSMutableAttributedString *text =
    [[NSMutableAttributedString alloc]
     initWithAttributedString: self.numberOfPeopleLabel.attributedText];
    [text addAttribute:NSForegroundColorAttributeName
                 value:[FontProperties getOrangeColor]
                 range:NSMakeRange(0, 2)];
    [self.numberOfPeopleLabel setAttributedText:text];
    [self.view addSubview:self.numberOfPeopleLabel];
}

#pragma mark - Login

- (void) login {
    User *userProfile = [Profile user];
    NSString *response = [userProfile login];
    [Profile setUser:userProfile];
    
    if ([response isEqualToString:@"error"] || [response isEqualToString:@"email_not_validated"]) {
    }
    else {
        if ([[Profile user] isGroupLocked]) {
            self.lockScreenViewController = [[LockScreenViewController alloc] init];
            [self.navigationController pushViewController:self.lockScreenViewController animated:NO];
        }
        else {
//            [self dismissViewControllerAnimated:YES  completion:nil];
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"loadViewAfterSigningUser" object:self];
            onboardFollowViewController = [OnboardFollowViewController new];
            [self.navigationController pushViewController:onboardFollowViewController animated:YES];
        }
    }
}

- (void)resendEmail {
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    [WiGoSpinnerView addDancingGToCenterView:self.view];
    [Network sendAsynchronousHTTPMethod:GET
                            withAPIName:@"verification/resend"
                            withHandler:^(NSDictionary *jsonResponse, NSError *error) {
                                dispatch_async(dispatch_get_main_queue(), ^(void){
                                    [WiGoSpinnerView removeDancingGFromCenterView:self.view];
                                    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
                                    if (!error) {
                                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Resent"
                                                                                            message:@"We just resent you a new email."
                                                                                           delegate:nil
                                                                                  cancelButtonTitle:@"OK"
                                                                                  otherButtonTitles:nil];
                                        [alertView show];
                                    }
                                });
    }];
}

- (void)changeEmailPressed {
    emailTextField.layer.borderColor = [FontProperties getOrangeColor].CGColor;
    emailTextField.enabled = YES;
    [emailTextField becomeFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    emailTextField.layer.borderColor = [UIColor clearColor].CGColor;
    emailTextField.enabled = NO;
    [textField resignFirstResponder];
    [self changeEmail:textField.text];
    return YES;
}

- (void)changeEmail:(NSString *)emailString {
    User *profileUser = [Profile user];
    [profileUser setEmail:emailString];
    [profileUser saveKeyAsynchronously:@"email"];
}




@end
