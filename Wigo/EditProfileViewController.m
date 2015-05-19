//
//  EditProfileViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/2/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "EditProfileViewController.h"
#import "Globals.h"

#import "FacebookAlbumTableViewController.h"

#import "UIButtonAligned.h"
#import "RWBlurPopover.h"

@interface EditProfileViewController ()
@property UIScrollView *scrollView;
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
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height + 50);
    _scrollView.backgroundColor = UIColor.whiteColor;
    [self.view addSubview:_scrollView];
    
    self.title = @"Edit Profile";
    
    [self initializeBarButton];
    [self initializePhotosSection];
    [self initializePrivacySection];
    [self initializeWiGoSection];
    
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [WGAnalytics tagView:@"edit_profile"];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    self.initialUserDict = WGProfile.currentUser.deserialize;
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    self.navigationItem.titleView.tintColor = [FontProperties getBlueColor];
    self.navigationController.navigationBar.backgroundColor = UIColor.whiteColor;
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [FontProperties getBlueColor], NSFontAttributeName:[FontProperties getTitleFont]};
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateProfile" object:nil];
}

- (void) initializeBarButton {
    UIButtonAligned *barBt = [[UIButtonAligned alloc] initWithFrame:CGRectMake(0, 0, 75, 44) andType:@1];
    [barBt setTitle:@"Done" forState:UIControlStateNormal];
    [barBt setTitleColor:RGB(160, 160, 160) forState:UIControlStateNormal];
    barBt.titleLabel.font = [FontProperties getSubtitleFont];
    [barBt addTarget:self action: @selector(saveDataAndGoBack) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barItem =  [[UIBarButtonItem alloc] init];
    [barItem setCustomView:barBt];
    self.navigationItem.rightBarButtonItem = barItem;
    
    [self.navigationItem setHidesBackButton:YES];
}

- (void)saveDataAndGoBack {
    WGProfile.currentUser.privacy = _privacySwitch.on ? PRIVATE : PUBLIC;
    if ([self.initialUserDict isEqual:WGProfile.currentUser.deserialize]) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else {
        [WGSpinnerView showOrangeSpinnerAddedTo:self.view];
        [WGProfile.currentUser save:^(BOOL success, NSError *error) {
            [WGSpinnerView hideSpinnerForView:self.view];
            [self dismissViewControllerAnimated:YES  completion: nil];
        }];
    }
}


- (void) initializePhotosSection {
    UILabel *photosLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, self.view.frame.size.width, 20)];
    photosLabel.text = @"Photos";
    photosLabel.font = [FontProperties mediumFont:18.0f];
    photosLabel.textColor = RGB(152, 152, 152);
    photosLabel.textAlignment = NSTextAlignmentCenter;
    [_scrollView addSubview:photosLabel];
    
    _photosScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 40 + 10, self.view.frame.size.width, 110)];
    _photosScrollView.backgroundColor = UIColor.whiteColor;
    _photosScrollView.showsHorizontalScrollIndicator = NO;
    [self updatePhotos];
    [_scrollView addSubview:_photosScrollView];
    
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 160, self.view.frame.size.width, 1)];
    lineView.backgroundColor = RGB(230, 230, 230);
    [_scrollView addSubview:lineView];
}

- (void)updatePhotos {
    [_photosScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];

    NSArray *imageArrayURL = WGProfile.currentUser.imagesURL;
    NSArray *imageAreaArray = WGProfile.currentUser.imagesArea;
    
    NSMutableArray *photosArray = [[NSMutableArray alloc] initWithCapacity:[imageArrayURL count] + 1];
    for (int i = 0; i < [imageArrayURL count]; i++) {
        NSString *imageURL = [imageArrayURL objectAtIndex:i];
        UIButton *imageButton = [[UIButton alloc] init];
        imageButton.tag = i;
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.layer.borderColor = UIColor.clearColor.CGColor;
        imageView.layer.cornerRadius = 5.0f;
        imageView.layer.borderWidth = 1.0f;
        imageView.clipsToBounds = YES;
        [imageView setImageWithURL:[NSURL URLWithString:imageURL] imageArea:[imageAreaArray objectAtIndex:i]];
        [imageButton addSubview:imageView];
        [imageButton addTarget:self action:@selector(selectedEditImage:) forControlEvents:UIControlEventTouchUpInside];
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
        photoButton.frame = CGRectMake(xPosition, 10, 80, 80);
        [_photosScrollView addSubview:photoButton];
        xPosition += 85;
    }
    _photosScrollView.contentSize = CGSizeMake(xPosition, _photosScrollView.frame.size.height);

}

- (void)selectedEditImage:(id)sender {
    UIButton*buttonSender = (UIButton *)sender;
    if (buttonSender.tag == -1) {
        [self.navigationController pushViewController:[FacebookAlbumTableViewController new] animated:YES];
    } else if (buttonSender.tag < [[[WGProfile currentUser] images] count]) {
        [self.view endEditing:YES];
        PhotoViewController *photoViewController = [[PhotoViewController alloc] initWithImage:[WGProfile.currentUser.images objectAtIndex:buttonSender.tag]];
        photoViewController.indexOfImage = (int)buttonSender.tag;
        [self.navigationController addChildViewController:photoViewController];
        [self.navigationController.view addSubview:photoViewController.view];
    }
}



- (void) initializePrivacySection {
    UILabel *privacyLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 160 + 10, self.view.frame.size.width, 20)];
    privacyLabel.text = @"Private Account";
    privacyLabel.textAlignment = NSTextAlignmentCenter;
    privacyLabel.font = [FontProperties mediumFont:18.0f];
    privacyLabel.textColor = RGB(152, 152, 152);
    [_scrollView addSubview:privacyLabel];
    
    self.publicDetailLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 185, self.view.frame.size.width, 40)];
    self.publicDetailLabel.text = @"Turn privacy ON to restrict your\nplans to only your friends.";
    self.publicDetailLabel.textAlignment = NSTextAlignmentCenter;
    self.publicDetailLabel.font = [FontProperties getSmallPhotoFont];
    self.publicDetailLabel.numberOfLines = 0;
    self.publicDetailLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [_scrollView addSubview:self.publicDetailLabel];
    
    _privacySwitch = [[UISwitch alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 30, 185 + 40, 60, 25)];
    _privacySwitch.on = [WGProfile currentUser].privacy == PRIVATE;
    _privacySwitch.onTintColor = [FontProperties getBlueColor];
    [_privacySwitch addTarget:self action:@selector(setState:) forControlEvents:UIControlEventValueChanged];
    [_scrollView addSubview:_privacySwitch];
    
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 276, self.view.frame.size.width, 1)];
    lineView.backgroundColor = RGB(230, 230, 230);
    [_scrollView addSubview:lineView];
}

- (void)setState:(id)sender
{
    if ([sender isOn]) {
        self.publicDetailLabel.text =  @"Turn privacy OFF to share your\nplans with everyone nearby.";
    }
    else {
        self.publicDetailLabel.text =  @"Turn privacy ON to restrict your\nplans to only your friends.";
    }
    
}

- (void) initializeWiGoSection {
    UIButton *helpButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 276 + 1, self.view.frame.size.width, 116 - 2)];
    helpButton.backgroundColor = UIColor.whiteColor;
    UILabel *helpLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, helpButton.frame.size.height)];
    helpLabel.text = @"Contact Us";
    helpLabel.font = [FontProperties getNormalFont];
    helpLabel.textAlignment = NSTextAlignmentCenter;
    [helpButton addSubview:helpLabel];
    [helpButton addTarget:self action:@selector(sendEmail) forControlEvents:UIControlEventTouchUpInside];
    [_scrollView addSubview:helpButton];
    
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 392, self.view.frame.size.width, 1)];
    lineView.backgroundColor = RGB(230, 230, 230);
    [_scrollView addSubview:lineView];
    
    UIButton *privacyButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 392 + 1, self.view.frame.size.width, 116 - 2)];
    privacyButton.backgroundColor = UIColor.whiteColor;
    UILabel *privacyLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, privacyButton.frame.size.height)];
    privacyLabel.text = @"Terms and Privacy";
    privacyLabel.font = [FontProperties getNormalFont];
    privacyLabel.textAlignment = NSTextAlignmentCenter;
    [privacyButton addSubview:privacyLabel];
    [privacyButton addTarget:self action:@selector(openPrivacy) forControlEvents:UIControlEventTouchUpInside];
    [_scrollView addSubview:privacyButton];
    
    UIView *line2View = [[UIView alloc] initWithFrame:CGRectMake(0, 508, self.view.frame.size.width, 1)];
    line2View.backgroundColor = RGB(230, 230, 230);
    [_scrollView addSubview:line2View];
    
    UIImageView *iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 25, [UIScreen mainScreen].bounds.size.height, 50, 50)];
    iconImageView.image = [UIImage imageNamed:@"iconFlashScreen"];
    [_scrollView addSubview:iconImageView];
    
    UILabel *versionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, iconImageView.frame.size.height + iconImageView.frame.origin.y, self.view.frame.size.width, 25)];
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    NSString *versionString = [info objectForKey:@"CFBundleShortVersionString"];
    versionLabel.text = [NSString stringWithFormat:@"Version %@", versionString];
    versionLabel.font = [FontProperties getSmallFont];
    versionLabel.textAlignment = NSTextAlignmentCenter;
    [_scrollView addSubview:versionLabel];
    
    UILabel *builtInBostonLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, versionLabel.frame.origin.y + versionLabel.frame.size.height, self.view.frame.size.width, 25)];
    builtInBostonLabel.text = @"Built in Boston";
    builtInBostonLabel.font = [FontProperties getSmallFont];
    builtInBostonLabel.textAlignment = NSTextAlignmentCenter;
    [_scrollView addSubview:builtInBostonLabel];
    
    UILabel *gitCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, builtInBostonLabel.frame.origin.y + builtInBostonLabel.frame.size.height, self.view.frame.size.width, 25)];
    NSString *gitCount = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"GitCount"];
    NSString *gitHash = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"GitHash"];
    gitCountLabel.text = [NSString stringWithFormat:@"Git Count %@, Git Hash %@", gitCount, gitHash];
    gitCountLabel.font = [FontProperties getSmallPhotoFont];
    gitCountLabel.textAlignment = NSTextAlignmentCenter;
    [_scrollView addSubview:gitCountLabel];
    
    UILabel *debugLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, gitCountLabel.frame.origin.y + gitCountLabel.frame.size.height, self.view.frame.size.width, 25)];
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
    NSURL *currentURL = [NSURL URLWithString:@"http://www.wigo.us/privacy"];
    [self openViewControllerWithURL:currentURL];
}

- (void)sendEmail {
    [self.view endEditing:YES];
    [[RWBlurPopover instance] presentViewController:[ContactUsViewController new] withOrigin:30 andHeight:450 fromViewController:self.navigationController];
}


- (void)openViewControllerWithURL:(NSURL*)url {
    webViewController = [[UIViewController alloc] init];
    UIWebView *webView = [[UIWebView alloc] initWithFrame:self.view.frame];
    [webView loadRequest:[NSURLRequest requestWithURL:url]];
    webView.backgroundColor = UIColor.whiteColor;
    webViewController.view = webView;
    [self.navigationController pushViewController:webViewController animated:NO];
}


@end
