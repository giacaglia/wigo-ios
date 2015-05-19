//
//  PhotoViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/13/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "PhotoViewController.h"
#import "Globals.h"
#import "GKImageCropViewController.h"

@interface PhotoViewController ()<GKImageCropControllerDelegate>
@property NSDictionary *image;
@property (nonatomic, strong) UIImageView *photoImageView;
@end

@implementation PhotoViewController

- (id)initWithImage:(NSDictionary *)image
{
    self = [super init];
    if (self) {
        _image = image;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.clearColor;

    self.bgView = [[UIView alloc] initWithFrame:self.view.frame];
    self.bgView.backgroundColor = RGBAlpha(255, 255, 255, 0.9f);
    self.bgView.alpha = 0.0f;
    [self.view addSubview:self.bgView];
   
    int yPosition = [UIScreen mainScreen].bounds.size.height - 4*68 - 3*7 - 2*1;

    _photoImageView = [[UIImageView alloc] initWithFrame:CGRectMake(35, 0, [UIScreen mainScreen].bounds.size.width - 70, [UIScreen mainScreen].bounds.size.width - 70)];
    _photoImageView.center = CGPointMake(_photoImageView.center.x, yPosition/2);
    _photoImageView.contentMode = UIViewContentModeScaleAspectFill;
    _photoImageView.layer.borderColor = UIColor.clearColor.CGColor;
    _photoImageView.layer.borderWidth = 1.0f;
    _photoImageView.layer.cornerRadius = 7.0f;
    _photoImageView.clipsToBounds = YES;
    [_photoImageView setImageWithURL:[_image objectForKey:@"url"] imageArea:[_image objectForKey:@"crop"]];
    [self.bgView addSubview:_photoImageView];
    
    self.grayView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - yPosition)];
    self.grayView.backgroundColor = RGB(247, 247, 247);
    [self.view addSubview:self.grayView];
    
    yPosition = 7;
    
    UIButton *deleteButton = [[UIButton alloc] initWithFrame:CGRectMake(6, yPosition, [UIScreen mainScreen].bounds.size.width - 12, 68)];
    deleteButton.backgroundColor = UIColor.whiteColor;
    [deleteButton addTarget:self action:@selector(deletePressed) forControlEvents:UIControlEventTouchUpInside];
    [deleteButton setTitle:@"Delete" forState:UIControlStateNormal];
    [deleteButton setTitleColor:RGB(236, 61, 83) forState:UIControlStateNormal];
    deleteButton.layer.borderColor = RGB(177, 177, 177).CGColor;
    deleteButton.layer.borderWidth = 0.5f;
    deleteButton.titleLabel.font = [FontProperties getTitleFont];
    [self.grayView addSubview:deleteButton];

    yPosition += 68;
    
    UIButton *cropPhotoButton = [[UIButton alloc] initWithFrame:CGRectMake(6, yPosition, [UIScreen mainScreen].bounds.size.width - 12, 68)];
    cropPhotoButton.backgroundColor = UIColor.whiteColor;
    [cropPhotoButton addTarget:self action:@selector(cropPhotoPressed) forControlEvents:UIControlEventTouchUpInside];
    [cropPhotoButton setTitle:@"Crop Photo" forState:UIControlStateNormal];
    [cropPhotoButton setTitleColor:RGB(118, 118, 118) forState:UIControlStateNormal];
    cropPhotoButton.titleLabel.font = [FontProperties getTitleFont];
    cropPhotoButton.layer.borderColor = RGB(177, 177, 177).CGColor;
    cropPhotoButton.layer.borderWidth = 0.5f;
    [self.grayView addSubview:cropPhotoButton];

    yPosition += 68;
    
    UIButton *makeCoverButton = [[UIButton alloc] initWithFrame:CGRectMake(6, yPosition, [UIScreen mainScreen].bounds.size.width - 12, 68)];
    makeCoverButton.backgroundColor = UIColor.whiteColor;
    [makeCoverButton addTarget:self action:@selector(makeCoverPressed) forControlEvents:UIControlEventTouchUpInside];
    [makeCoverButton setTitle:@"Make Cover" forState:UIControlStateNormal];
    [makeCoverButton setTitleColor:[FontProperties getBlueColor] forState:UIControlStateNormal];
    makeCoverButton.titleLabel.font = [FontProperties getTitleFont];
    makeCoverButton.layer.borderColor = RGB(177, 177, 177).CGColor;
    makeCoverButton.layer.borderWidth = 0.5f;
    [self.grayView addSubview:makeCoverButton];

    yPosition += 68 + 7;
    
    UIButton *cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(6, yPosition, [UIScreen mainScreen].bounds.size.width - 12, 68)];
    cancelButton.backgroundColor = [UIColor whiteColor];
    [cancelButton addTarget:self action:@selector(cancelPressed) forControlEvents:UIControlEventTouchUpInside];
    [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [cancelButton setTitleColor:RGB(74, 74, 74) forState:UIControlStateNormal];
    cancelButton.titleLabel.font = [FontProperties getTitleFont];
    cancelButton.layer.borderColor = RGB(177, 177, 177).CGColor;
    cancelButton.layer.borderWidth = 0.5;
    [self.grayView addSubview:cancelButton];

    [UIView animateWithDuration:0.15f animations:^{
        int yPosition = [UIScreen mainScreen].bounds.size.height - 4*68 - 3*7 - 2*1;
        self.grayView.frame = CGRectMake(0, yPosition, self.view.frame.size.width, self.view.frame.size.height - yPosition);
        self.bgView.alpha = 1.0f;
    }];
}

- (void)cropPhotoPressed {
    UIImageView *tempImageView = [UIImageView new];
    [tempImageView setImageWithURL:[_image objectForKey:@"url"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        GKImageCropViewController *cropViewController = [[GKImageCropViewController alloc] init];
        cropViewController.sourceImage = image;
        cropViewController.delegate = self;
        cropViewController.resizeableCropArea = NO;
        cropViewController.cropSize = CGSizeMake(280, 280);
        [self presentViewController:cropViewController animated:YES completion:^(void){}];
    }];
}

- (void)imageCropController:(GKImageCropViewController *)imageCropController didFinishWithCroppedImage:(UIImage *)croppedImage{
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)didFinishWithCroppedArea:(CGRect)croppedArea {
    NSDictionary *beforeDictionary = [[WGProfile.currentUser images] objectAtIndex:self.indexOfImage];
    NSMutableDictionary *imageDictionary = [NSMutableDictionary dictionaryWithDictionary:beforeDictionary];
    [imageDictionary setValue:@{@"x": @(MAX(0,(int)roundf(croppedArea.origin.x))),
                                @"y": @(MAX((int)roundf(croppedArea.origin.y),0)),
                                @"width": @((int)roundf(croppedArea.size.width)),
                                @"height": @((int)roundf(croppedArea.size.height))}
                       forKey:@"crop"];
    [WGProfile.currentUser setImageDictionary:imageDictionary forIndex:self.indexOfImage];
    [[WGProfile currentUser] save:^(BOOL success, NSError *error) {
        if (error) {
            [[WGError sharedInstance] handleError:error actionType:WGActionSave retryHandler:nil];
            [[WGError sharedInstance] logError:error forAction:WGActionSave];
            return;
        }
    }];
    [_photoImageView setImageWithURL:[imageDictionary objectForKey:@"url"] imageArea:[imageDictionary objectForKey:@"crop"]];
    [self dismissViewControllerAnimated:YES completion:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updatePhotos" object:nil];
}


- (void)makeCoverPressed {
    [WGProfile.currentUser makeImageAtIndexCoverImage:[WGProfile.currentUser.imagesURL indexOfObject:[_image objectForKey:@"url"]]];
    
    [WGProfile.currentUser save:^(BOOL success, NSError *error) {
        if (error) {
            [[WGError sharedInstance] logError:error forAction:WGActionSave];
            return;
        }
    }];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updatePhotos" object:nil];
    [self willMoveToParentViewController:nil];
    [self.view removeFromSuperview];
    [self removeFromParentViewController];

}

- (void)deletePressed {
    if (WGProfile.currentUser.images.count < 4) {
        [self willMoveToParentViewController:nil];
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Bummer"
                                                            message:@"You need a minimum of 3 photos"
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];

    } else {
        [WGProfile.currentUser removeImageAtIndex:[[WGProfile currentUser].imagesURL indexOfObject:[_image objectForKey:@"url"]]];
        [WGProfile.currentUser save:^(BOOL success, NSError *error) {
            if (error) {
                [[WGError sharedInstance] logError:error forAction:WGActionSave];
                return;
            }
        }];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"updatePhotos" object:nil];
        [self willMoveToParentViewController:nil];
        [self.view removeFromSuperview];
        [self removeFromParentViewController];

    }
}

-(void)cancelPressed {
    [self willMoveToParentViewController:nil];
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
}

@end
