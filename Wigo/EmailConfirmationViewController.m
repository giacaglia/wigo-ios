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
#import "BatteryViewController.h"

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
    [WGAnalytics tagEvent:@"Email Confirmation View"];
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
    [faceImageView setImageWithURL:[WGProfile currentUser].smallCoverImageURL imageArea:[WGProfile currentUser].smallCoverImageArea];
    faceImageView.layer.cornerRadius = 3;
    faceImageView.layer.borderWidth = 1;
    faceImageView.layer.borderColor = [UIColor clearColor].CGColor;
    faceImageView.backgroundColor = [UIColor whiteColor];
    faceImageView.layer.masksToBounds = YES;
    [faceAndNameView addSubview:faceImageView];
    
    UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(75, 24, 200, 22)];
    nameLabel.textAlignment = NSTextAlignmentLeft;
    nameLabel.text = [[WGProfile currentUser] fullName];
    nameLabel.font = [FontProperties getSmallFont];
    [faceAndNameView addSubview:nameLabel];
    
    [self.view addSubview:faceAndNameView];
}

- (void) initializeEmailLabel {
    UILabel *openLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 225, self.view.frame.size.width, 30)];
    openLabel.textAlignment = NSTextAlignmentCenter;
    openLabel.text = @"Please open the link in the email";
    openLabel.font = [FontProperties lightFont:22.0f];
    [self.view addSubview:openLabel];
    
    UILabel *justSentLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 255, self.view.frame.size.width, 30)];
    justSentLabel.textAlignment = NSTextAlignmentCenter;
    justSentLabel.text = @"that we just sent to";
    justSentLabel.font = [FontProperties lightFont:22.0f];
    [self.view addSubview:justSentLabel];
    
    emailTextField = [[UITextField alloc] initWithFrame:CGRectMake(40, 285, self.view.frame.size.width - 80, 30)];
    emailTextField.textAlignment = NSTextAlignmentCenter;
    emailTextField.text = [WGProfile currentUser].email;
    emailTextField.font = [FontProperties lightFont:22.0f];
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
    resendButton.frame = CGRectMake(22, self.view.frame.size.height - 60, self.view.frame.size.width*0.4, 47);
    [resendButton setTitle:@"Resend" forState:UIControlStateNormal];
    [resendButton setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
    resendButton.layer.borderColor = [FontProperties getOrangeColor].CGColor;
    resendButton.layer.borderWidth = 1;
    resendButton.layer.cornerRadius = 5;
    resendButton.titleLabel.font = [FontProperties getSmallFont];
    [resendButton addTarget:self action:@selector(resendEmail) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:resendButton];

    
    UIButton *changeButton = [[UIButton alloc] init];
    changeButton.frame = CGRectMake(22 + self.view.frame.size.width*0.4 + 20, self.view.frame.size.height - 60, self.view.frame.size.width*0.4, 47);
    [changeButton setTitle:@"Change Email" forState:UIControlStateNormal];
    [changeButton setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
    changeButton.layer.borderColor = [FontProperties getOrangeColor].CGColor;
    changeButton.layer.borderWidth = 1;
    changeButton.layer.cornerRadius = 5;
    changeButton.titleLabel.font = [FontProperties getSmallFont];
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
    if ([WGProfile currentUser].key) {
        [WGProfile reload:^(BOOL success, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                if (error) {
                    return;
                }
                if ([WGProfile currentUser].emailValidated) {
                    if ([[WGProfile currentUser].group.locked boolValue]) {
                        [self.navigationController pushViewController:[BatteryViewController new] animated:NO];
                    } else {
                        onboardFollowViewController = [OnboardFollowViewController new];
                        [self.navigationController pushViewController:onboardFollowViewController animated:YES];
                    }
                }
            });
        }];
    }
}

- (void)resendEmail {
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    [WiGoSpinnerView addDancingGToCenterView:self.view];
    
    [[WGProfile currentUser] resendVerificationEmail:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [WiGoSpinnerView removeDancingGFromCenterView:self.view];
            [[UIApplication sharedApplication] endIgnoringInteractionEvents];
            if (error) {
                [[WGError sharedInstance] handleError:error actionType:WGActionPost retryHandler:nil];
                return;
            }
            UIAlertView *alertView = [[UIAlertView alloc]
                                      initWithTitle:@"You're good"
                                      message:@"We just resent you a new verification email."
                                      delegate:nil
                                      cancelButtonTitle:@"OK"
                                      otherButtonTitles:nil];
            [alertView show];
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
    [[WGProfile currentUser] saveKey:@"email" withValue:emailString andHandler:^(BOOL success, NSError *error) {
        if (error) {
            [[WGError sharedInstance] handleError:error actionType:WGActionSave retryHandler:nil];
        }
    }];
}




@end
