//
//  SignUpViewController.m
//  webPays
//
//  Created by Giuliano Giacaglia on 9/26/13.
//  Copyright (c) 2013 Giuliano Giacaglia. All rights reserved.
//

#import "SignViewController.h"
#import "FontProperties.h"
#import "MainViewController.h"

#import "Profile.h"
#import "User.h"
#import "Query.h"

#import "WiGoSpinnerView.h"

#if !defined(StringOrEmpty)
#define StringOrEmpty(A)  ({ __typeof__(A) __a = (A); __a ? __a : @""; })
#endif

@interface SignViewController ()
@property BOOL pushed;
@property FBLoginView *loginView;
@property NSString * profilePicturesAlbumId;

@property NSString *email;
@property NSString *accessToken;
@property NSString *fbID;

@property BOOL userDidntTryToSignUp;
@property BOOL userEmailAlreadySent;

@end

@implementation SignViewController


- (id)init
{
    self = [super init];
    if (self) {
        _userDidntTryToSignUp = YES;
        _userEmailAlreadySent = NO;
        self.view.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _pushed = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [self getFacebookTokensAndLoginORSignUp];
}

- (void) getFacebookTokensAndLoginORSignUp {
    _fbID = StringOrEmpty([[NSUserDefaults standardUserDefaults] objectForKey:@"facebook_id"]);
    _email = StringOrEmpty([[NSUserDefaults standardUserDefaults] objectForKey:@"email"]);
    _accessToken = StringOrEmpty([[NSUserDefaults standardUserDefaults] objectForKey:@"accessToken"]);
    if ([_fbID isEqualToString:@""] || [_email isEqualToString:@""] || [_accessToken isEqualToString:@""]) {
        [self fetchTokensFromFacebook];
    }
    else {
        [self logInUser];
    }
}

- (void) fetchTokensFromFacebook {
    [self initializeLogo];
    [self initializeFacebookSignButton];
}

- (void) logInUser {
    if (_userDidntTryToSignUp) {
        _userDidntTryToSignUp = NO;

        [[NSUserDefaults standardUserDefaults] setObject:_fbID forKey: @"facebook_id"];
        [[NSUserDefaults standardUserDefaults] setObject:_email forKey: @"email"];
        [[NSUserDefaults standardUserDefaults] setObject:_accessToken forKey: @"accessToken"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        User *profileUser = [Profile user];
        [profileUser setObject:_fbID forKey:@"facebook_id"];
        [profileUser setEmail:_email];
        [profileUser setAccessToken:_accessToken];
        [Profile setUser:profileUser];
        [WiGoSpinnerView showOrangeSpinnerAddedTo:self.view];
        NSString *response = [profileUser login];
        [WiGoSpinnerView hideSpinnerForView:self.view];
        [Profile setUser:profileUser];
        
        
        if ([response isEqualToString:@"error"]) {
            [self fetchTokensFromFacebook];
            [self fetchProfilePicturesAlbumFacebook];
        }
        else if ([response isEqualToString:@"email_not_validated"]) {
            _userEmailAlreadySent = YES;
            [self fetchTokensFromFacebook];
            [self fetchProfilePicturesAlbumFacebook];
        }
        else {
            [self dismissViewControllerAnimated:YES  completion:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"loadViewAfterSigningUser" object:self];
        }
       
    }
}


- (void)initializeLogo {
    UIImageView *logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"wigoLogo"]];
    logoImageView.frame = CGRectMake(self.view.frame.size.width/2 - 91, self.view.frame.size.height/2 - 52 - 40, 182, 104);
    [self.view addSubview:logoImageView];
}

- (void)initializeFacebookSignButton {
    _loginView = [[FBLoginView alloc] initWithReadPermissions: @[@"public_profile", @"email", @"user_friends", @"user_photos"]];
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
    dontWorryLabel.font = [UIFont fontWithName:@"Whitney-Medium" size:13.0f];
    dontWorryLabel.textColor = RGB(51, 102, 154);
    dontWorryLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:dontWorryLabel];
}


#pragma mark - Log In Via FB

- (void) loginViewFetchedUserInfo:(FBLoginView *)loginView user:(id<FBGraphUser>)fbGraphUser {
//    NSLog(@"fetched");
    if (!_pushed) {
        _pushed = YES;
        _fbID = [fbGraphUser objectID];
        _email = fbGraphUser[@"email"];
        _accessToken = [FBSession activeSession].accessTokenData.accessToken;
        User *profileUser = [Profile user];
        [profileUser setFirstName:fbGraphUser[@"first_name"]];
        [profileUser setLastName:fbGraphUser[@"last_name"]];
        [Profile setUser:profileUser];
        
        [self logInUser];
    }
}

#pragma mark - Sign Up Process

- (BOOL) wasUserAbleToSignIn:(NSString *)response {
    if ([response isEqualToString:@"error"]) {
        return NO;
    }
    return YES;
}

- (void) fetchProfilePicturesAlbumFacebook {
    [FBRequestConnection startWithGraphPath:@"/me/albums"
                                 parameters:nil
                                 HTTPMethod:@"GET"
                          completionHandler:^(
                                              FBRequestConnection *connection,
                                              id result,
                                              NSError *error
                                              ) {
                              FBGraphObject *resultObject = (FBGraphObject *)[result objectForKey:@"data"];
                              for (FBGraphObject *album in resultObject) {
                                  if ([[album objectForKey:@"name"] isEqualToString:@"Profile Pictures"]) {
                                      _profilePicturesAlbumId = (NSString *)[album objectForKey:@"id"];
                                      [self get3ProfilePictures];
                                      break;
                                  }
                              }
                          }];

}

- (void) get3ProfilePictures {
    NSMutableArray *profilePictures = [[NSMutableArray alloc] initWithCapacity:0];
    [WiGoSpinnerView showOrangeSpinnerAddedTo:self.view];
    [FBRequestConnection startWithGraphPath:[NSString stringWithFormat:@"/%@/photos", _profilePicturesAlbumId]
                                 parameters:nil
                                 HTTPMethod:@"GET"
                          completionHandler:^(
                                              FBRequestConnection *connection,
                                              id result,
                                              NSError *error
                                              ) {
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
                              [WiGoSpinnerView hideSpinnerForView:self.view];
                              User *profileUser = [Profile user];
                              [profileUser setImagesURL:profilePictures];
                              [Profile setUser:profileUser];
                              if (_userEmailAlreadySent) {
                                  self.emailConfirmationViewController = [[EmailConfirmationViewController alloc] init];
                                  [self.navigationController pushViewController:self.emailConfirmationViewController animated:YES];
                              }
                              else {
                                  self.signUpViewController = [[SignUpViewController alloc] init];
                                  [self.navigationController pushViewController:self.signUpViewController animated:YES];
                              }
                          }];
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
    return returnedPhoto;
}

@end