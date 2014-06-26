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

@end

@implementation SignUpViewController


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
    
    UIImageView *faceImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"giu3.jpg"]];
    faceImageView.frame = CGRectMake(15, 10, 47, 47);
    faceImageView.layer.cornerRadius = 3;
    faceImageView.layer.borderWidth = 1;
    faceImageView.backgroundColor = [UIColor whiteColor];
    faceImageView.layer.masksToBounds = YES;
    [faceAndNameView addSubview:faceImageView];
    
    UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(75, 24, 200, 22)];
    nameLabel.textAlignment = NSTextAlignmentLeft;
    nameLabel.text = @"Giuliano Giacaglia";
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
    
    UITextField *studentTextField = [[UITextField alloc] initWithFrame:CGRectMake(40, 230, self.view.frame.size.width - 80, 47)];
    studentTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"student@university.edu" attributes:@{NSForegroundColorAttributeName:RGBAlpha(246, 143, 30, 0.3f)}];
    studentTextField.textAlignment = NSTextAlignmentCenter;
    studentTextField.tintColor = [FontProperties getOrangeColor];
    studentTextField.textColor = [FontProperties getOrangeColor];
    studentTextField.layer.borderColor = [FontProperties getOrangeColor].CGColor;
    studentTextField.layer.borderWidth = 1;
    studentTextField.layer.cornerRadius = 5;
    [studentTextField becomeFirstResponder];
    [self.view addSubview:studentTextField];
    
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
    [self performSegueWithIdentifier:@"emailSegue" sender:self];
}


@end
