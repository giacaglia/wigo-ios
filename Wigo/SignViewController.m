//
//  SignUpViewController.m
//  webPays
//
//  Created by Giuliano Giacaglia on 9/26/13.
//  Copyright (c) 2013 Giuliano Giacaglia. All rights reserved.
//

#import "SignViewController.h"
#import "MainViewController.h"
#import "Globals.h"

#import <Crashlytics/Crashlytics.h>


@interface SignViewController ()
// UI
@property UIView *facebookConnectView;

@property BOOL pushed;
@property FBLoginView *loginView;
@property NSString * profilePicturesAlbumId;
@property NSString *profilePic;

@property NSString *accessToken;
@property NSString *fbID;

@property UIAlertView * alert;
@property BOOL alertShown;
@property BOOL fetchingProfilePictures;
@end

@implementation SignViewController


- (id)init
{
    self = [super init];
    if (self) {
        _fetchingProfilePictures = NO;
        self.view.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeAlertToNotShown) name:@"changeAlertToNotShown" object:nil];
    _alertShown = NO;
    _fetchingProfilePictures = NO;
    _pushed = NO;
    
    [self initializeLogo];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _alertShown = NO;
    _fetchingProfilePictures = NO;
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [self getFacebookTokensAndLoginORSignUp];
}

- (void) changeAlertToNotShown {
    _alertShown = NO;
    _fetchingProfilePictures = NO;
}

- (void) getFacebookTokensAndLoginORSignUp {
    _fbID = StringOrEmpty([[NSUserDefaults standardUserDefaults] objectForKey:@"facebook_id"]);
    _accessToken = StringOrEmpty([[NSUserDefaults standardUserDefaults] objectForKey:@"accessToken"]);

    NSString *key = [[NSUserDefaults standardUserDefaults] objectForKey:@"key"];
    if (key) {
        User *user = [[User alloc] initWithDictionary:@{@"key": key}];
        [Profile setUser:user];
        [self loadMainViewController];
    }
    else {
        if ([_fbID isEqualToString:@""] || [_accessToken isEqualToString:@""]) {
            [self fetchTokensFromFacebook];
        }
        else {
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
    _loginView = [[FBLoginView alloc] initWithReadPermissions: @[@"user_friends", @"user_photos"]];
    _loginView.loginBehavior = FBSessionLoginBehaviorUseSystemAccountIfPresent;
    _loginView.delegate = self;
    _loginView.frame = CGRectMake(0, self.view.frame.size.height - 127, 253, 36);
    _loginView.frame = CGRectOffset(_loginView.frame, (self.view.center.x - (_loginView.frame.size.width / 2)), 5);
    _loginView.backgroundColor = [UIColor whiteColor];
    UIImageView *connectFacebookImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"connectFacebook"]];
    connectFacebookImageView.backgroundColor = [UIColor whiteColor];
    connectFacebookImageView.frame = CGRectMake(0, 0, 253, 36);
    [_loginView addSubview:connectFacebookImageView];
    [_loginView bringSubviewToFront:connectFacebookImageView];
    [self.view addSubview:_loginView];
    
    UILabel *dontWorryLabel = [[UILabel alloc] init];
    dontWorryLabel.frame = CGRectMake(0, self.view.frame.size.height - 125 + 34, self.view.frame.size.width, 30);
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
                                  _fetchingProfilePictures = NO;
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
                                  _fetchingProfilePictures = NO;
                                  NSMutableArray *profilePictures = [[NSMutableArray alloc] initWithCapacity:0];
                                  [profilePictures addObject:_profilePic];
                                  [self saveProfilePictures:profilePictures];
                              }
                          }];

}

- (void) get3ProfilePictures {
    NSMutableArray *profilePictures = [[NSMutableArray alloc] initWithCapacity:0];
    [WiGoSpinnerView addDancingGToCenterView:self.view];
    [FBRequestConnection startWithGraphPath:[NSString stringWithFormat:@"/%@/photos", _profilePicturesAlbumId]
                                 parameters:nil
                                 HTTPMethod:@"GET"
                          completionHandler:^(
                                              FBRequestConnection *connection,
                                              id result,
                                              NSError *error
                                              ) {
                              if (error) {
                                  _fetchingProfilePictures = NO;
                              }
                              FBGraphObject *resultObject = [result objectForKey:@"data"];
                              for (FBGraphObject *photoRepresentation in resultObject) {
                                  FBGraphObject *images = [photoRepresentation objectForKey:@"images"];
                                  FBGraphObject *newPhoto = [self getFirstFacebookPhotoGreaterThanSixHundred:images];
                                  if (newPhoto != nil) {
                                      [profilePictures addObject:[newPhoto objectForKey:@"source"]];
                                      if ([profilePictures count] == 1) {
                                          [[Profile user] setValue:[profilePictures objectAtIndex:0] forKey:@"image"];
                                      }
                                      if ([profilePictures count] >= 3) {
                                          break;
                                      }
                                  }
                              }
                              if ([profilePictures count] == 0) {
                                  [profilePictures addObject:@"https://api.wigo.us/static/img/wigo_profile_gray.png"];
                              }
                              [self saveProfilePictures:profilePictures];
                          }];
}

- (void)saveProfilePictures:(NSMutableArray *)profilePictures {
    [[Profile user] setImagesURL:profilePictures];
    [WiGoSpinnerView removeDancingGFromCenterView:self.view];
    if (!_pushed) {
        _pushed = YES;
        _fetchingProfilePictures = NO;
        self.signUpViewController = [[SignUpViewController alloc] init];
        [self.navigationController pushViewController:self.signUpViewController animated:YES];
    }
}

- (FBGraphObject *)getFirstFacebookPhotoGreaterThanSixHundred:(FBGraphObject *)photoArray {
    int minHeight = 0;
    FBGraphObject *returnedPhoto;
    for (FBGraphObject *fbPhoto in photoArray) {
        int heightPhoto = [[fbPhoto objectForKey:@"height"] intValue];
        if (heightPhoto > 600) {
            if (minHeight == 0) {
                returnedPhoto = fbPhoto;
                minHeight = heightPhoto;
            }
            else if (minHeight > heightPhoto) {
                returnedPhoto = fbPhoto;
                minHeight = heightPhoto;
            }
        }
    }
    
    // If the photo was fetched then returned it else return biggest res photo
    if (minHeight > 0) {
        return returnedPhoto;
    }
    else {
        int maxHeight = 0;
        for (FBGraphObject *fbPhoto in photoArray) {
            int heightPhoto = [[fbPhoto objectForKey:@"height"] intValue];
            if (heightPhoto > maxHeight) {
                returnedPhoto = fbPhoto;
                maxHeight = heightPhoto;
            }
        }
        return returnedPhoto;
    }
}

#pragma mark - UIAlertView Methods

- (void)showErrorLoginFailed {
    _alert = [[UIAlertView alloc] initWithTitle:@"Not so fast!"
                                        message:@"WiGo requires Facebook login. Open Settings > Facebook and make sure WiGo is turned on."
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
        [[Profile user] setFirstName:fbGraphUser[@"first_name"]];
        [[Profile user] setLastName:fbGraphUser[@"last_name"]];
        NSDictionary *userResponse = (NSDictionary *)fbGraphUser;
        if ([[userResponse allKeys] containsObject:@"gender"]) {
            [[Profile user] setObject:[userResponse objectForKey:@"gender"] forKey:@"gender"];
        }
        
        if (!_alertShown && !_fetchingProfilePictures) {
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

    }
    else if ([[[error userInfo] allKeys] containsObject:@"NSLocalizedFailureReason"]) {
        if ([[[error userInfo] objectForKey:@"NSLocalizedFailureReason"] isEqualToString:@"com.facebook.sdk:SystemLoginDisallowedWithoutError"])
            [self showErrorLoginFailed];
    }
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
    // Set object FbID and access token to be saved locally
    [[NSUserDefaults standardUserDefaults] setObject:_fbID forKey: @"facebook_id"];
    [[NSUserDefaults standardUserDefaults] setObject:_accessToken forKey: @"accessToken"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [Crashlytics setUserIdentifier:_fbID];
    
    User *profileUser = [Profile user];
    [profileUser setObject:_fbID forKey:@"facebook_id"];
    [profileUser setAccessToken:_accessToken];
    [WiGoSpinnerView addDancingGToCenterView:self.view];
    [profileUser loginWithHandler:^(NSDictionary *jsonResponse, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [WiGoSpinnerView removeDancingGFromCenterView:self.view];
            [self handleJsonResponse:jsonResponse andError:error];
        });
    }];
}

- (void)handleJsonResponse:(NSDictionary *)jsonResponse andError:(NSError *)error {
    if ([[jsonResponse allKeys] containsObject:@"status"] &&
        [[jsonResponse objectForKey:@"status"] isEqualToString:@"error"] &&
        ![[jsonResponse objectForKey:@"code"] isEqualToString:@"does_not_exist"] ) { //If it exists but other error shows up.
        [self showBummerError];
    }
    else if ([[jsonResponse allKeys] containsObject:@"status"] &&
             [[jsonResponse objectForKey:@"code"] isEqualToString:@"does_not_exist"]) {
        _fetchingProfilePictures = YES;
        [self fetchTokensFromFacebook];
        [self fetchProfilePicturesAlbumFacebook];
    }
    else if ([[error domain] isEqualToString:NSURLErrorDomain]) {
        [self showErrorNoConnection];
    }
    else if (!jsonResponse && [[error domain] isEqualToString:NSCocoaErrorDomain]) {
        [self showBummerError];
    }
    else if (![[Profile user] emailValidated]) {
        if (!_pushed) {
            _pushed = YES;
            self.emailConfirmationViewController = [[EmailConfirmationViewController alloc] init];
            [self.navigationController pushViewController:self.emailConfirmationViewController animated:YES];
        }
    }
    else {
        if (!_pushed) {
            _pushed = YES;
            if ([[Profile user] isGroupLocked]) {
                self.lockScreenViewController = [[LockScreenViewController alloc] init];
                [self.navigationController pushViewController:self.lockScreenViewController animated:NO];
            }
            else {
                [self loadMainViewController];
            }
            
        }
    }
}

- (void)fetchUserInfo {
    [WiGoSpinnerView addDancingGToCenterView:self.view];
    [Network queryAsynchronousAPI:@"users/me" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [WiGoSpinnerView removeDancingGFromCenterView:self.view];
            [self handleJsonResponse:jsonResponse andError:error];
        });
    }];
}


- (void)loadMainViewController {
    if ([[[Profile user] numEvents] intValue] >= 3) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"changeTabs" object:self];
    }
    [self dismissViewControllerAnimated:YES  completion:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"loadViewAfterSigningUser" object:self];
}




@end