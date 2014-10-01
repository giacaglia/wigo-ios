//
//  FacebookImagesViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 7/7/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "FacebookImagesViewController.h"
#import "Globals.h"
#import "GKImagePicker.h"
#import "GKImageCropViewController.h"
#import "ErrorViewController.h"

@interface FacebookImagesViewController ()<GKImageCropControllerDelegate>
@property NSString *profilePicturesAlbumId;
@property NSMutableArray *profilePicturesURL;
@property UIScrollView *scrollView;
@property int startingYPosition;
@end

NSString *urlOfSelectedImage;


@implementation FacebookImagesViewController

- (id)init {
    self = [super init];
    if (self) {
        self.view.backgroundColor = [UIColor whiteColor];
    }
    return self;
}


- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [EventAnalytics tagEvent:@"Facebook Images View"];
    [self initializeScrollView];
    [self loadImages];
}



- (void)loadImages {
    [FBSession openActiveSessionWithReadPermissions:@[@"user_photos"]
                                       allowLoginUI:YES
                                  completionHandler:^(FBSession *session,
                                                      FBSessionState state,
                                                      NSError *error) {
                                      if (error) {
                                          if (![self gaveUserPermission:[error userInfo]]) [self requestReadPermissions];
                                          else [self showErrorNotAccess];
                                      }
                                      else if (session.isOpen) {
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
                              if (error) {
                                  if (![self gaveUserPermission:[error userInfo]]) [self requestReadPermissions];
                                  else [self showErrorNotAccess];
                              }
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

- (void)requestReadPermissions {
    [FBSession.activeSession requestNewReadPermissions:@[@"user_photos"]
                                     completionHandler:^(FBSession *session, NSError *error) {
                                        if (!error) {
                                            if ([FBSession.activeSession.permissions
                                                 indexOfObject:@"user_photos"] == NSNotFound){
                                                [self showErrorNotAccess];
                                            } else {
                                                [self loadImages];
                                            }
                                            
                                        } else {
                                            [self showErrorNotAccess];
                                        }
    }];
}

- (BOOL)gaveUserPermission:(NSDictionary *)userInfo {
    if ([[userInfo allKeys] containsObject:@"com.facebook.sdk:HTTPStatusCode"] && [[userInfo allKeys] containsObject:@"com.facebook.sdk:ParsedJSONResponseKey"]) {
        if ([[userInfo objectForKey:@"com.facebook.sdk:HTTPStatusCode"] isEqualToNumber:@403] &&
            [[[userInfo objectForKey:@"com.facebook.sdk:ParsedJSONResponseKey"] objectForKey:@"code"] isEqualToNumber:@403]) {
            return NO;
        }
        return YES;
        
    }
    return YES;
}

- (void)showErrorNotAccess {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"Could not load your Facebook Photos"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
}

- (void) getProfilePictures {
    [WiGoSpinnerView addDancingGToCenterView:self.view];
    _profilePicturesURL = [[NSMutableArray alloc] initWithCapacity:0];
    [FBRequestConnection startWithGraphPath:[NSString stringWithFormat:@"/%@/photos", _profilePicturesAlbumId]
                                 parameters:nil
                                 HTTPMethod:@"GET"
                          completionHandler:^(
                                              FBRequestConnection *connection,
                                              id result,
                                              NSError *error
                                              ) {
                              [WiGoSpinnerView removeDancingGFromCenterView:self.view];
                              if (!error) {
                                  FBGraphObject *resultObject = [result objectForKey:@"data"];
                                  for (FBGraphObject *photoRepresentation in resultObject) {
                                      [_profilePicturesURL addObject:[photoRepresentation objectForKey:@"source"]];
                                      _startingYPosition = 0;
                                  }
                                  [self addImagesFromURLArray];
                              }

    }];
}



- (void) initializeScrollView {
    self.automaticallyAdjustsScrollViewInsets = NO;
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64)];
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
        __weak UIImageView *weakProfileImgView = imgView;
        [imgView setImageWithURL:[NSURL URLWithString:pictureURL]
                       completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(choseImageView:)];
                [weakProfileImgView addGestureRecognizer:tap];
            });
        }];
        imgView.frame = CGRectMake(positionX, _startingYPosition, sizeOfEachImage, sizeOfEachImage);
        imgView.userInteractionEnabled = YES;
        imgView.tag = i;
        positionX += sizeOfEachImage + distanceOfEachImage;
        [_scrollView addSubview:imgView];
        if (i%(NImages) == (NImages -1)) { //If it's the last image in the row
            _startingYPosition += sizeOfEachImage + 5; // 5 is the distance of the images on the bottom
            positionX = 0;
        }
       
    }
    _startingYPosition += sizeOfEachImage + 5;
    _scrollView.contentSize = CGSizeMake(self.view.frame.size.width, _startingYPosition);
}

- (void)choseImageView:(UITapGestureRecognizer*)sender {
    UIImageView *imageViewSender = (UIImageView *)sender.view;
    urlOfSelectedImage = [_profilePicturesURL objectAtIndex:imageViewSender.tag];
//    User *profileUser = [Profile user];
//    [profileUser addImageURL:urlOfSelectedImage];
//    [profileUser save];
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"updatePhotos" object:nil];
//    [self.navigationController popViewControllerAnimated:YES];

    GKImageCropViewController *cropViewController = [[GKImageCropViewController alloc] init];
    cropViewController.sourceImage = imageViewSender.image;
    cropViewController.delegate = self;
    cropViewController.resizeableCropArea = NO;
    cropViewController.cropSize = CGSizeMake(280, 280);
    [self presentViewController:cropViewController animated:YES completion:^(void){}];

}

#pragma GKImagePickerDelegate

- (void)imageCropController:(GKImageCropViewController *)imageCropController didFinishWithCroppedImage:(UIImage *)croppedImage{
//    [self dismissViewControllerAnimated:YES completion:^(void) {}];
}

- (void)didFinishWithCroppedArea:(CGRect)croppedArea {

    User *profileUser = [Profile user];
//    NSArray *imagesArea = [NSMutableArray arrayWithArray:[profileUser imagesArea]];
    [profileUser addImageWithURL:urlOfSelectedImage andArea:croppedArea];
//    [profileUser addImageURL:urlOfSelectedImage];
    [profileUser save];
    [self dismissViewControllerAnimated:YES completion:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updatePhotos" object:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
