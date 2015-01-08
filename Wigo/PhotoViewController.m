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

@interface PhotoViewController ()
@property NSDictionary *image;
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
    
    UIImageView *photoImageView = [[UIImageView alloc] initWithFrame:CGRectMake(35, [[UIScreen mainScreen] bounds].size.height - [[UIScreen mainScreen] bounds].size.width - 130, [[UIScreen mainScreen] bounds].size.width - 70, [[UIScreen mainScreen] bounds].size.width - 70)];
    photoImageView.contentMode = UIViewContentModeScaleAspectFill;
    photoImageView.clipsToBounds = YES;
    [photoImageView setImageWithURL:[_image objectForKey:@"url"] imageArea:[_image objectForKey:@"crop"]];
    [self.view addSubview:photoImageView];
    
    UIButton *makeCoverButton = [[UIButton alloc] initWithFrame:CGRectMake(35, photoImageView.frame.origin.y + photoImageView.frame.size.height + 24, [[UIScreen mainScreen] bounds].size.width - 70, 42)];
    makeCoverButton.backgroundColor = RGB(246, 143, 30);
    [makeCoverButton addTarget:self action:@selector(makeCoverPressed) forControlEvents:UIControlEventTouchUpInside];
    [makeCoverButton setTitle:@"MAKE COVER" forState:UIControlStateNormal];
    [makeCoverButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    makeCoverButton.titleLabel.font = [FontProperties getTitleFont];
    [self.view addSubview:makeCoverButton];
    
    UIButton *deleteButton = [[UIButton alloc] initWithFrame:CGRectMake(35, photoImageView.frame.origin.y + photoImageView.frame.size.height + 78, [[UIScreen mainScreen] bounds].size.width - 70, 42)];
    deleteButton.backgroundColor = RGB(214, 45, 58);
    [deleteButton addTarget:self action:@selector(deletePressed) forControlEvents:UIControlEventTouchUpInside];
    [deleteButton setTitle:@"DELETE" forState:UIControlStateNormal];
    [deleteButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    deleteButton.titleLabel.font = [FontProperties getTitleFont];
    [self.view addSubview:deleteButton];
    
    UIButton *cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(35, photoImageView.frame.origin.y + photoImageView.frame.size.height + 132, [[UIScreen mainScreen] bounds].size.width - 70, 42)];
    cancelButton.backgroundColor = [UIColor whiteColor];
    [cancelButton addTarget:self action:@selector(cancelPressed) forControlEvents:UIControlEventTouchUpInside];
    [cancelButton setTitle:@"CANCEL" forState:UIControlStateNormal];
    [cancelButton setTitleColor:RGB(214, 45, 58) forState:UIControlStateNormal];
    cancelButton.titleLabel.font = [FontProperties getTitleFont];
    cancelButton.layer.borderColor = RGB(214, 45, 58).CGColor;
    cancelButton.layer.borderWidth = 0.5;
    [self.view addSubview:cancelButton];
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

    }
    else {
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

- (void)cancelPressed {
    [[RWBlurPopover instance] dismissViewControllerAnimated:YES completion:nil];
}

@end
