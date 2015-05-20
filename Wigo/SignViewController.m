//
//  SignViewController.m
//
//  Created by Giuliano Giacaglia on 9/26/13.
//  Copyright (c) 2013 Giuliano Giacaglia. All rights reserved.
//

#import "Globals.h"
#import "SignViewController.h"
#import "FacebookHelper.h"
#import <Parse/Parse.h>
#import "WaitListViewController.h"
#import "LocationPrimer.h"


#define kPushNotificationMessage @"When your friends are counting on you to go out, we need to reach you via push notifications."
#define kPushNotificationKey @"push_notification_key"
#define kFacebookIDKey @"facebook_id"
#define kAccessTokenKey @"accessToken"


@interface SignViewController () <UIScrollViewDelegate, FBSDKLoginButtonDelegate>
@property FBSDKLoginButton *loginButton;
@property UIAlertView * alert;
@end

@implementation SignViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.fetchingProfilePictures = NO;
//    self.pushed = NO;
    self.alertShown = NO;
    self.view.backgroundColor = UIColor.whiteColor;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeAlertToNotShown) name:@"changeAlertToNotShown" object:nil];
    
    [self initializeScrollView];
    [self initializeLoginButton];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.alertShown = NO;
    self.fetchingProfilePictures = NO;
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    [self getFacebookTokensAndLoginORSignUp];
    [WGAnalytics tagEvent:@"Sign View"];
    [WGAnalytics tagViewWithNoUser:@"sign"];
}

- (void) changeAlertToNotShown {
    self.alertShown = NO;
    self.fetchingProfilePictures = NO;
}

- (void) getFacebookTokensAndLoginORSignUp {
    self.fbID = [[NSUserDefaults standardUserDefaults] objectForKey:kFacebookIDKey];
    self.accessToken = [[NSUserDefaults standardUserDefaults] objectForKey:kAccessTokenKey];
    NSString *key = WGProfile.currentUser.key;
    if (!key || key.length <= 0) {
        if (!self.fbID || !self.accessToken) {
            [self fetchTokensFromFacebook];
        } else {
            [self loginUserAsynchronous];
        }
    }
}


-(void)initializeLoginButton {
    _loginButton = [[FBSDKLoginButton alloc] init];
    _loginButton.loginBehavior = FBSDKLoginBehaviorSystemAccount;
    _loginButton.readPermissions = @[@"user_friends", @"email", @"user_photos", @"user_work_history", @"user_education_history"];
    _loginButton.delegate = self;
    _loginButton.frame = CGRectMake(0, self.view.frame.size.height - 0.2*self.view.frame.size.width, self.view.frame.size.width, 0.2*self.view.frame.size.width);
    UIImageView *connectFacebookImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"connectFacebook"]];
    connectFacebookImageView.frame = CGRectMake(0, 0, self.view.frame.size.width, 0.2*self.view.frame.size.width);
    [_loginButton addSubview:connectFacebookImageView];
    [_loginButton bringSubviewToFront:connectFacebookImageView];
    [self.view addSubview:_loginButton];
}

- (void)fetchTokensFromFacebook {
    if (![FBSDKAccessToken currentAccessToken]) return;
    [WGSpinnerView addDancingGToCenterView:self.view];
    self.accessToken = [FBSDKAccessToken currentAccessToken].tokenString;
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me/" parameters:nil]
     startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
         [WGSpinnerView removeDancingGFromCenterView:self.view];
         [[UIApplication sharedApplication] endIgnoringInteractionEvents];
         if (!error) {
             if (result[@"email"]) WGProfile.currentUser.email = result[@"email"];
             self.fbID = result[@"id"];
             self.profilePic = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?width=640&height=640", self.fbID];
             WGProfile.currentUser.facebookId = self.fbID;
             [FacebookHelper fillProfileWithUser:result];
             if (!self.alertShown && !self.fetchingProfilePictures) {
                 [self loginUserAsynchronous];
             }
         }
     }];
}


#pragma mark - Sign Up Process

- (void)signUpWithImages:(NSArray *)profilePictures {
    if (!profilePictures) return;
    WGProfile.currentUser.images = profilePictures;
    self.fetchingProfilePictures = NO;
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    [WGSpinnerView addDancingGToCenterView:self.view];
    self.properties = WGProfile.currentUser.properties;
    __weak typeof(self) weakSelf = self;
    if (self.isSigningUp) return;
    self.isSigningUp = YES;
    [WGProfile.currentUser signup:^(BOOL success, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.isSigningUp = NO;
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        [WGSpinnerView removeDancingGFromCenterView:strongSelf.view];
        if (error) {
            [[WGError sharedInstance] logError:error forAction:WGActionSave];
            return;
        }
        WGProfile.currentUser.properties = strongSelf.properties;
        [WGProfile.currentUser save:^(BOOL success, NSError *error) {}];
        [TabBarAuxiliar clearOutAllNotifications];
        [strongSelf presentPushNotification];
    }];
}


#pragma mark - UIAlertView Methods

- (void)showErrorNoConnection {
    if (!self.alertShown) return;
    
    self.alertShown = YES;
    _alert = [[UIAlertView alloc] initWithTitle:@"No Connection"
                                        message:@"Please check your network connection and try again."
                                       delegate:self
                              cancelButtonTitle:@"Ok"
                              otherButtonTitles: nil];
    [_alert show];
    [self logout];
    _alert.delegate = self;
}

- (void)alertView:(UIAlertView *)alertView
didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if ([alertView.message isEqual:kPushNotificationMessage]) return;
    [self fetchTokensFromFacebook];
}

#pragma mark - Facebook Delegate Methods

- (void) loginButton:(FBSDKLoginButton *)loginButton
didCompleteWithResult:(FBSDKLoginManagerLoginResult *)result
               error:(NSError *)error
{
    if (error) {
        if ([[[error userInfo] allKeys] containsObject:@"com.facebook.sdk:ErrorInnerErrorKey"]) {
            NSError *innerError = [[error userInfo] objectForKey:@"com.facebook.sdk:ErrorInnerErrorKey"];
            if ([[innerError domain] isEqualToString:NSURLErrorDomain]) {
                [self showErrorNoConnection];
            }
            
        } else {
            [self handleAuthError:error];
        }
        return;
    }
    if (result.isCancelled) {
        return;
    }
    [self fetchTokensFromFacebook];
}

- (void) loginButtonDidLogOut:(FBSDKLoginButton *)loginButton {
    
}

- (void)handleAuthError:(NSError *)error {
    NSString *alertText;
    NSString *alertTitle;
    if ([FBErrorUtility shouldNotifyUserForError:error] == YES){
        // Error requires people using you app to make an action outside your app to recover
        alertTitle = @"Something went wrong";
        alertText = [FBErrorUtility userMessageForError:error];
        [self showMessage:alertText withTitle:alertTitle];
        
    } else {
        // You need to find more information to handle the error within your app
        if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled) {
            //The user refused to log in into your app, either ignore or...
            alertTitle = @"Login cancelled";
            alertText = @"You need to login to access this part of the app";
            [self showMessage:alertText withTitle:alertTitle];
            
        } else {
            // All other errors that can happen need retries
            // Show the user a generic error message
            alertTitle = @"Facebook Permission";
            alertText = @"To use Wigo, please go to \nSettings > Facebook and\nswitch Wigo to ON";
            [self showMessage:alertText withTitle:alertTitle];
        }
    }
}

- (void)showMessage:(NSString *)text withTitle:(NSString *)title
{
    [[[UIAlertView alloc] initWithTitle:title
                                message:text
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

-(void) loginViewShowingLoggedOutUser:(FBLoginView *)loginView {
    self.alertShown = NO;
}

-(void) logout {
    FBSession* session = [FBSession activeSession];
    [session closeAndClearTokenInformation];
    [session close];
    [FBSession setActiveSession:nil];
    
    NSHTTPCookieStorage* cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray* facebookCookies = [cookies cookiesForURL:[NSURL URLWithString:@"https://facebook.com/"]];
    
    for (NSHTTPCookie* cookie in facebookCookies) {
        [cookies deleteCookie:cookie];
    }
}

#pragma mark - Asynchronous methods

-(void) loginUserAsynchronous {
    [Crashlytics setUserIdentifier:self.fbID];
    WGProfile.currentUser.facebookId = self.fbID;
    WGProfile.currentUser.facebookAccessToken = self.accessToken;
    [WGSpinnerView addDancingGToCenterView:self.view];
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    if (self.isFetching) return;
    self.isFetching = YES;
    __weak typeof(self) weakSelf = self;
    [WGProfile.currentUser login:^(BOOL success, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.isFetching = NO;
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        [WGSpinnerView removeDancingGFromCenterView:strongSelf.view];
        if (error) {
            if ([error.localizedDescription isEqual:@"Request failed: not found (404)"]) {
                [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
                [WGSpinnerView addDancingGToCenterView:strongSelf.view];
                [FacebookHelper fetchProfilePicturesWithHandler:^(NSArray *imagesArray, BOOL success) {
                    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
                    [WGSpinnerView removeDancingGFromCenterView:strongSelf.view];
                    strongSelf.fetchingProfilePictures = NO;
                    [strongSelf signUpWithImages:imagesArray];
                }];
            }
            else {
                strongSelf.fetchingProfilePictures = YES;
                [strongSelf fetchTokensFromFacebook];
            }
            return;
        }
        [NetworkFetcher.defaultGetter fetchFriendsIds];
        [TabBarAuxiliar clearOutAllNotifications];
        [strongSelf presentPushNotification];
    }];
}

-(void) navigate {
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    currentInstallation[@"api_version"] = API_VERSION;
    [currentInstallation setObject:@2.0f forKey:@"api_version_num"];
    currentInstallation[@"wigo_id"] = WGProfile.currentUser.id;
    [currentInstallation saveInBackground];
    
    if (self.pushed) return;
    self.pushed = YES;
    if ([WGProfile.currentUser.status isEqual:kStatusWaiting]) {
        [self.navigationController pushViewController:[WaitListViewController new] animated:YES];
    }
    else [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)reloadedUserInfo:(BOOL)success andError:(NSError *)error {
    [WGSpinnerView removeDancingGFromCenterView:self.view];
    if (error || !success) {
        if (!self.fbID || !self.accessToken) {
            [self fetchTokensFromFacebook];
        } else {
            [self loginUserAsynchronous];
        }
        return;
    }
    [self presentPushNotification];
}

#pragma mark - UIScrollView

-(void)initializeScrollView {
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 0.2*self.view.frame.size.width)];
    self.scrollView.contentSize = CGSizeMake(5*self.view.frame.size.width, self.view.frame.size.height - 0.2*self.view.frame.size.width - 50);
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.delegate = self;
    [self.view addSubview:self.scrollView];
    
    self.pageControl = [[UIPageControl alloc] initWithFrame: CGRectMake(0, self.view.frame.size.height - 0.2*self.view.frame.size.width - 20 - 5, self.view.frame.size.width, 20)];
    self.pageControl.enabled = NO;
    self.pageControl.currentPage = 0;
    self.pageControl.currentPageIndicatorTintColor = [FontProperties getBlueColor];
    self.pageControl.pageIndicatorTintColor = RGB(224, 224, 224);
    self.pageControl.numberOfPages = 5;
    [self.view addSubview: self.pageControl];
    
    [self addText:@"Discover awesome events\nin your area" andImage:@"discover" atIndex:0];
    [self addText:@"See who's going\nin real-time" andImage:@"whoPreview" atIndex:1];
    [self addText:@"Share moments\nwith friends" andImage:@"share" atIndex:2];
    [self addText:@"Finalize plans\nvia chats" andImage:@"chatPreview" atIndex:3];
    [self addText:@"Forget FOMO, forever!" andImage:@"wigoPreview" atIndex:4];
    
    
}

-(void)addText:(NSString *)text
      andImage:(NSString *)imageName
       atIndex:(int)index {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(index*self.view.frame.size.width, 0, self.view.frame.size.width, 100)];
    label.text = text;
    label.numberOfLines = 0;
    label.textColor = UIColor.blackColor;
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [FontProperties lightFont:27.0f];
    [self.scrollView addSubview:label];
    
    float widthOfImage = 0.575*[UIScreen mainScreen].bounds.size.width;
    float heightOfImage = 1.9*widthOfImage;
    if (heightOfImage >= self.pageControl.frame.origin.y - label.frame.origin.y - label.frame.size.height) {
        heightOfImage = self.pageControl.frame.origin.y - label.frame.origin.y - label.frame.size.height - 30;
        widthOfImage = heightOfImage/1.9;
    }
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - widthOfImage/2 + index*self.view.frame.size.width, 95, widthOfImage, 1.9*widthOfImage)];
    imgView.center = CGPointMake(imgView.center.x, (label.center.y + self.pageControl.center.y)/2);
    imgView.image = [UIImage imageNamed:imageName];
    [self.scrollView addSubview:imgView];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    int page = scrollView.contentOffset.x / scrollView.frame.size.width;
    self.pageControl.hidden = (page >= 4);
    self.pageControl.currentPage = page;
}

#pragma mark - Push Notification

-(void) presentPushNotification {
    BOOL wasPushNotificationEnabled = [LocationPrimer wasPushNotificationEnabled];
    if (!wasPushNotificationEnabled) {
        UIVisualEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        self.blurredView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        self.blurredView.frame = self.view.bounds;
        [self.view addSubview:self.blurredView];
        [self presentAlertView];
    }
    else {
        [self navigate];
    }
    
}

- (void)presentAlertView {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                        message:kPushNotificationMessage
                                                       delegate:self
                                              cancelButtonTitle:@"Don't allow"
                                              otherButtonTitles:@"Allow", nil];
    alertView.delegate = self;
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self presentAlertView];
        return;
    }
    
    [[NSUserDefaults standardUserDefaults] setValue:@YES forKey:kPushNotificationKey];
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationCategory *category = [self registerActions];
        NSSet *categories = [NSSet setWithObjects:category, nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:categories]];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    } else {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
         (UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert)];
    }
#else
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
     (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
#endif
    [self.blurredView removeFromSuperview];
    [self navigate];
}

- (UIMutableUserNotificationCategory*)registerActions {
    UIMutableUserNotificationAction* acceptLeadAction = [[UIMutableUserNotificationAction alloc] init];
    acceptLeadAction.identifier = @"tap_with_diff_event";
    acceptLeadAction.title = @"Go Here";
    acceptLeadAction.activationMode = UIUserNotificationActivationModeForeground;
    acceptLeadAction.destructive = false;
    acceptLeadAction.authenticationRequired = false;
    
    UIMutableUserNotificationCategory* category = [[UIMutableUserNotificationCategory alloc] init];
    category.identifier = @"tap_with_diff_event";
    [category setActions:@[acceptLeadAction] forContext: UIUserNotificationActionContextDefault];
    return category;
}


@end