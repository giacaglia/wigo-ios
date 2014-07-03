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

@end

@implementation SignViewController


- (id)init
{
    self = [super init];
    if (self) {
        self.view.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _pushed = NO;
    [self.parentViewController.navigationController setNavigationBarHidden:YES ];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self getFacebookTokensAndLoginORSignUp];
}

- (void) getFacebookTokensAndLoginORSignUp {
    _fbID = StringOrEmpty([[NSUserDefaults standardUserDefaults] objectForKey:@"fbID"]);
    _email = StringOrEmpty([[NSUserDefaults standardUserDefaults] objectForKey:@"email"]);
    _accessToken = StringOrEmpty([[NSUserDefaults standardUserDefaults] objectForKey:@"accessToken"]);
    if ([_fbID isEqualToString:@""] || [_email isEqualToString:@""] || [_accessToken isEqualToString:@""]) {
        [self fetchTokensFromFacebook];
    }
    else {
        [self loginOrSignUpWithFacebookTokens];
    }
}

- (void) fetchTokensFromFacebook {
    [self initializeLogo];
    [self initializeFacebookSignButton];
}

- (void) loginOrSignUpWithFacebookTokens {
    [[NSUserDefaults standardUserDefaults] setObject:_fbID forKey: @"fbID"];
    [[NSUserDefaults standardUserDefaults] setObject:_email forKey: @"email"];
    [[NSUserDefaults standardUserDefaults] setObject:_accessToken forKey: @"accessToken"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    User *userProfile = [Profile user];
    [userProfile setObject:_fbID forKey:@"fbID"];
    [userProfile setAccessToken:_accessToken];
    [Profile setUser:userProfile];
    NSString *response = [userProfile login];
    [Profile setUser:userProfile];
    
    BOOL userDidSignUpEver = [self didUserSignUp:response];
    if (userDidSignUpEver) {
        [self dismissViewControllerAnimated:YES  completion:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"loadViewAfterSigningUser" object:self];
    }
    else {
        // NEED TO REALLY SIGN UP!! MOVE TO OTHER SCREEN
        [self fetchTokensFromFacebook];
        [self fetchProfilePicturesAlbumFacebook];
    }
}




- (void)initializeLogo {

    UIImageView *logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"wigoLogo"]];
    logoImageView.frame = CGRectMake(self.view.frame.size.width/2 - 87, 100, 174, 83);
    [self.view addSubview:logoImageView];
    
    UILabel *bestWayLabel = [[UILabel alloc] init];
    bestWayLabel.frame = CGRectMake(self.view.frame.size.width/2 - 87, 183, 174, 30);
    bestWayLabel.text = @"THE BEST WAY TO GO OUT";
    bestWayLabel.font = [UIFont fontWithName:@"Whitney-MediumSC" size:13.0f];
    bestWayLabel.textColor = [UIColor grayColor];
    bestWayLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:bestWayLabel];
}

- (void)initializeFacebookSignButton {
    _loginView = [[FBLoginView alloc] initWithReadPermissions: @[@"public_profile", @"email", @"user_friends", @"user_photos"]];
    _loginView.delegate = self;
    _loginView.frame = CGRectMake(0, self.view.frame.size.height/2 + 100, 245, 34);
    _loginView.frame = CGRectOffset(_loginView.frame, (self.view.center.x - (_loginView.frame.size.width / 2)), 5);
    _loginView.backgroundColor = [UIColor whiteColor];
    
    UIImageView *connectFacebookImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"connectFacebook"]];
    connectFacebookImageView.backgroundColor = [UIColor whiteColor];
    connectFacebookImageView.frame = CGRectMake(0, 0, 245, 34);
    [_loginView addSubview:connectFacebookImageView];
    [_loginView bringSubviewToFront:connectFacebookImageView];
    
    [self.view addSubview:_loginView];
    
    UILabel *dontWorryLabel = [[UILabel alloc] init];
    dontWorryLabel.frame = CGRectMake(0, self.view.frame.size.height/2 + 100 + 34, self.view.frame.size.width, 30);
    dontWorryLabel.text = @"Don't worry, we'll never post on your behalf.";
    dontWorryLabel.font = [UIFont fontWithName:@"Whitney-Medium" size:13.0f];
    dontWorryLabel.textColor = RGB(51, 102, 154);
    dontWorryLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:dontWorryLabel];
}


#pragma mark - Log In Via FB

- (void) loginViewFetchedUserInfo:(FBLoginView *)loginView user:(id<FBGraphUser>)fbGraphUser {
    NSLog(@"Fetched Facebook tokens");
    if (!_pushed) {
        _pushed = YES;
        _fbID = [fbGraphUser objectID];
        _email = fbGraphUser[@"email"];
        _accessToken = [FBSession activeSession].accessTokenData.accessToken;
        
        [self loginOrSignUpWithFacebookTokens];
    }
}

#pragma mark - Sign Up Process

- (BOOL) didUserSignUp:(NSString *)response {
     return YES;
    if ([response isEqualToString:@"invalid_email"]) {
        NSLog(@"invalid email");
        return NO;
    }
    else if ([response isEqualToString:@"Error"]) {
        return NO;
    }
    User *profileUser = [Profile user];
    if (![profileUser emailValidated]) {
        return NO;
    }
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
                                          [[Profile user] setImages:profilePictures];
                                          [[NSNotificationCenter defaultCenter] postNotificationName:@"loadViewAfterSigningUser" object:self];
                                          NSLog(@"here");
                                          self.signUpViewController = [[SignUpViewController alloc] init];
                                          [self.navigationController pushViewController:self.signUpViewController animated:YES];
                                          break;
                                      }
                                  }
                              }
                              NSLog(@"here if not there");
                              User *profileUser = [Profile user];
                              [profileUser setImages:profilePictures];
                              [profileUser setEmailValidated:YES];
                              [Profile setUser:profileUser];
                              [profileUser save];
                              [[NSNotificationCenter defaultCenter] postNotificationName:@"loadViewAfterSigningUser" object:self];
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