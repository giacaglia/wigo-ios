//
//  FacebookImagesViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 7/7/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "FacebookImagesViewController.h"
#import "Globals.h"

@interface FacebookImagesViewController ()
@property NSString *profilePicturesAlbumId;
@property NSMutableArray *profilePicturesURL;
@property UIScrollView *scrollView;
@property int startingYPosition;
@end

@implementation FacebookImagesViewController


- (id)init {
    self = [super init];
    if (self) {
        self.view.backgroundColor = [UIColor whiteColor];
    }
    return self;
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // Do any additional setup after loading the view.
    [self initializeScrollView];
    [self loadImages];
}


- (void)loadImages {
    [FBSession openActiveSessionWithReadPermissions:@[@"public_profile", @"email", @"user_friends", @"user_photos"]
                                       allowLoginUI:YES
                                  completionHandler:^(FBSession *session,
                                                      FBSessionState state,
                                                      NSError *error) {
                                      if (error) {
                                          UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                                              message:error.localizedDescription
                                                                                             delegate:nil
                                                                                    cancelButtonTitle:@"OK"
                                                                                    otherButtonTitles:nil];
                                          [alertView show];
                                      } else if (session.isOpen) {
                                          [self fetchProfilePicturesAlbumFacebook];
                                      }
                                  }];
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
                                      [self getProfilePictures];
                                      break;
                                  }
                              }
                          }];
    
}

- (void) getProfilePictures {
    _profilePicturesURL = [[NSMutableArray alloc] initWithCapacity:0];
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
                                  NSLog(@"Image %@", photoRepresentation);
                                  [_profilePicturesURL addObject:[photoRepresentation objectForKey:@"source"]];
                                  _startingYPosition = 0;
                                  [self addImagesFromURLArray];
                              }
    }];
}



- (void) initializeScrollView {
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    _scrollView.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height);
    [self.view addSubview:_scrollView];
}


- (void)addImagesFromURLArray {
    int NImages = 3;
    int distanceOfEachImage = 4;
    int totalDistanceOfAllImages = distanceOfEachImage * (NImages - 1); // 10 pts is the distance of each image
    int sizeOfEachImage = self.view.frame.size.width - totalDistanceOfAllImages; // 10 pts on the extreme left and extreme right
    sizeOfEachImage /= NImages;
    int positionX = 0;
    for (int i = 0; i < [_profilePicturesURL count]; i++) {
        NSString *pictureURL = [_profilePicturesURL objectAtIndex:i];
        UIImageView *imgView = [[UIImageView alloc] init];
        imgView.contentMode = UIViewContentModeScaleAspectFill;
        imgView.clipsToBounds = YES;
        [imgView setImageWithURL:[NSURL URLWithString:pictureURL]];
        imgView.frame = CGRectMake(positionX, _startingYPosition, sizeOfEachImage, sizeOfEachImage);
        imgView.userInteractionEnabled = YES;
        imgView.tag = i;
        positionX += sizeOfEachImage + distanceOfEachImage;
        [_scrollView addSubview:imgView];
        if (i%(NImages) == (NImages -1)) { //If it's the last image in the row
            _startingYPosition += sizeOfEachImage + 5; // 5 is the distance of the images on the bottom
            positionX = 0;
        }
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(choseImageView:)];
        [imgView addGestureRecognizer:tap];
    }
    _startingYPosition += sizeOfEachImage + 5;
    _scrollView.contentSize = CGSizeMake(self.view.frame.size.width, _startingYPosition);
}

- (void)choseImageView:(UITapGestureRecognizer*)sender {
    UIImageView *imageViewSender = (UIImageView *)sender.view;
    NSString *urlOfSelectedImage = [_profilePicturesURL objectAtIndex:imageViewSender.tag];
    User *profileUser = [Profile user];
    [profileUser addImageURL:urlOfSelectedImage];
    [profileUser save];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updatePhotos" object:nil];
    [self.navigationController popViewControllerAnimated:YES];
}
@end
