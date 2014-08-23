//
//  EditProfileViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/2/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "EditProfileViewController.h"
#import "Globals.h"

#import "UIButtonAligned.h"
#import "RWBlurPopover.h"

@interface EditProfileViewController ()

@property UIScrollView *scrollView;

@property UITextView *bioTextView;
@property UILabel *totalNumberOfCharactersLabel;
@property UISwitch *privacySwitch;
@property UIScrollView *photosScrollView;

@end

UIViewController *webViewController;

@implementation EditProfileViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePhotos) name:@"updatePhotos" object:nil];
    
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    _scrollView.contentSize = CGSizeMake(self.view.frame.size.width, 905);
    [self.view addSubview:_scrollView];
    
    self.title = @"Edit Profile";
    self.navigationItem.titleView.tintColor = [FontProperties getOrangeColor];
    self.navigationController.navigationBar.backgroundColor = RGB(235, 235, 235);
    
    [self initializeBarButton];
    [self initializePhotosSection];
    [self initializeBioSection];
    [self initializeNotificationsSection];
    [self initializePrivacySection];
    [self initializeWiGoSection];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [EventAnalytics tagEvent:@"Edit Profile View"];
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateProfile" object:nil];
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
    [WiGoSpinnerView showOrangeSpinnerAddedTo:self.view];
    User *profileUser = [Profile user];
    [profileUser setBioString:_bioTextView.text];
    [profileUser setIsPrivate:_privacySwitch.on];
    [profileUser save];
    [WiGoSpinnerView hideSpinnerForView:self.view];
    
    [self.navigationController popViewControllerAnimated:YES];
}


- (void) initializePhotosSection {
    UILabel *photosLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 10, 100, 20)];
    photosLabel.text = @"PHOTOS";
    photosLabel.font = [FontProperties getNormalFont];
    photosLabel.textAlignment = NSTextAlignmentLeft;
    [_scrollView addSubview:photosLabel];
    
    _photosScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 40, self.view.frame.size.width, 110)];
    _photosScrollView.backgroundColor = [UIColor whiteColor];
    [self updatePhotos];
    
    UILabel *coverLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 90, 70, 15)];
    coverLabel.text = @"COVER";
    coverLabel.font = [FontProperties getBioFont];
    coverLabel.textAlignment = NSTextAlignmentCenter;
    coverLabel.textColor = [FontProperties getOrangeColor];
    [_photosScrollView addSubview:coverLabel];

    [_scrollView addSubview:_photosScrollView];
}

- (void)updatePhotos {
    [_photosScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];

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
            imageButton.layer.borderColor = [FontProperties getLightOrangeColor].CGColor;
        }
        [photosArray addObject:imageButton];
    }
    
    if ([imageArrayURL count] < 5) {
        UIButton *imageButton = [[UIButton alloc] init];
        [imageButton setImage:[UIImage imageNamed:@"plusSquare"] forState:UIControlStateNormal];
        imageButton.tag = -1;
        [imageButton addTarget:self action:@selector(selectedEditImage:) forControlEvents:UIControlEventTouchUpInside];
        [photosArray addObject:imageButton];
    }
    
    int xPosition = 15;
    for (UIButton *photoButton in photosArray) {
        photoButton.frame = CGRectMake(xPosition, 10, 70, 70);
        [_photosScrollView addSubview:photoButton];
        xPosition += 75;
    }
    _photosScrollView.contentSize = CGSizeMake(xPosition, _photosScrollView.frame.size.height);

}

- (void)selectedEditImage:(id)sender {
    UIButton*buttonSender = (UIButton *)sender;
    if (buttonSender.tag == -1) {
        self.facebookImagesViewController = [[FacebookImagesViewController alloc] init];
        [self.navigationController pushViewController:self.facebookImagesViewController animated:YES];
    }
    else {
        [self.view endEditing:YES];
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
    _totalNumberOfCharactersLabel.text = [NSString stringWithFormat:@"%d", (MAX_LENGTH_BIO - (int)[_bioTextView.text length])];
    _totalNumberOfCharactersLabel.font = [FontProperties getSubtitleFont];
    _totalNumberOfCharactersLabel.textColor = RGB(153, 153, 153);
    [_bioTextView addSubview:_totalNumberOfCharactersLabel];
}


- (void) initializeNotificationsSection {
    UILabel *notificationsLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 280 + 15, 250, 20)];
    notificationsLabel.text = @"PUSH NOTIFICATIONS";
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
    
    UISwitch *tapsSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(265, 10, 16, 30)];
    tapsSwitch.on = [[Profile user] isTapPushNotificationEnabled];
    [tapsSwitch addTarget:self action:@selector(tapsSwitchPressed:) forControlEvents:UIControlEventValueChanged];
    [shoulderTapView addSubview:tapsSwitch];
    
    UIView *favoritesView = [[UIView alloc] initWithFrame:CGRectMake(0, 375, self.view.frame.size.width, 50)];
    favoritesView.backgroundColor = [UIColor whiteColor];
    [_scrollView addSubview:favoritesView];
    
    UILabel *favoritesLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, 180, shoulderTapView.frame.size.height)];
    favoritesLabel.textAlignment = NSTextAlignmentLeft;
    favoritesLabel.text = @"Favorites going out";
    favoritesLabel.font = [FontProperties getNormalFont];
    [favoritesView addSubview:favoritesLabel];
    
    UISwitch *favoritesSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(265, 10, 16, 30)];
    favoritesSwitch.on = [[Profile user] isFavoritesGoingOutNotificationEnabled];
    [favoritesSwitch addTarget:self action:@selector(favoritesSwitchPressed:) forControlEvents:UIControlEventValueChanged];
    [favoritesView addSubview:favoritesSwitch];
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
    _privacySwitch.on = [[Profile user] isPrivate];
    
    [publicView addSubview:_privacySwitch];
    [_scrollView addSubview:publicView];
    
    UILabel *publicDetailLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 525, self.view.frame.size.width, 40)];
    publicDetailLabel.text = @"Turn privacy ON to approve follow requests and restrict your plans to only your followers.";
    publicDetailLabel.textAlignment = NSTextAlignmentCenter;
    publicDetailLabel.font = [FontProperties getSmallPhotoFont];
    publicDetailLabel.numberOfLines = 0;
    publicDetailLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [_scrollView addSubview:publicDetailLabel];
}

- (void) initializeWiGoSection {
    UILabel *wiGoLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 555 + 40, 100, 20)];
    wiGoLabel.text = @"WiGo";
    wiGoLabel.textAlignment = NSTextAlignmentLeft;
    wiGoLabel.font = [FontProperties getNormalFont];
    [_scrollView addSubview:wiGoLabel];
    
    UIButton *helpButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 625, self.view.frame.size.width, 50)];
    helpButton.backgroundColor = [UIColor whiteColor];
    UILabel *helpLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, 200, helpButton.frame.size.height)];
    helpLabel.text = @"Need help? Contact Us";
    helpLabel.font = [FontProperties getNormalFont];
    [helpButton addSubview:helpLabel];
    [helpButton addTarget:self action:@selector(sendEmail) forControlEvents:UIControlEventTouchUpInside];
    [_scrollView addSubview:helpButton];
    
    UIButton *privacyButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 675, self.view.frame.size.width, 50)];
    privacyButton.backgroundColor = [UIColor whiteColor];
    UILabel *privacyLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, 150, privacyButton.frame.size.height)];
    privacyLabel.text = @"Privacy Policy";
    privacyLabel.font = [FontProperties getNormalFont];
    [privacyButton addSubview:privacyLabel];
    [privacyButton addTarget:self action:@selector(openPrivacy) forControlEvents:UIControlEventTouchUpInside];
    [_scrollView addSubview:privacyButton];
    
    UIButton *termsOfServiceButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 725, self.view.frame.size.width, 50)];
    termsOfServiceButton.backgroundColor = [UIColor whiteColor];
    UILabel *termsOfServiceLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, 150, termsOfServiceButton.frame.size.height)];
    termsOfServiceLabel.text = @"Terms of Service";
    termsOfServiceLabel.font = [FontProperties getNormalFont];
    [termsOfServiceButton addSubview:termsOfServiceLabel];
    [termsOfServiceButton addTarget:self action:@selector(openTerms) forControlEvents:UIControlEventTouchUpInside];
    [_scrollView addSubview:termsOfServiceButton];
    
    UIButton *communityStandardsButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 775, self.view.frame.size.width, 50)];
    communityStandardsButton.backgroundColor = [UIColor whiteColor];
    UILabel *communityStandardsLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, 200, termsOfServiceButton.frame.size.height)];
    communityStandardsLabel.text = @"Community Standards";
    communityStandardsLabel.font = [FontProperties getNormalFont];
    [communityStandardsButton addSubview:communityStandardsLabel];
    [communityStandardsButton addTarget:self action:@selector(openCommunityStandards) forControlEvents:UIControlEventTouchUpInside];
    [_scrollView addSubview:communityStandardsButton];
    
    UIImageView *iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 25, 845, 50, 50)];
    iconImageView.image = [UIImage imageNamed:@"iconFlashScreen"];
    [_scrollView addSubview:iconImageView];
    
    UILabel *versionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 885, self.view.frame.size.width, 50)];
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    NSString *versionString = [info objectForKey:@"CFBundleShortVersionString"];
    versionLabel.text = [NSString stringWithFormat:@"Version %@", versionString];
    versionLabel.font = [FontProperties getSmallFont];
    versionLabel.textAlignment = NSTextAlignmentCenter;
    [_scrollView addSubview:versionLabel];
    
    UILabel *builtInBostonLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 915, self.view.frame.size.width, 50)];
    builtInBostonLabel.text = @"Built in Boston";
    builtInBostonLabel.font = [FontProperties getSmallFont];
    builtInBostonLabel.textAlignment = NSTextAlignmentCenter;
    [_scrollView addSubview:builtInBostonLabel];
    
    UILabel *gitCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 945, self.view.frame.size.width, 50)];
    NSString *gitCount = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"GitCount"];
    NSString *gitHash = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"GitHash"];
    gitCountLabel.text = [NSString stringWithFormat:@"Git Count %@, Git Hash %@", gitCount, gitHash];
    gitCountLabel.font = [FontProperties getSmallPhotoFont];
    gitCountLabel.textAlignment = NSTextAlignmentCenter;
    [_scrollView addSubview:gitCountLabel];
    
    UILabel *debugLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 995, self.view.frame.size.width, 50)];
    NSString *debugString = @"";
    
#if defined(DEBUG)
    debugString = @"Debug";
#elif defined(DISTRIBUTION)
    debugString = @"Distribution";
#else
    debugString = @"Release";
#endif
    
    debugLabel.text = debugString;
    debugLabel.font = [FontProperties getSmallPhotoFont];
    debugLabel.textAlignment = NSTextAlignmentCenter;
    [_scrollView addSubview:debugLabel];
}

- (void)openPrivacy {
    NSURL *currentURL = [NSURL URLWithString:@"http://www.wigo.us/legal/privacy.pdf"];
    [self openViewControllerWithURL:currentURL];
}

- (void)sendEmail {
    [self.view endEditing:YES];
    self.contactUsViewController = [[ContactUsViewController alloc] init];
    [[RWBlurPopover instance] presentViewController:self.contactUsViewController withOrigin:30 andHeight:450];
}

- (void)openTerms {
    NSURL *currentURL = [NSURL URLWithString:@"http://www.wigo.us/legal/rightsandresponsibilities.pdf"];
    [self openViewControllerWithURL:currentURL];
}


- (void) openCommunityStandards {
    NSURL *currentURL = [NSURL URLWithString:@"http://www.wigo.us/legal/communitystandards.pdf"];
    [self openViewControllerWithURL:currentURL];
}

- (void)openViewControllerWithURL:(NSURL*)url {
    webViewController = [[UIViewController alloc] init];
    UIWebView *webView = [[UIWebView alloc] initWithFrame:self.view.frame];
    [webView loadRequest:[NSURLRequest requestWithURL:url]];
    webView.backgroundColor = [UIColor whiteColor];
    webViewController.view = webView;
    [self.navigationController pushViewController:webViewController animated:NO];
}

- (void)tapsSwitchPressed:(id)sender {
    BOOL state = [sender isOn];
    User *profileUser = [Profile user];
    [profileUser setIsTapPushNotificationEnabled:state];
    [profileUser saveKeyAsynchronously:@"properties"];
}

- (void)favoritesSwitchPressed:(id)sender {
    BOOL state = [sender isOn];
    User *profileUser = [Profile user];
    [profileUser setIsFavoritesGoingOutNotificationEnabled:state];
    [profileUser saveKeyAsynchronously:@"properties"];
}

#pragma mark - UITextView Delegate methods

- (void)textViewDidChange:(UITextView *)textView {
    _totalNumberOfCharactersLabel.text = [NSString stringWithFormat:@"%d", (MAX_LENGTH_BIO - (int)[textView.text length])];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSUInteger newLength = [textView.text length] + [text length] - range.length;
    return (newLength > MAX_LENGTH_BIO) ? NO : YES;
}

@end
