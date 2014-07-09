//
//  EditProfileViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/2/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "EditProfileViewController.h"
#import "FontProperties.h"
#import "UIButtonAligned.h"
#import "Profile.h"
#import "RWBlurPopover.h"
#import "MBProgressHUD.h"
#import "SDWebImage/UIImageView+WebCache.h"
#import <QuartzCore/QuartzCore.h>

@interface EditProfileViewController ()

@property UIScrollView *scrollView;

@property UITextView *bioTextView;
@property UILabel *totalNumberOfCharactersLabel;
@property UISwitch *privacySwitch;

@end

@implementation EditProfileViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    _scrollView.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height + 100);
    [self.view addSubview:_scrollView];
    
    self.title = @"Edit Profile";
    self.navigationItem.titleView.tintColor = [FontProperties getOrangeColor];
    self.navigationController.navigationBar.backgroundColor = RGB(235, 235, 235);
    
    [self initializeBarButton];
    [self initializePhotosSection];
    [self initializeBioSection];
    [self initializeNotificationsSection];
    [self initializePrivacySection];
}



- (void) initializeBarButton {
    UIButtonAligned *barBt = [[UIButtonAligned alloc] initWithFrame:CGRectMake(0, 0, 75, 44) andType:@1];
    [barBt setTitle:@"Done" forState:UIControlStateNormal];
    [barBt setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
    barBt.titleLabel.font = [FontProperties getSubtitleFont];
    [barBt addTarget:self action: @selector(saveDataAndGoBack) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barItem =  [[UIBarButtonItem alloc] init];
    [barItem setCustomView:barBt];
    self.navigationItem.rightBarButtonItem = barItem;
    
    [self.navigationItem setHidesBackButton:YES];
}

- (void)saveDataAndGoBack {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];

    User *profileUser = [Profile user];
    [profileUser setBioString:_bioTextView.text];
    [profileUser setPrivate:_privacySwitch.on];
    [Profile setUser:profileUser];
    [profileUser save];
    [MBProgressHUD hideHUDForView:self.view animated:YES];

    [self.navigationController popViewControllerAnimated:YES];
}


- (void) initializePhotosSection {
    UILabel *photosLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 10, 100, 20)];
    photosLabel.text = @"PHOTOS";
    photosLabel.font = [FontProperties getNormalFont];
    photosLabel.textAlignment = NSTextAlignmentLeft;
    [_scrollView addSubview:photosLabel];
    
    UIScrollView *photosScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 40, self.view.frame.size.width, 110)];
    photosScrollView.backgroundColor = [UIColor whiteColor];
    
    NSArray *imageArrayURL = [[Profile user] imagesURL];
    NSMutableArray *photosArray = [[NSMutableArray alloc] initWithCapacity:[imageArrayURL count] + 1];
    for (int i = 0; i < [imageArrayURL count]; i++) {
        NSString *imageURL = [imageArrayURL objectAtIndex:i];
        UIButton *imageButton = [[UIButton alloc] init];
        imageButton.tag = i;
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 70, 70)];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        [imageView setImageWithURL:[NSURL URLWithString:imageURL]];
        [imageButton addSubview:imageView];
        [imageButton addTarget:self action:@selector(selectedEditImage:) forControlEvents:UIControlEventTouchUpInside];
        // IF its the cover photo
        if (i == 0) {
            imageButton.layer.borderWidth = 1;
            imageButton.layer.borderColor = [FontProperties getOrangeColor].CGColor;
        }
        [photosArray addObject:imageButton];
    }
    
    if ([imageArrayURL count] < 5) {
        UIButton *imageButton = [[UIButton alloc] init];
        [imageButton setImage:[UIImage imageNamed:@"plusSquare"] forState:UIControlStateNormal];
        imageButton.tag = -1;
        [imageButton addTarget:self action:@selector(selectedEditImage:) forControlEvents:UIControlEventTouchDown];
        [photosArray addObject:imageButton];
    }

    int xPosition = 15;
    for (UIButton *photoButton in photosArray) {
        photoButton.frame = CGRectMake(xPosition, 10, 70, 70);
        [photosScrollView addSubview:photoButton];
        xPosition += 75;
    }
    
    UILabel *coverLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 90, 70, 15)];
    coverLabel.text = @"COVER";
    coverLabel.font = [FontProperties getBioFont];
    coverLabel.textAlignment = NSTextAlignmentCenter;
    coverLabel.textColor = [FontProperties getOrangeColor];
    [photosScrollView addSubview:coverLabel];
    
    photosScrollView.contentSize = CGSizeMake(xPosition, photosScrollView.frame.size.height);
    [_scrollView addSubview:photosScrollView];
}

- (void)selectedEditImage:(id)sender {
    UIButton*buttonSender = (UIButton *)sender;
    if (buttonSender.tag == -1) {
        self.facebookImagesViewController = [[FacebookImagesViewController alloc] init];
        [self.navigationController pushViewController:self.facebookImagesViewController animated:YES];
    }
    else {
        
        self.photoViewController = [[PhotoViewController alloc] initWithImageURL:[[[Profile user] imagesURL] objectAtIndex:buttonSender.tag]];
        [[RWBlurPopover instance] presentViewController:self.photoViewController withOrigin:30 andHeight:450];
    }
}


- (void) initializeBioSection {
    UILabel *bioLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 145 + 15, 100, 20)];
    bioLabel.text = @"SHORT BIO";
    bioLabel.textAlignment = NSTextAlignmentLeft;
    bioLabel.font = [FontProperties getNormalFont];
    [_scrollView addSubview:bioLabel];
    
    UILabel *backgroundLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 190, self.view.frame.size.width, 85)];
    backgroundLabel.backgroundColor = [UIColor whiteColor];
    [_scrollView addSubview:backgroundLabel];
    
    _bioTextView = [[UITextView alloc] initWithFrame:CGRectMake(15, 190, self.view.frame.size.width - 30, 85)];
    _bioTextView.backgroundColor = [UIColor whiteColor];
    _bioTextView.text = [[Profile user] bioString];
    _bioTextView.delegate = self;
    [_scrollView addSubview:_bioTextView];
    
    _totalNumberOfCharactersLabel = [[UILabel alloc] initWithFrame:CGRectMake(_bioTextView.frame.size.width - 85, _bioTextView.frame.size.height - 20, 80, 20)];
    _totalNumberOfCharactersLabel.textAlignment = NSTextAlignmentRight;
    _totalNumberOfCharactersLabel.text = [NSString stringWithFormat:@"%d",[_bioTextView.text length]];
    _totalNumberOfCharactersLabel.font = [FontProperties getSubtitleFont];
    _totalNumberOfCharactersLabel.textColor = RGB(153, 153, 153);
    [_bioTextView addSubview:_totalNumberOfCharactersLabel];
}


- (void) initializeNotificationsSection {
    UILabel *notificationsLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 280 + 15, 150, 20)];
    notificationsLabel.text = @"NOTIFICATIONS";
    notificationsLabel.textAlignment = NSTextAlignmentLeft;
    notificationsLabel.font = [FontProperties getNormalFont];
    [_scrollView addSubview:notificationsLabel];
    
    UIView *shoulderTapView = [[UIView alloc] initWithFrame:CGRectMake(0, 325, self.view.frame.size.width, 50)];
    shoulderTapView.backgroundColor = [UIColor whiteColor];
    [_scrollView addSubview:shoulderTapView];
    
    UILabel *shoulderTapLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, 150, shoulderTapView.frame.size.height)];
    shoulderTapLabel.textAlignment = NSTextAlignmentLeft;
    shoulderTapLabel.text = @"Taps";
    shoulderTapLabel.font = [FontProperties getNormalFont];
    [shoulderTapView addSubview:shoulderTapLabel];
    
    UIButton *emailSettingsButton = [[UIButton alloc] initWithFrame:CGRectMake(220, 15, 36, 20)];
    [emailSettingsButton setImage:[UIImage imageNamed:@"emailUnfilled"] forState:UIControlStateNormal];
    [emailSettingsButton addTarget:self action:@selector(emailPressed:) forControlEvents:UIControlEventTouchDown];
    [shoulderTapView addSubview:emailSettingsButton];
    
    UIButton *phoneButton = [[UIButton alloc] initWithFrame:CGRectMake(285, 10, 16, 30)
                              ];
    [phoneButton addTarget:self action:@selector(phonePressed:) forControlEvents:UIControlEventTouchDown];

    [phoneButton setImage:[UIImage imageNamed:@"phoneFilled"] forState:UIControlStateNormal];
    [shoulderTapView addSubview:phoneButton];
    
    UIView *favoritesView = [[UIView alloc] initWithFrame:CGRectMake(0, 375, self.view.frame.size.width, 50)];
    favoritesView.backgroundColor = [UIColor whiteColor];
    [_scrollView addSubview:favoritesView];
    
    UILabel *favoritesLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, 180, shoulderTapView.frame.size.height)];
    favoritesLabel.textAlignment = NSTextAlignmentLeft;
    favoritesLabel.text = @"Favorites going out";
    favoritesLabel.font = [FontProperties getNormalFont];
    [favoritesView addSubview:favoritesLabel];
    
    UIButton *emailSettingsButton2 = [[UIButton alloc] initWithFrame:CGRectMake(220, 15, 36, 20)];
    [emailSettingsButton2 setImage:[UIImage imageNamed:@"emailUnfilled"] forState:UIControlStateNormal];
    [emailSettingsButton2 addTarget:self action:@selector(emailPressed:) forControlEvents:UIControlEventTouchDown];
    [favoritesView addSubview:emailSettingsButton2];
    
    UIButton *phoneButtons2 = [[UIButton alloc] initWithFrame:CGRectMake(285, 10, 16, 30)
                              ];
    [phoneButtons2 setImage:[UIImage imageNamed:@"phoneFilled"] forState:UIControlStateNormal];
    [phoneButtons2 addTarget:self action:@selector(phonePressed:) forControlEvents:UIControlEventTouchDown];
    [favoritesView addSubview:phoneButtons2];
}

- (void)emailPressed:(id)sender {
    UIButton *buttonPressed = (UIButton *)sender;
    if (buttonPressed.tag == -100) {
        [buttonPressed setImage:[UIImage imageNamed:@"emailFilled"] forState:UIControlStateNormal];
        buttonPressed.tag = 100;
    }
    else {
        [buttonPressed setImage:[UIImage imageNamed:@"emailUnfilled"] forState:UIControlStateNormal];
        buttonPressed.tag = -100;
    }
}

- (void)phonePressed:(id)sender {
    UIButton *buttonPressed = (UIButton *)sender;
    if (buttonPressed.tag == -100) {
        [buttonPressed setImage:[UIImage imageNamed:@"phoneFilled"] forState:UIControlStateNormal];
        buttonPressed.tag = 100;
    }
    else {
        buttonPressed.tintColor = [UIColor grayColor];
        [buttonPressed setImage:[UIImage imageNamed:@"phoneUnfilled"] forState:UIControlStateNormal];
        buttonPressed.tag = -100;
    }
}

- (void) initializePrivacySection {
    UILabel *privacyLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 400 + 40, 100, 20)];
    privacyLabel.text = @"PRIVACY";
    privacyLabel.textAlignment = NSTextAlignmentLeft;
    privacyLabel.font = [FontProperties getNormalFont];
    [_scrollView addSubview:privacyLabel];
    
    UIView *publicView = [[UIView alloc] initWithFrame:CGRectMake(0, 470, self.view.frame.size.width, 50)];
    publicView.backgroundColor = [UIColor whiteColor];
    UILabel *publicLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, 150, publicView.frame.size.height)];
    publicLabel.text = @"Private account";
    publicLabel.font = [FontProperties getNormalFont];
    [publicView addSubview:publicLabel];
    _privacySwitch = [[UISwitch alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 60, 10, 40, 20)];
    _privacySwitch.on = [[Profile user] private];
    
    [publicView addSubview:_privacySwitch];
    [_scrollView addSubview:publicView];
    
    UILabel *publicDetailLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 525, self.view.frame.size.width, 40)];
    publicDetailLabel.text = @"Turn privacy ON to approve follow requests and restrict your Places to only your followers.";
    publicDetailLabel.textAlignment = NSTextAlignmentCenter;
    publicDetailLabel.font = [FontProperties getSmallPhotoFont];
    publicDetailLabel.numberOfLines = 0;
    publicDetailLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [_scrollView addSubview:publicDetailLabel];
}

#pragma mark - UITextView Delegate methods

- (void)textViewDidChange:(UITextView *)textView {
    _totalNumberOfCharactersLabel.text = [NSString stringWithFormat:@"%d",[textView.text length]];
}

@end
