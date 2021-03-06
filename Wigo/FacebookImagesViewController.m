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
#import "FacebookHelper.h"
#import "UIButtonAligned.h"

@interface FacebookImagesViewController ()<GKImageCropControllerDelegate>
@property NSString *profilePicturesAlbumId;
@property UIScrollView *scrollView;
@property int startingYPosition;
@end

NSDictionary *chosenPhoto;
//NSString *albumID;

@implementation FacebookImagesViewController


- (id)initWithAlbumID:(NSString *)newAlbumID {
    self = [super init];
    if (self) {
        _profilePicturesAlbumId = newAlbumID;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    self.title = @"Select Photo";
    [self initializeBackBarButton];
    [self initializeScrollView];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [WGAnalytics tagEvent:@"Facebook Images View"];
    [WGAnalytics tagView:@"facebook_images" withTargetUser:nil];
}

- (void)initializeBackBarButton {
    UIButtonAligned *barBt = [[UIButtonAligned alloc] initWithFrame:CGRectMake(0, 0, 65, 44) andType:@0];
    [barBt setImage:[UIImage imageNamed:@"backIcon"] forState:UIControlStateNormal];
    [barBt setTitle:@" Back" forState:UIControlStateNormal];
    [barBt setTitleColor:[FontProperties getBlueColor] forState:UIControlStateNormal];
    barBt.titleLabel.font = [FontProperties getSubtitleFont];
    [barBt addTarget:self action: @selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barItem =  [[UIBarButtonItem alloc] init];
    [barItem setCustomView:barBt];
    self.navigationItem.leftBarButtonItem = barItem;
}

- (void)goBack {
    [self.navigationController popViewControllerAnimated:YES];
}


- (void)loadImages {
    if ([FBSDKAccessToken currentAccessToken]) {
        [self fetchProfilePicturesAlbumFacebook];
        return;
    }
    
    FBSDKLoginManager *loginManager = [[FBSDKLoginManager alloc] init];
    [loginManager logInWithReadPermissions:@[@"user_photos"] handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
        if (error) {
          if (![self gaveUserPermission:[error userInfo]]) [self requestReadPermissions];
          else [self showErrorNotAccess];
          return;
        }
    }];
}

- (void) fetchProfilePicturesAlbumFacebook {
    [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me/albums" parameters:nil]
     startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        if (error) {
            if (![self gaveUserPermission:[error userInfo]]) [self requestReadPermissions];
            else [self showErrorNotAccess];
            return;
        }
        FBGraphObject *resultObject = (FBGraphObject *)[result objectForKey:@"data"];
        for (FBGraphObject *album in resultObject) {
            if ([[album objectForKey:@"name"] isEqualToString:@"Profile Pictures"]) {
                [self getProfilePictures];
                break;
            }
        }
    }];
    
}

- (void)requestReadPermissions {
    FBSDKLoginManager *loginManager = [[FBSDKLoginManager alloc] init];
    [loginManager logInWithReadPermissions:@[@"user_photos"] handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
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
    [WGSpinnerView addDancingGToCenterView:self.view];
    self.profilePicturesURL = [NSMutableArray new];
    self.imagesArray = [NSMutableArray new];
    NSString *graphPath = [NSString stringWithFormat:@"/%@/photos", _profilePicturesAlbumId];
    [[[FBSDKGraphRequest alloc] initWithGraphPath:graphPath
                                       parameters:nil]
     startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        [WGSpinnerView removeDancingGFromCenterView:self.view];
        if (!error) {
            FBGraphObject *resultObject = result[@"data"];
            for (FBGraphObject *photoRepresentation in resultObject) {
                FBGraphObject *images = [photoRepresentation objectForKey:@"images"];
                FBGraphObject *newPhoto = [FacebookHelper getFirstFacebookPhotoGreaterThanX:600 inPhotoArray:images];
                FBGraphObject *smallPhoto = [FacebookHelper getFirstFacebookPhotoGreaterThanX:200 inPhotoArray:images];
                if (newPhoto) {
                    NSDictionary *newImage =
                        @{@"url": [newPhoto objectForKey:@"source"],
                          @"small": [smallPhoto objectForKey:@"source"],
                          @"id": [photoRepresentation objectForKey:@"id"],
                          @"type": @"facebook"
                          };
                    [self.profilePicturesURL addObject:[newPhoto objectForKey:@"source"]];
                    [self.imagesArray addObject:newImage];
                    _startingYPosition = 0;
                }
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
    [self loadImages];
}


- (void)addImagesFromURLArray {
    int NImages = 3;
    int distanceOfEachImage = 4;
    int totalDistanceOfAllImages = distanceOfEachImage * (NImages - 1); // 10 pts is the distance of each image
    int sizeOfEachImage = self.view.frame.size.width - totalDistanceOfAllImages; // 10 pts on the extreme left and extreme right
    sizeOfEachImage /= NImages;
    int positionX = 0;
    for (int i = 0; i < self.profilePicturesURL.count; i++) {
        NSString *pictureURL = [self.profilePicturesURL objectAtIndex:i];

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
    NSDictionary *newImage = [self.imagesArray objectAtIndex:imageViewSender.tag];
    chosenPhoto = newImage;
    GKImageCropViewController *cropViewController = [[GKImageCropViewController alloc] init];
    cropViewController.sourceImage = imageViewSender.image;
    cropViewController.delegate = self;
    cropViewController.resizeableCropArea = NO;
    cropViewController.cropSize = CGSizeMake(280, 280);
    [self presentViewController:cropViewController animated:YES completion:^(void){}];

}

#pragma GKImagePickerDelegate

- (void)imageCropController:(GKImageCropViewController *)imageCropController didFinishWithCroppedImage:(UIImage *)croppedImage{
    [self dismissViewControllerAnimated:YES completion:^(void) {}];
}

- (void)didFinishWithCroppedArea:(CGRect)croppedArea {
    
    NSMutableDictionary *imageDictionary = [NSMutableDictionary dictionaryWithDictionary:chosenPhoto];
    [imageDictionary addEntriesFromDictionary:@{@"crop":
                                                @{@"x": @(MAX(0,(int)roundf(croppedArea.origin.x))),
                                                @"y": @(MAX((int)roundf(croppedArea.origin.y),0)),
                                                @"width": @((int)roundf(croppedArea.size.width)),
                                                @"height": @((int)roundf(croppedArea.size.height))}
                                                }];
    
    [WGProfile.currentUser addImageDictionary:imageDictionary];
    [WGProfile.currentUser save:^(BOOL success, NSError *error) {
        if (error) {
            [[WGError sharedInstance] logError:error forAction:WGActionSave];
            return;
        }
        [self dismissViewControllerAnimated:YES completion:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"updatePhotos" object:nil];
        [self.navigationController popToRootViewControllerAnimated:YES];
    }];
}

@end
