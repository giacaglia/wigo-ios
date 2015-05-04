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
    _scrollView.contentSize = CGSizeMake(self.view.frame.size.width, 550);
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
    self.navigationItem.titleView.tintColor = [FontProperties getOrangeColor];
    self.navigationController.navigationBar.backgroundColor = RGB(235, 235, 235);
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [FontProperties getOrangeColor], NSFontAttributeName:[FontProperties getTitleFont]};
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
    UILabel *photosLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 10, 100, 20)];
    photosLabel.text = @"Photos";
    photosLabel.font = [FontProperties getNormalFont];
    photosLabel.textAlignment = NSTextAlignmentLeft;
    [_scrollView addSubview:photosLabel];
    
    _photosScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 40, self.view.frame.size.width, 110)];
    _photosScrollView.backgroundColor = UIColor.whiteColor;
    _photosScrollView.showsHorizontalScrollIndicator = NO;
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

    NSArray *imageArrayURL = [[WGProfile currentUser] imagesURL];
    NSArray *imageAreaArray = [[WGProfile currentUser] imagesArea];
    
    NSMutableArray *photosArray = [[NSMutableArray alloc] initWithCapacity:[imageArrayURL count] + 1];
    for (int i = 0; i < [imageArrayURL count]; i++) {
        NSString *imageURL = [imageArrayURL objectAtIndex:i];
        UIButton *imageButton = [[UIButton alloc] init];
        imageButton.tag = i;
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 70, 70)];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        [imageView setImageWithURL:[NSURL URLWithString:imageURL] imageArea:[imageAreaArray objectAtIndex:i]];
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
        [self.navigationController pushViewController:[FacebookAlbumTableViewController new] animated:YES];
    } else if (buttonSender.tag < [[[WGProfile currentUser] images] count]) {
        [self.view endEditing:YES];
        PhotoViewController *photoViewController = [[PhotoViewController alloc] initWithImage:[[WGProfile currentUser].images objectAtIndex:buttonSender.tag]];
        photoViewController.indexOfImage = (int)buttonSender.tag;
        [[RWBlurPopover instance] presentViewController:photoViewController withOrigin:0 andHeight:[[UIScreen mainScreen] bounds].size.height fromViewController:self.navigationController];
    }
}



- (void) initializePrivacySection {
    UILabel *privacyLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 150 + 15, 100, 20)];
    privacyLabel.text = @"Privacy";
    privacyLabel.textAlignment = NSTextAlignmentLeft;
    privacyLabel.font = [FontProperties getNormalFont];
    [_scrollView addSubview:privacyLabel];
    
    UIView *publicView = [[UIView alloc] initWithFrame:CGRectMake(0, 200, self.view.frame.size.width, 50)];
    publicView.backgroundColor = [UIColor whiteColor];
    UILabel *publicLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, 160, publicView.frame.size.height)];
    publicLabel.text = @"Private account";
    publicLabel.font = [FontProperties getNormalFont];
    [publicView addSubview:publicLabel];
    _privacySwitch = [[UISwitch alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 60, 10, 40, 20)];
    _privacySwitch.on = [WGProfile currentUser].privacy == PRIVATE;
    
    [publicView addSubview:_privacySwitch];
    [_scrollView addSubview:publicView];
    
    UILabel *publicDetailLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 255, self.view.frame.size.width, 40)];
    publicDetailLabel.text = @"Turn privacy ON to approve follow requests and restrict your plans to only your followers.";
    publicDetailLabel.textAlignment = NSTextAlignmentCenter;
    publicDetailLabel.font = [FontProperties getSmallPhotoFont];
    publicDetailLabel.numberOfLines = 0;
    publicDetailLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [_scrollView addSubview:publicDetailLabel];
}

- (void) initializeWiGoSection {
    UILabel *wiGoLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 255 + 40, 100, 20)];
    wiGoLabel.text = @"Wigo";
    wiGoLabel.textAlignment = NSTextAlignmentLeft;
    wiGoLabel.font = [FontProperties getNormalFont];
    [_scrollView addSubview:wiGoLabel];
    
    UIButton *helpButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 325, self.view.frame.size.width, 50)];
    helpButton.backgroundColor = [UIColor whiteColor];
    UILabel *helpLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, 200, helpButton.frame.size.height)];
    helpLabel.text = @"Contact Us";
    helpLabel.font = [FontProperties getNormalFont];
    [helpButton addSubview:helpLabel];
    [helpButton addTarget:self action:@selector(sendEmail) forControlEvents:UIControlEventTouchUpInside];
    [_scrollView addSubview:helpButton];
    
    UIButton *privacyButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 375, self.view.frame.size.width, 50)];
    privacyButton.backgroundColor = [UIColor whiteColor];
    UILabel *privacyLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, 150, privacyButton.frame.size.height)];
    privacyLabel.text = @"Terms and Privacy";
    privacyLabel.font = [FontProperties getNormalFont];
    [privacyButton addSubview:privacyLabel];
    [privacyButton addTarget:self action:@selector(openPrivacy) forControlEvents:UIControlEventTouchUpInside];
    [_scrollView addSubview:privacyButton];
    
    UIImageView *iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 25, 545, 50, 50)];
    iconImageView.image = [UIImage imageNamed:@"iconFlashScreen"];
    [_scrollView addSubview:iconImageView];
    
    UILabel *versionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 585, self.view.frame.size.width, 50)];
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    NSString *versionString = [info objectForKey:@"CFBundleShortVersionString"];
    versionLabel.text = [NSString stringWithFormat:@"Version %@", versionString];
    versionLabel.font = [FontProperties getSmallFont];
    versionLabel.textAlignment = NSTextAlignmentCenter;
    [_scrollView addSubview:versionLabel];
    
    UILabel *builtInBostonLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 610, self.view.frame.size.width, 50)];
    builtInBostonLabel.text = @"Built in Boston";
    builtInBostonLabel.font = [FontProperties getSmallFont];
    builtInBostonLabel.textAlignment = NSTextAlignmentCenter;
    [_scrollView addSubview:builtInBostonLabel];
    
    UILabel *gitCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 635, self.view.frame.size.width, 50)];
    NSString *gitCount = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"GitCount"];
    NSString *gitHash = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"GitHash"];
    gitCountLabel.text = [NSString stringWithFormat:@"Git Count %@, Git Hash %@", gitCount, gitHash];
    gitCountLabel.font = [FontProperties getSmallPhotoFont];
    gitCountLabel.textAlignment = NSTextAlignmentCenter;
    [_scrollView addSubview:gitCountLabel];
    
    UILabel *debugLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 655, self.view.frame.size.width, 50)];
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
    NSURL *currentURL = [NSURL URLWithString:@"http://www.wigo.us/legal/privacy.html"];
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
