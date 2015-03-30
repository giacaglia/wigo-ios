//
//  SignUpViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/21/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "SignUpViewController.h"
#import "Globals.h"
#import "EmailConfirmationViewController.h"

@interface SignUpViewController ()

@property (nonatomic, strong) UIButton *continueButton;
@property (nonatomic, strong) UILabel *eduAddressLabel;
@property (nonatomic, strong) UILabel *errorLabel;
@end

@implementation SignUpViewController

- (id)init
{
    self = [super init];
    if (self) {
        self.view.backgroundColor = UIColor.whiteColor;
        self.navigationItem.hidesBackButton = YES;
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self initializeSignUpLabel];
    [self initializeEDUAddress];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [WGAnalytics tagView:@"sign_up"];
}

- (void) initializeSignUpLabel {
    UILabel *signUpLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 37, self.view.frame.size.width, 28)];
    signUpLabel.text = @"SIGN UP";
    signUpLabel.textColor = [FontProperties getOrangeColor];
    signUpLabel.font = [FontProperties getTitleFont];
    signUpLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:signUpLabel];
}

- (void)initializeEDUAddress {
    _eduAddressLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 66, self.view.frame.size.width, 50)];
    NSString *eduString = [NSString stringWithFormat:@"%@, please enter your .EDU email\nto verify you're a college student", WGProfile.currentUser.firstName];
    NSMutableAttributedString *mutAttributedText = [[NSMutableAttributedString alloc] initWithString:eduString];
    [mutAttributedText addAttribute:NSForegroundColorAttributeName value:RGB(127, 127, 127) range:NSMakeRange(0, eduString.length)];
    [mutAttributedText addAttribute:NSForegroundColorAttributeName value:[FontProperties getOrangeColor] range:NSMakeRange(WGProfile.currentUser.firstName.length + 20, 10)];
    _eduAddressLabel.attributedText = mutAttributedText;
    _eduAddressLabel.textAlignment = NSTextAlignmentCenter;
    _eduAddressLabel.font = [FontProperties mediumFont:16.0f];
    _eduAddressLabel.numberOfLines = 0;
    _eduAddressLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [self.view addSubview:_eduAddressLabel];
    
    self.studentTextField = [[UITextField alloc] init];
    NSString *placeHolderString = [NSString stringWithFormat:@"%@@university.edu", WGProfile.currentUser.firstName.lowercaseString];
    self.studentTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeHolderString attributes:@{NSForegroundColorAttributeName:RGBAlpha(246, 143, 30, 0.3f)}];
    self.studentTextField.textAlignment = NSTextAlignmentCenter;
    self.studentTextField.tintColor = [FontProperties getOrangeColor];
    self.studentTextField.textColor = [FontProperties getOrangeColor];
    self.studentTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.studentTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    [self.studentTextField becomeFirstResponder];
    self.studentTextField.returnKeyType = UIReturnKeyDone;
    [self.studentTextField addTarget:self action:@selector(continuePressed) forControlEvents:UIControlEventEditingDidEndOnExit];
    self.studentTextField.delegate = self;
    self.studentTextField.frame = CGRectMake(40, self.view.frame.size.height/2 - 23, self.view.frame.size.width - 80, 47);
    [self.view addSubview:self.studentTextField];
    
    _errorLabel = [UILabel new];
    _errorLabel.textColor = UIColor.redColor;
    _errorLabel.text = @"Please enter correct email";
    _errorLabel.textAlignment = NSTextAlignmentCenter;
    _errorLabel.font = [FontProperties mediumFont:15.0f];
    _errorLabel.hidden = YES;
    [self.view addSubview:_errorLabel];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    
    _continueButton = [UIButton new];
    _continueButton.backgroundColor = RGBAlpha(246, 143, 30, 0.3f);
    [_continueButton setTitle:@"Continue" forState:UIControlStateNormal];
    [_continueButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    _continueButton.titleLabel.font = [FontProperties scMediumFont:18.0f];
    [_continueButton addTarget:self action:@selector(continuePressed) forControlEvents:UIControlEventTouchUpInside];
    _continueButton.frame =  CGRectMake(0, self.view.frame.size.height - 50, self.view.frame.size.width, 50);
    [self.view addSubview:_continueButton];
}

- (void)continuePressed {
    NSString *emailString = self.studentTextField.text;
    if ([self isTextAnEmail:emailString]) {
        NSArray *images = WGProfile.currentUser.images;
        WGProfile.currentUser.email = emailString;
        __weak typeof(self) weakSelf = self;
        self.studentTextField.enabled = NO;
        [WGSpinnerView addDancingGToCenterView:self.view];
        [WGProfile.currentUser signup:^(BOOL success, NSError *error) {
            __weak typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.studentTextField.enabled = YES;
            if (error) {
                [[WGError sharedInstance] handleError:error actionType:WGActionCreate retryHandler:nil];
                [[WGError sharedInstance] logError:error forAction:WGActionCreate];
                [WGSpinnerView removeDancingGFromCenterView:strongSelf.view];
                return;
            }
            WGProfile.currentUser.images = images;
            __weak typeof(strongSelf) weakOfStrong = strongSelf;
            [WGProfile.currentUser save:^(BOOL success, NSError *error) {
                __strong typeof(weakOfStrong) strongOfStrong = weakOfStrong;
                [WGSpinnerView removeDancingGFromCenterView:strongOfStrong.view];
                if (error) {
                    [[WGError sharedInstance] handleError:error actionType:WGActionSave retryHandler:nil];
                    [[WGError sharedInstance] logError:error forAction:WGActionSave];
                    return;
                }
                EmailConfirmationViewController *emailConfirmationViewController =
                [EmailConfirmationViewController new];
                emailConfirmationViewController.placesDelegate = strongOfStrong.placesDelegate;
                [strongOfStrong.navigationController pushViewController:emailConfirmationViewController animated:YES];
            }];
        }];
    } else {
        _errorLabel.hidden = NO;
    }    
}

- (BOOL)isTextAnEmail:(NSString *)emailString {
    emailString = [emailString stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:emailString];
}

- (void)keyboardDidHide:(NSNotification *)notification {
    NSDictionary* keyboardInfo = [notification userInfo];
    CGRect kbFrame = [[keyboardInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    _continueButton.frame = CGRectMake(0, kbFrame.origin.y - 50, self.view.frame.size.width, 50);
}

- (void)keyboardDidShow:(NSNotification *)notification {
    NSDictionary* keyboardInfo = [notification userInfo];
    CGRect kbFrame = [[keyboardInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    _continueButton.frame = CGRectMake(0, kbFrame.origin.y - 50, self.view.frame.size.width, 50);
    UIImageView *rightArrowImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"rightArrow"]];
    rightArrowImageView.frame = CGRectMake(_continueButton.frame.size.width - 35, _continueButton.frame.size.height/2 - 7, 7, 14);
    [_continueButton addSubview:rightArrowImageView];
    self.studentTextField.frame = CGRectMake(40, _continueButton.frame.origin.y/2 + _eduAddressLabel.frame.origin.y/2 + _eduAddressLabel.frame.size.height/2, self.view.frame.size.width - 80, 47);
    _errorLabel.frame = CGRectMake(0, self.studentTextField.frame.origin.y + self.studentTextField.frame.size.height, self.view.frame.size.width, 20);
}

- (BOOL)textField:(UITextField *)textField
shouldChangeCharactersInRange:(NSRange)range
replacementString:(NSString *)string {
    if (!_errorLabel.isHidden) _errorLabel.hidden = YES;
    NSString *tempString = [[textField.text stringByReplacingCharactersInRange:range withString:string] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.edu";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    BOOL isEDUEmail = [emailTest evaluateWithObject:tempString];
    if (isEDUEmail) {
        _continueButton.backgroundColor = [FontProperties getOrangeColor];
    }
    else {
        _continueButton.backgroundColor = RGBAlpha(246, 143, 30, 0.3f);
    }
    return YES;
}


@end
