//
//  SignUpViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/21/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "SignUpViewController.h"
#import "FontProperties.h"
#import <QuartzCore/QuartzCore.h>

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
    
    UIImageView *faceImageView = [[UIImageView alloc] initWithImage:[[Profile user] coverImage]];
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

- (void)initializeEDUAddress {
    UILabel *eduAddressLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 190, self.view.frame.size.width, 40)];
    eduAddressLabel.text = @"Enter your .EDU email address";
    eduAddressLabel.textAlignment = NSTextAlignmentCenter;
    eduAddressLabel.font = [FontProperties getSmallFont];
    [self.view addSubview:eduAddressLabel];
    
    _studentTextField = [[UITextField alloc] initWithFrame:CGRectMake(40, 230, self.view.frame.size.width - 80, 47)];
    _studentTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"student@university.edu" attributes:@{NSForegroundColorAttributeName:RGBAlpha(246, 143, 30, 0.3f)}];
    _studentTextField.textAlignment = NSTextAlignmentCenter;
    _studentTextField.tintColor = [FontProperties getOrangeColor];
    _studentTextField.textColor = [FontProperties getOrangeColor];
    _studentTextField.layer.borderColor = [FontProperties getOrangeColor].CGColor;
    _studentTextField.layer.borderWidth = 1;
    _studentTextField.layer.cornerRadius = 5;
    _studentTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [_studentTextField becomeFirstResponder];
    [self.view addSubview:_studentTextField];
    
    UIButton *continueButton = [[UIButton alloc] initWithFrame:CGRectMake(37, 290, self.view.frame.size.width - 77, 47)];
    continueButton.backgroundColor = RGBAlpha(246, 143, 30, 0.3f);
    [continueButton setTitle:@"Continue" forState:UIControlStateNormal];
    [continueButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    continueButton.layer.borderColor = [UIColor whiteColor].CGColor;
    continueButton.layer.borderWidth = 3;
    continueButton.layer.cornerRadius = 5;
    [continueButton addTarget:self action:@selector(continuePressed) forControlEvents:UIControlEventTouchDown];
    UIImageView *rightArrowImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"rightArrow"]];
    rightArrowImageView.frame = CGRectMake(continueButton.frame.size.width - 35, continueButton.frame.size.height/2 - 9, 11, 18);
    [continueButton addSubview:rightArrowImageView];
    [self.view addSubview:continueButton];
}

- (void)continuePressed {
//    NSError *error = NULL;
//    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:emailRegex options:NSRegularExpressionCaseInsensitive error:&error];
//    NSRange rangeOfFirstMatch = [regex rangeOfFirstMatchInString:_studentTextField.text options:0 range:NSMakeRange(0, [_studentTextField.text length])];
//    if (!NSEqualRanges(rangeOfFirstMatch, NSMakeRange(NSNotFound, 0))) {
//        NSString *substringForFirstMatch = [_studentTextField.text substringWithRange:rangeOfFirstMatch];
//    }
    
    NSString *emailString = _studentTextField.text;
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    BOOL isEmail = [emailTest evaluateWithObject:emailString];
    if (isEmail) {
        [[Profile user] setEmail:emailString];
        [[Profile user] login];
        self.emailConfirmationViewController = [[EmailConfirmationViewController alloc] init];
        [self.navigationController pushViewController:self.emailConfirmationViewController animated:YES];
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Email" message:@"Enter a valid email address" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    
//    [self performSegueWithIdentifier:@"emailSegue" sender:self];
}


@end
