    //
//  SignUpViewController.m
//  webPays
//
//  Created by Giuliano Giacaglia on 9/26/13.
//  Copyright (c) 2013 Giuliano Giacaglia. All rights reserved.
//

#import "Globals.h"
#import "SignViewController.h"
#import "FacebookHelper.h"
#import <Parse/Parse.h>
#import "ReferalViewController.h"
#import "WaitListViewController.h"

#define kPushNotificationMessage @"Wigo works best when you enable push notifications so we can let you know when the next party is happening."
#define kPushNotificationKey @"push_notification_key"


@interface SignViewController () <UIScrollViewDelegate>
@property UIView *facebookConnectView;
@property BOOL pushed;
@property FBLoginView *loginView;
@property NSString * profilePicturesAlbumId;
@property NSString *profilePic;
@property NSString *accessToken;
@property NSString *fbID;
@property UIAlertView * alert;
@property BOOL alertShown;
@end

@implementation SignViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.fetchingProfilePictures = NO;
    self.view.backgroundColor = UIColor.whiteColor;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeAlertToNotShown) name:@"changeAlertToNotShown" object:nil];
    _alertShown = NO;
    _pushed = NO;
    
    [self initializeScrollView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [WGAnalytics tagView:@"sign"];
    _alertShown = NO;
    self.fetchingProfilePictures = NO;
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    [self getFacebookTokensAndLoginORSignUp];
}

- (void) changeAlertToNotShown {
    _alertShown = NO;
    self.fetchingProfilePictures = NO;
}

- (void) getFacebookTokensAndLoginORSignUp {
    _fbID = [[NSUserDefaults standardUserDefaults] objectForKey:@"facebook_id"];
    _accessToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"accessToken"];

    NSString *key = [[NSUserDefaults standardUserDefaults] objectForKey:@"key"];
    if (!key || key.length <= 0) {
        if (!_fbID || !_accessToken) {
            [self fetchTokensFromFacebook];
        } else {
            [self loginUserAsynchronous];
        }
    }
}

- (void)fetchTokensFromFacebook {
    if (_loginView) [_loginView removeFromSuperview];
    
    _loginView = [[FBLoginView alloc] initWithReadPermissions: @[@"user_friends", @"user_photos", @"user_work_history", @"user_education_history"]];
    _loginView.loginBehavior = FBSessionLoginBehaviorUseSystemAccountIfPresent;
    _loginView.delegate = self;
    _loginView.frame = CGRectMake(0, self.view.frame.size.height - 0.2*self.view.frame.size.width, self.view.frame.size.width, 0.2*self.view.frame.size.width);
    UIImageView *connectFacebookImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"connectFacebook"]];
    connectFacebookImageView.backgroundColor = [UIColor whiteColor];
    connectFacebookImageView.frame = CGRectMake(0, 0, self.view.frame.size.width, 0.2*self.view.frame.size.width);
    [_loginView addSubview:connectFacebookImageView];
    [_loginView bringSubviewToFront:connectFacebookImageView];
    [self.view addSubview:_loginView];
    
}


#pragma mark - Sign Up Process

- (void) fetchProfilePicturesAlbumFacebook {
    [FBRequestConnection startWithGraphPath:@"/me/albums"
                                 parameters:nil
                                 HTTPMethod:@"GET"
                          completionHandler:^(
                                              FBRequestConnection *connection,
                                              id result,
                                              NSError *error
                                              ) {
                              if (error) {
                                  self.fetchingProfilePictures = NO;
                                  [[WGError sharedInstance] logError:error forAction:WGActionFacebook];
                              }
                              BOOL foundProfilePicturesAlbum = NO;
                              FBGraphObject *resultObject = (FBGraphObject *)[result objectForKey:@"data"];
                              for (FBGraphObject *album in resultObject) {
                                  if ([[album objectForKey:@"name"] isEqualToString:@"Profile Pictures"]) {
                                      foundProfilePicturesAlbum = YES;
                                      _profilePicturesAlbumId = (NSString *)[album objectForKey:@"id"];
                                      [self get3ProfilePictures];
                                      break;
                                  }
                              }
                              if (!foundProfilePicturesAlbum) {
                                  self.fetchingProfilePictures = NO;
                                  NSMutableArray *profilePictures = [[NSMutableArray alloc] initWithCapacity:0];
                                  [profilePictures addObject:@{@"url": _profilePic}];
                                  [self saveProfilePictures:profilePictures];
                              }
                          }];

}

- (void) get3ProfilePictures {
    NSMutableArray *profilePictures = [[NSMutableArray alloc] initWithCapacity:0];
    [WGSpinnerView addDancingGToCenterView:self.view];
    [FBRequestConnection startWithGraphPath:[NSString stringWithFormat:@"/%@/photos", _profilePicturesAlbumId]
                                 parameters:nil
                                 HTTPMethod:@"GET"
                          completionHandler:^(
                                              FBRequestConnection *connection,
                                              id result,
                                              NSError *error
                                              ) {
                              if (error) {
                                  self.fetchingProfilePictures = NO;
                                  [[WGError sharedInstance] logError:error forAction:WGActionFacebook];
                              }
                              FBGraphObject *resultObject = [result objectForKey:@"data"];
                              for (FBGraphObject *photoRepresentation in resultObject) {
                                  FBGraphObject *images = [photoRepresentation objectForKey:@"images"];
                                  FBGraphObject *newPhoto = [FacebookHelper getFirstFacebookPhotoGreaterThanX:600 inPhotoArray:images];
                                  FBGraphObject *smallPhoto = [FacebookHelper getFirstFacebookPhotoGreaterThanX:200 inPhotoArray:images];
                                  if (newPhoto) {
                                      NSDictionary *newImage;
                                      if (smallPhoto) {
                                          newImage =
                                            @{
                                              @"url": [newPhoto objectForKey:@"source"],
                                              @"id": [photoRepresentation objectForKey:@"id"],
                                              @"type": @"facebook",
                                              @"small": [smallPhoto objectForKey:@"source"]
                                            };
                                      }
                                      else {
                                          newImage =
                                          @{
                                            @"url": [newPhoto objectForKey:@"source"],
                                            @"id": [photoRepresentation objectForKey:@"id"],
                                            @"type": @"facebook",
                                            };
                                      }
                                      [profilePictures addObject:newImage];
                                      if ([profilePictures count] == 1) {
                                          [WGProfile currentUser].image = [profilePictures objectAtIndex:0];
                                      }
                                      if ([profilePictures count] >= 3) {
                                          break;
                                      }

                                  }
                                }
                                if ([profilePictures count] == 0) {
                                    [profilePictures addObject:@{@"url": @"https://api.wigo.us/static/img/wigo_profile_gray.png"}];
                                }
                                [self saveProfilePictures:profilePictures];
                          }];
}


- (void)saveProfilePictures:(NSMutableArray *)profilePictures {
    WGProfile.currentUser.images = profilePictures;
    if (_pushed) return;

    _pushed = YES;
    self.fetchingProfilePictures = NO;
    [WGSpinnerView removeDancingGFromCenterView:self.view];
    __weak typeof(self) weakSelf = self;
    [WGProfile.currentUser save:^(BOOL success, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [WGSpinnerView removeDancingGFromCenterView:strongSelf.view];
        if (error) {
            [[WGError sharedInstance] logError:error forAction:WGActionSave];
            return;
        }
        if ([WGProfile.currentUser.status isEqual:kStatusWaiting]) {
            [strongSelf.navigationController pushViewController:[WaitListViewController new] animated:YES];
        }
        else [strongSelf dismissViewControllerAnimated:YES completion:nil];
    }];
}


#pragma mark - UIAlertView Methods

- (void)showErrorNoConnection {
    if (!_alertShown) {
        _alertShown = YES;
        _alert = [[UIAlertView alloc] initWithTitle:@"No Connection"
                                            message:@"Please check your network connection and try again."
                                           delegate:self
                                  cancelButtonTitle:@"Ok"
                                  otherButtonTitles: nil];
        [_alert show];
        [self logout];
        _alert.delegate = self;
    }
}

- (void)alertView:(UIAlertView *)alertView
didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if ([alertView.message isEqual:kPushNotificationMessage]) return;
    [self fetchTokensFromFacebook];
}

#pragma mark - Facebook Delegate Methods

- (void) loginViewFetchedUserInfo:(FBLoginView *)loginView user:(id<FBGraphUser>)fbGraphUser {
    if (_pushed) return;
    
    _fbID = [fbGraphUser objectID];
    _profilePic = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?width=640&height=640", [fbGraphUser objectForKey:@"id"]];
    _accessToken = [FBSession activeSession].accessTokenData.accessToken;
    [FacebookHelper fillProfileWithUser:fbGraphUser];
    if (!_alertShown && !self.fetchingProfilePictures) {
        [self loginUserAsynchronous];
    }
    
}

- (void) loginView:(FBLoginView *)loginView handleError:(NSError *)error {
    if ([[[error userInfo] allKeys] containsObject:@"com.facebook.sdk:ErrorInnerErrorKey"]) {
        NSError *innerError = [[error userInfo] objectForKey:@"com.facebook.sdk:ErrorInnerErrorKey"];
        if ([[innerError domain] isEqualToString:NSURLErrorDomain]) {
            [self showErrorNoConnection];
        }

    } else {
        [self handleAuthError:error];
    }
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
            alertTitle = @"Something went wrong";
            alertText = @"Please retry";
            [self showMessage:alertText withTitle:alertTitle];
        }
    }
}

- (void)showMessage:(NSString *)text withTitle:(NSString *)title
{
    [[[UIAlertView alloc] initWithTitle:title
                                message:text
                               delegate:self
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

-(void) loginViewShowingLoggedOutUser:(FBLoginView *)loginView {
    _alertShown = NO;
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
    [Crashlytics setUserIdentifier:_fbID];
    
    WGProfile.currentUser.facebookId = _fbID;
    WGProfile.currentUser.facebookAccessToken = _accessToken;
    
    [WGSpinnerView addDancingGToCenterView:self.view];
    __weak typeof(self) weakSelf = self;
    [WGProfile.currentUser login:^(BOOL success, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [WGSpinnerView removeDancingGFromCenterView:strongSelf.view];
        if (error) {
            strongSelf.fetchingProfilePictures = YES;
            [strongSelf logout];
            [strongSelf fetchTokensFromFacebook];
            if ([error.localizedDescription isEqual:@"Request failed: not found (404)"]) {
                [strongSelf fetchProfilePicturesAlbumFacebook];
            }
            [[WGError sharedInstance] handleError:error actionType:WGActionLogin retryHandler:nil];
            [[WGError sharedInstance] logError:error forAction:WGActionLogin];
            return;
        }
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
    
    if (_pushed) return;
    _pushed = YES;

    if ([WGProfile.currentUser.status isEqual:kStatusWaiting]) {
        [self.navigationController pushViewController:[WaitListViewController new] animated:YES];
    }
    else [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)reloadedUserInfo:(BOOL)success andError:(NSError *)error {
    [WGSpinnerView removeDancingGFromCenterView:self.view];
    if (error || !success) {
        if (!_fbID || !_accessToken) {
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
    
    [self addText:@"Discover awesome events\nin your area" andImage:@"discover" atIndex:0];
    [self addText:@"See who's going\nin real-time" andImage:@"whoPreview" atIndex:1];
    [self addText:@"Share moments\nwith friends" andImage:@"share" atIndex:2];
    [self addText:@"Finalize plans\nvia chats" andImage:@"chatPreview" atIndex:3];
    [self addText:@"Forget FOMO, forever!" andImage:@"wigoPreview" atIndex:4];

    self.pageControl = [[UIPageControl alloc] initWithFrame: CGRectMake(0, self.view.frame.size.height - 0.2*self.view.frame.size.width - 20 - 5, self.view.frame.size.width, 20)];
    self.pageControl.enabled = NO;
    self.pageControl.currentPage = 0;
    self.pageControl.currentPageIndicatorTintColor = [FontProperties getBlueColor];
    self.pageControl.pageIndicatorTintColor = RGB(224, 224, 224);
    self.pageControl.numberOfPages = 5;
    [self.view addSubview: self.pageControl];
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
    
    UIImageView *fourthImgView = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 92 + index*self.view.frame.size.width, 95, 184, 355)];
    fourthImgView.image = [UIImage imageNamed:imageName];
    [self.scrollView addSubview:fourthImgView];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    int page = scrollView.contentOffset.x / scrollView.frame.size.width;
    self.pageControl.hidden = (page >= 4);
    self.pageControl.currentPage = page;
}

#pragma mark - Push Notification

-(void) presentPushNotification {
    NSNumber *wasSentPushNotification = [[NSUserDefaults standardUserDefaults] objectForKey:kPushNotificationKey];
    if (!wasSentPushNotification) {
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
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"triedToRegister"];
    [[NSUserDefaults standardUserDefaults] synchronize];
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