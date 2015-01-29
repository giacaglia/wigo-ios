//
//  SignUpViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/21/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "SignUpViewController.h"
#import "Globals.h"
#define isiPhone5  ([[UIScreen mainScreen] bounds].size.height == 568)?TRUE:FALSE


@interface SignUpViewController ()
@property UITextField *studentTextField;
@end

@implementation SignUpViewController

- (id)init
{
    self = [super init];
    if (self) {
        self.view.backgroundColor = [UIColor whiteColor];
        self.navigationItem.hidesBackButton = YES;
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self initializeSignUpLabel];
    [self initializeFaceAndNameLabel];
    [self initializeEDUAddress];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [WGAnalytics tagEvent:@"Sign Up View"];
}

- (void) initializeSignUpLabel {
    UILabel *signUpLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 37, self.view.frame.size.width, 28)];
    signUpLabel.text = @"SIGN UP";
    signUpLabel.textColor = [FontProperties getOrangeColor];
    signUpLabel.font = [FontProperties getTitleFont];
    signUpLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:signUpLabel];
}

- (void)initializeFaceAndNameLabel {
    UIView *faceAndNameView = [[UIView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, 68)];
    faceAndNameView.backgroundColor = [FontProperties getLightOrangeColor];
    
    UIImageView *faceImageView = [[UIImageView alloc] init];
    faceImageView.contentMode = UIViewContentModeScaleAspectFill;
    faceImageView.clipsToBounds = YES;
    [faceImageView setSmallImageForUser:WGProfile.currentUser completed:nil];
    faceImageView.frame = CGRectMake(15, 10, 47, 47);
    faceImageView.layer.cornerRadius = 3;
    faceImageView.layer.borderWidth = 1;
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

- (void)initializeEDUAddress {
    UILabel *eduAddressLabel = [[UILabel alloc] init];
    eduAddressLabel.text = @"Enter your .EDU email to verify you're a college student:";
    eduAddressLabel.textAlignment = NSTextAlignmentCenter;
    eduAddressLabel.font = [FontProperties getSmallFont];
    eduAddressLabel.numberOfLines = 0;
    eduAddressLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [self.view addSubview:eduAddressLabel];
    
    _studentTextField = [[UITextField alloc] init];
    _studentTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"student@university.edu" attributes:@{NSForegroundColorAttributeName:RGBAlpha(246, 143, 30, 0.3f)}];
    _studentTextField.textAlignment = NSTextAlignmentCenter;
    _studentTextField.tintColor = [FontProperties getOrangeColor];
    _studentTextField.textColor = [FontProperties getOrangeColor];
    _studentTextField.layer.borderColor = [FontProperties getOrangeColor].CGColor;
    _studentTextField.layer.borderWidth = 1;
    _studentTextField.layer.cornerRadius = 5;
    _studentTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _studentTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    [_studentTextField becomeFirstResponder];
    [_studentTextField addTarget:self action:@selector(continuePressed) forControlEvents:UIControlEventEditingDidEndOnExit];
    [self.view addSubview:_studentTextField];
    
    UIButton *continueButton = [[UIButton alloc] init];
    continueButton.backgroundColor = RGBAlpha(246, 143, 30, 0.3f);
    [continueButton setTitle:@"Continue" forState:UIControlStateNormal];
    [continueButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    continueButton.layer.borderColor = [UIColor whiteColor].CGColor;
    continueButton.layer.borderWidth = 3;
    continueButton.layer.cornerRadius = 5;
    [continueButton addTarget:self action:@selector(continuePressed) forControlEvents:UIControlEventTouchUpInside];
    
    if (isiPhone5) {
        eduAddressLabel.frame = CGRectMake(40, 150, self.view.frame.size.width - 80, 50);
        _studentTextField.frame = CGRectMake(40, 210, self.view.frame.size.width - 80, 47);
        continueButton.frame = CGRectMake(37, 270, self.view.frame.size.width - 77, 47);
    } else {
        eduAddressLabel.frame = CGRectMake(40, 130, self.view.frame.size.width - 80, 50);
        _studentTextField.frame = CGRectMake(40, 180, self.view.frame.size.width - 80, 37);
        continueButton.frame = CGRectMake(37, 225, self.view.frame.size.width - 77, 37);
    }
    
    UIImageView *rightArrowImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"rightArrow"]];
    rightArrowImageView.frame = CGRectMake(continueButton.frame.size.width - 35, continueButton.frame.size.height/2 - 9, 11, 18);
    [continueButton addSubview:rightArrowImageView];
    [self.view addSubview:continueButton];
}

- (void)continuePressed {
    NSString *emailString = _studentTextField.text;
    emailString = [emailString stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    BOOL isEmail = [emailTest evaluateWithObject:emailString];
    if (isEmail) {
        NSArray *images = [[WGProfile currentUser] images];
        [WGProfile currentUser].email = emailString;
        
        [[WGProfile currentUser] signup:^(BOOL success, NSError *error) {
            if (error) {
                [[WGError sharedInstance] handleError:error actionType:WGActionCreate retryHandler:nil];
                [[WGError sharedInstance] logError:error forAction:WGActionCreate];
                return;
            }
            [WGProfile currentUser].images = images;
            [[WGProfile currentUser] save:^(BOOL success, NSError *error) {
                if (error) {
                    [[WGError sharedInstance] handleError:error actionType:WGActionSave retryHandler:nil];
                    [[WGError sharedInstance] logError:error forAction:WGActionSave];
                    return;
                }
                self.emailConfirmationViewController = [[EmailConfirmationViewController alloc] init];
                [self.navigationController pushViewController:self.emailConfirmationViewController animated:YES];
            }];
        }];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Email" message:@"Enter a valid email address" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }    
}

@end
