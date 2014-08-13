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


#if !defined(StringOrEmpty)
#define StringOrEmpty(A)  ({ __typeof__(A) __a = (A); __a ? __a : @""; })
#endif

@interface SignViewController ()
// UI
@property UIView *facebookConnectView;

@property BOOL pushed;
@property FBLoginView *loginView;
@property NSString * profilePicturesAlbumId;
@property NSString *profilePic;

@property NSString *accessToken;
@property NSString *fbID;

@property BOOL userEmailAlreadySent;

@property UIAlertView * alert;
@property BOOL alertShown;
@property BOOL fetchingProfilePictures;
@end

@implementation SignViewController


- (id)init
{
    self = [super init];
    if (self) {
        _userEmailAlreadySent = NO;
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

    if ([_fbID isEqualToString:@""] || [_accessToken isEqualToString:@""]) {
        [self fetchTokensFromFacebook];
    }
    else {
        [self loginUserAsynchronous];
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
    logoImageView.frame = CGRectMake(self.view.frame.size.width/2 - 91, self.view.frame.size.height/2 - 52 - 40, 182, 104);
    [_facebookConnectView addSubview:logoImageView];
}

- (void)initializeFacebookSignButton {
    _loginView = [[FBLoginView alloc] initWithReadPermissions: @[@"public_profile", @"user_friends", @"user_photos"]];
    _loginView.delegate = self;
    _loginView.frame = CGRectMake(0, self.view.frame.size.height - 125, 245, 34);
    _loginView.frame = CGRectOffset(_loginView.frame, (self.view.center.x - (_loginView.frame.size.width / 2)), 5);
    _loginView.backgroundColor = [UIColor whiteColor];
    UIImageView *connectFacebookImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"connectFacebook"]];
    connectFacebookImageView.backgroundColor = [UIColor whiteColor];
    connectFacebookImageView.frame = CGRectMake(0, 0, 245, 34);
    [_loginView addSubview:connectFacebookImageView];
    [_loginView bringSubviewToFront:connectFacebookImageView];
    [self.view addSubview:_loginView];
    
    UILabel *dontWorryLabel = [[UILabel alloc] init];
    dontWorryLabel.frame = CGRectMake(0, self.view.frame.size.height - 125 + 34, self.view.frame.size.width, 30);
    dontWorryLabel.text = @"Don't worry, we'll never post on your behalf.";
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
    [WiGoSpinnerView removeDancingGFromCenterView:self.view];
    User *profileUser = [Profile user];
    [profileUser setImagesURL:profilePictures];
    if (_userEmailAlreadySent) {
        if (!_pushed) {
            _pushed = YES;
            _fetchingProfilePictures = NO;
            self.emailConfirmationViewController = [[EmailConfirmationViewController alloc] init];
            [self.navigationController pushViewController:self.emailConfirmationViewController animated:YES];
        }
    }
    else {
        if (!_pushed) {
            _pushed = YES;
            _fetchingProfilePictures = NO;
            self.signUpViewController = [[SignUpViewController alloc] init];
            [self.navigationController pushViewController:self.signUpViewController animated:YES];
        }
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

#pragma mark - Facebook Delegate Methods

- (void) loginViewFetchedUserInfo:(FBLoginView *)loginView user:(id<FBGraphUser>)fbGraphUser {
    if (!_pushed) {
        _fbID = [fbGraphUser objectID];
        _profilePic = [fbGraphUser link];
        _accessToken = [FBSession activeSession].accessTokenData.accessToken;
        User *profileUser = [Profile user];
        [profileUser setFirstName:fbGraphUser[@"first_name"]];
        [profileUser setLastName:fbGraphUser[@"last_name"]];
        
        if (!_alertShown && !_fetchingProfilePictures) {
            [self loginUserAsynchronous];
        }
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
            if ([[jsonResponse allKeys] containsObject:@"status"]) {
                if ([[jsonResponse objectForKey:@"status"] isEqualToString:@"error"]){
                    _alertShown = YES;
                    _alert = [[UIAlertView alloc ] initWithTitle:@"Error"
                                                         message:@"An unexpected error happened. Please try again later"
                                                        delegate:self
                                               cancelButtonTitle:@"Ok"
                                               otherButtonTitles: nil];
                    [_alert show];
                }
            }
            
            if ([error domain] == NSURLErrorDomain) {
                if (!_alertShown) {
                    _alertShown = YES;
                    _alert = [[UIAlertView alloc ] initWithTitle:@"Error"
                                                                     message:[error localizedDescription]
                                                                    delegate:self
                                                           cancelButtonTitle:@"Ok"
                                                           otherButtonTitles: nil];
                    [_alert show];
                }
                [self fetchTokensFromFacebook];
                _fetchingProfilePictures = YES;
                [self fetchProfilePicturesAlbumFacebook];
            }
            else if ([[error localizedDescription] isEqualToString:@"error"]) {
                [self fetchTokensFromFacebook];
                _fetchingProfilePictures = YES;
                [self fetchProfilePicturesAlbumFacebook];
            }
            else if (![profileUser emailValidated]) {
                _userEmailAlreadySent = YES;
                _fetchingProfilePictures = YES;
                [self fetchTokensFromFacebook];
                [self fetchProfilePicturesAlbumFacebook];
            }
            else {
                if (!_pushed) {
                    _pushed = YES;
                    if ([[Profile user] isGroupLocked]) {
                        self.lockScreenViewController = [[LockScreenViewController alloc] init];
                        [self.navigationController pushViewController:self.lockScreenViewController animated:NO];
                    }
                    else {
                        [self dismissViewControllerAnimated:YES  completion:nil];
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"loadViewAfterSigningUser" object:self];
                    }

                }
            }
        });
    }];
    
}


@end