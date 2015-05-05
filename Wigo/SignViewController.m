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


@interface SignViewController ()
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


- (id)init
{
    self = [super init];
    if (self) {
        self.fetchingProfilePictures = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeAlertToNotShown) name:@"changeAlertToNotShown" object:nil];
    _alertShown = NO;
    self.fetchingProfilePictures = NO;
    _pushed = NO;
    
    [self initializeLogo];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [WGAnalytics tagView:@"sign"];
    _alertShown = NO;
    self.fetchingProfilePictures = NO;
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    [self showOnboard];
    [self presentPushNotification];
}

-(void) showBarrierError:(NSError *)error {
    [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
}

- (void)showOnboard {
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

- (void) fetchTokensFromFacebook {
    _facebookConnectView.hidden = NO;
    [self initializeFacebookSignButton];
}

- (void)initializeLogo {
    _facebookConnectView = [[UIView alloc] initWithFrame:self.view.frame];
    _facebookConnectView.hidden = YES;
    [self.view addSubview:_facebookConnectView];
    
    UIImageView *logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"wigoLogo"]];
    logoImageView.frame = CGRectMake(self.view.frame.size.width/2 - 132, self.view.frame.size.height/2 - 75 - 40, 265, 151);
    [_facebookConnectView addSubview:logoImageView];
}

- (void)initializeFacebookSignButton {
    _loginView = [[FBLoginView alloc] initWithReadPermissions: @[@"user_friends", @"user_photos", @"user_work_history", @"user_education_history"]];
    _loginView.loginBehavior = FBSessionLoginBehaviorUseSystemAccountIfPresent;
    _loginView.delegate = self;
    _loginView.frame = CGRectMake(0, self.view.frame.size.height - 50 - 50, 256, 50);
    _loginView.frame = CGRectOffset(_loginView.frame, (self.view.center.x - (_loginView.frame.size.width / 2)), 5);
    _loginView.backgroundColor = [UIColor whiteColor];
    UIImageView *connectFacebookImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"connectFacebook"]];
    connectFacebookImageView.backgroundColor = [UIColor whiteColor];
    connectFacebookImageView.frame = CGRectMake(0, 0, 256, 50);
    [_loginView addSubview:connectFacebookImageView];
    [_loginView bringSubviewToFront:connectFacebookImageView];
    [self.view addSubview:_loginView];
    
    UILabel *dontWorryLabel = [[UILabel alloc] init];
    dontWorryLabel.frame = CGRectMake(0, self.view.frame.size.height - 30 - 20, self.view.frame.size.width, 30);
    dontWorryLabel.text = @"Don't worry, we'll NEVER post on your behalf.";
    dontWorryLabel.font = [FontProperties mediumFont:13.0f];
    dontWorryLabel.textColor = RGB(51, 102, 154);
    dontWorryLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:dontWorryLabel];
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
    if (!_pushed) {
        _pushed = YES;
        self.fetchingProfilePictures = NO;
        [WGSpinnerView removeDancingGFromCenterView:self.view];
        __weak typeof(self) weakSelf = self;
        [WGProfile.currentUser save:^(BOOL success, NSError *error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [WGSpinnerView removeDancingGFromCenterView:strongSelf.view];
            if (error) {
                [[WGError sharedInstance] handleError:error actionType:WGActionSave retryHandler:nil];
                [[WGError sharedInstance] logError:error forAction:WGActionSave];
                return;
            }
            
            [strongSelf dismissViewControllerAnimated:YES completion:nil];
        }];

        
    }
}




#pragma mark - UIAlertView Methods

- (void)showErrorLoginFailed {
    _alert = [[UIAlertView alloc] initWithTitle:@"Not so fast!"
                                        message:@"Wigo requires Facebook login. Open Settings > Facebook and make sure Wigo is turned on."
                                       delegate:self
                              cancelButtonTitle:@"Ok"
                              otherButtonTitles: nil];
    [_alert show];
}

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

- (void)showBummerError {
    _alertShown = YES;
    _alert = [[UIAlertView alloc] initWithTitle:@"Bummer"
                                        message:@"We fudged something up. Please try again later."
                                       delegate:self
                              cancelButtonTitle:@"Ok"
                              otherButtonTitles: nil];
    [_alert show];
    [self logout];
    _alert.delegate = self;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    [self fetchTokensFromFacebook];
}

#pragma mark - Facebook Delegate Methods

- (void) loginViewFetchedUserInfo:(FBLoginView *)loginView user:(id<FBGraphUser>)fbGraphUser {
    if (!_pushed) {
        _fbID = [fbGraphUser objectID];
        _profilePic = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?width=640&height=640", [fbGraphUser objectForKey:@"id"]];
        _accessToken = [FBSession activeSession].accessTokenData.accessToken;
        
        WGProfile.currentUser.firstName = fbGraphUser[@"first_name"];
        WGProfile.currentUser.lastName = fbGraphUser[@"last_name"];
        if (fbGraphUser[@"birthday"]) WGProfile.currentUser.birthday = fbGraphUser[@"birthday"];
        if (fbGraphUser[@"education"]) {
            NSArray *schoolArray = ((NSArray *)fbGraphUser[@"education"]);
            NSArray *filteredArray = [schoolArray filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
                FBGraphObject *school = (FBGraphObject *)object;
                return ([school[@"type"] isEqual:@"College"]);
            }]];
            if (filteredArray.count > 0) {
                FBGraphObject *firstSchool = [filteredArray objectAtIndex:0];
                WGProfile.currentUser.education = [[firstSchool objectForKey:@"school"] objectForKey:@"name"];
            }
        }
        if (fbGraphUser[@"work"]) {
            NSArray *workArray = fbGraphUser[@"work"];
            if (workArray.count > 0) {
                NSDictionary *employerDict = [workArray objectAtIndex:0];
                if (employerDict && [employerDict isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *details = [employerDict objectForKey:@"employer"];
                    if (details && [details isKindOfClass:[NSDictionary class]]) {
                        if ([details.allKeys containsObject:@"name"]) {
                            WGProfile.currentUser.work = [details objectForKey:@"name"];
                        }
                    }
                }
            }
        }
        
        NSDictionary *userResponse = (NSDictionary *) fbGraphUser;
        if ([[userResponse allKeys] containsObject:@"gender"]) {
            WGProfile.currentUser.gender = [WGUser genderFromName:[userResponse objectForKey:@"gender"]];
        }
        
        if (!_alertShown && !self.fetchingProfilePictures) {
            [self loginUserAsynchronous];
        }
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

- (void) loginViewShowingLoggedOutUser:(FBLoginView *)loginView {
    _alertShown = NO;
}

- (void)logout {
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

- (void) loginUserAsynchronous {
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
        [strongSelf navigate];
    }];
}

-(void) navigate {
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    currentInstallation[@"api_version"] = API_VERSION;
    [currentInstallation setObject:@2.0f forKey:@"api_version_num"];
    currentInstallation[@"wigo_id"] = WGProfile.currentUser.id;
    [currentInstallation saveInBackground];
    
    if (!_pushed) {
        _pushed = YES;
        if (WGProfile.currentUser.group.locked.boolValue) {
            if (WGProfile.currentUser.findReferrer) {
                [self presentViewController:[ReferalViewController new] animated:YES completion:nil];
                NSDateFormatter *dateFormatter = [NSDateFormatter new];
                [dateFormatter setDateFormat:@"yyyy-d-MM HH:mm:ss"];
                [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
                WGProfile.currentUser.findReferrer = NO;
                [WGProfile.currentUser save:^(BOOL success, NSError *error) {}];
            }
            [self.navigationController setNavigationBarHidden:YES animated:NO];
            [self.navigationController pushViewController:[WaitListViewController new] animated:YES];
        } else {
            [self dismissViewControllerAnimated:NO  completion:nil];
        }
        
    }
    
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
    [self navigate];
}

-(void) presentPushNotification {
    UIVisualEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    self.blurredView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    self.blurredView.frame = self.view.bounds;
    [self.view addSubview:self.blurredView];
    [self presentAlertView];
}

- (void)presentAlertView {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                        message:@"Wigo works best when you enable push notifications so we can let you know when the next party is happening."
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