//
//  PhotoViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/13/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "PhotoViewController.h"
#import "Globals.h"
#import "RWBlurPopover.h"
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
        self.view.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _photoImageView = [[UIImageView alloc] initWithFrame:CGRectMake(35, [[UIScreen mainScreen] bounds].size.height - [[UIScreen mainScreen] bounds].size.width - 184, [[UIScreen mainScreen] bounds].size.width - 70, [[UIScreen mainScreen] bounds].size.width - 70)];
    _photoImageView.contentMode = UIViewContentModeScaleAspectFill;
    _photoImageView.clipsToBounds = YES;
    [_photoImageView setImageWithURL:[_image objectForKey:@"url"] imageArea:[_image objectForKey:@"crop"]];
    [self.view addSubview:_photoImageView];
    
    UIButton *makeCoverButton = [[UIButton alloc] initWithFrame:CGRectMake(35, _photoImageView.frame.origin.y + _photoImageView.frame.size.height + 24, [[UIScreen mainScreen] bounds].size.width - 70, 42)];
    makeCoverButton.backgroundColor = RGB(246, 143, 30);
    [makeCoverButton addTarget:self action:@selector(makeCoverPressed) forControlEvents:UIControlEventTouchUpInside];
    [makeCoverButton setTitle:@"MAKE COVER" forState:UIControlStateNormal];
    [makeCoverButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    makeCoverButton.titleLabel.font = [FontProperties getTitleFont];
    [self.view addSubview:makeCoverButton];
    
    UIButton *cropPhotoButton = [[UIButton alloc] initWithFrame:CGRectMake(35, _photoImageView.frame.origin.y + _photoImageView.frame.size.height + 78, [[UIScreen mainScreen] bounds].size.width - 70, 42)];
    cropPhotoButton.backgroundColor = [FontProperties getBlueColor];
    [cropPhotoButton addTarget:self action:@selector(cropPhotoPressed) forControlEvents:UIControlEventTouchUpInside];
    [cropPhotoButton setTitle:@"CROP PHOTO" forState:UIControlStateNormal];
    [cropPhotoButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    cropPhotoButton.titleLabel.font = [FontProperties getTitleFont];
    [self.view addSubview:cropPhotoButton];
    
    UIButton *deleteButton = [[UIButton alloc] initWithFrame:CGRectMake(35, _photoImageView.frame.origin.y + _photoImageView.frame.size.height + 132, [[UIScreen mainScreen] bounds].size.width - 70, 42)];
    deleteButton.backgroundColor = RGB(214, 45, 58);
    [deleteButton addTarget:self action:@selector(deletePressed) forControlEvents:UIControlEventTouchUpInside];
    [deleteButton setTitle:@"DELETE" forState:UIControlStateNormal];
    [deleteButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    deleteButton.titleLabel.font = [FontProperties getTitleFont];
    [self.view addSubview:deleteButton];
    
    UIButton *cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(35, _photoImageView.frame.origin.y + _photoImageView.frame.size.height + 186, [[UIScreen mainScreen] bounds].size.width - 70, 42)];
    cancelButton.backgroundColor = [UIColor whiteColor];
    [cancelButton addTarget:self action:@selector(cancelPressed) forControlEvents:UIControlEventTouchUpInside];
    [cancelButton setTitle:@"CANCEL" forState:UIControlStateNormal];
    [cancelButton setTitleColor:RGB(214, 45, 58) forState:UIControlStateNormal];
    cancelButton.titleLabel.font = [FontProperties getTitleFont];
    cancelButton.layer.borderColor = RGB(214, 45, 58).CGColor;
    cancelButton.layer.borderWidth = 0.5;
    [self.view addSubview:cancelButton];
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
            return;
        }
    }];
    [_photoImageView setImageWithURL:[imageDictionary objectForKey:@"url"] imageArea:[imageDictionary objectForKey:@"crop"]];
    [self dismissViewControllerAnimated:YES completion:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updatePhotos" object:nil];
}


- (void)makeCoverPressed {
    [[WGProfile currentUser] makeImageAtIndexCoverImage:[[WGProfile currentUser].imagesURL indexOfObject:[_image objectForKey:@"url"]]];
    
    [[WGProfile currentUser] save:^(BOOL success, NSError *error) {
        if (error) {
            [[WGError sharedInstance] handleError:error actionType:WGActionSave retryHandler:nil];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"updatePhotos" object:nil];
        [[RWBlurPopover instance] dismissViewControllerAnimated:YES completion:nil];
    }];
}

- (void)deletePressed {
    if ([WGProfile currentUser].images.count < 4) {
        [[RWBlurPopover instance] dismissViewControllerAnimated:YES completion:nil];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Bummer"
                                                            message:@"You need a minimum of 3 photos"
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];

    } else {
        [[WGProfile currentUser] removeImageAtIndex:[[WGProfile currentUser].imagesURL indexOfObject:[_image objectForKey:@"url"]]];
        [[WGProfile currentUser] save:^(BOOL success, NSError *error) {
            if (error) {
                [[WGError sharedInstance] handleError:error actionType:WGActionSave retryHandler:nil];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:@"updatePhotos" object:nil];
            [[RWBlurPopover instance] dismissViewControllerAnimated:YES completion:nil];
        }];
    }
}

-(void)cancelPressed {
    [[RWBlurPopover instance] dismissViewControllerAnimated:YES completion:nil];
}

@end
