//
//  PhotoViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/13/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "PhotoViewController.h"
#import "Profile.h"
#import "FontProperties.h"
#import <QuartzCore/QuartzCore.h>
#import "RWBlurPopover.h"
#import "SDWebImage/UIImageView+WebCache.h"

@interface PhotoViewController ()

@property NSString *imageURL;

@end

@implementation PhotoViewController

- (id)initWithImageURL:(NSString *)imageURL
{
    self = [super init];
    if (self) {
        _imageURL = imageURL;
        self.view.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIImageView *photoImageView = [[UIImageView alloc] initWithFrame:CGRectMake(35, 0, 248, 248)];
    [photoImageView setImageWithURL:_imageURL];
    [self.view addSubview:photoImageView];
    
    UIButton *makeCoverButton = [[UIButton alloc] initWithFrame:CGRectMake(35, 248 + 50, 248, 42)];
    makeCoverButton.backgroundColor = RGB(246, 143, 30);
    [makeCoverButton addTarget:self action:@selector(makeCoverPressed) forControlEvents:UIControlEventTouchDown];
    [makeCoverButton setTitle:@"MAKE COVER" forState:UIControlStateNormal];
    [makeCoverButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    makeCoverButton.titleLabel.font = [FontProperties getTitleFont];
    [self.view addSubview:makeCoverButton];
    
    UIButton *deleteButton = [[UIButton alloc] initWithFrame:CGRectMake(35, 248 + 50 + 42 + 12, 248, 42)];
    deleteButton.backgroundColor = RGB(214, 45, 58);
    [deleteButton addTarget:self action:@selector(deletePressed) forControlEvents:UIControlEventTouchDown];
    [deleteButton setTitle:@"DELETE" forState:UIControlStateNormal];
    [deleteButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    deleteButton.titleLabel.font = [FontProperties getTitleFont];
    [self.view addSubview:deleteButton];
    
    UIButton *cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(35, 248 + 50 + 42 + 12 + 42 + 12, 248, 42)];
    cancelButton.backgroundColor = [UIColor whiteColor];
    [cancelButton addTarget:self action:@selector(cancelPressed) forControlEvents:UIControlEventTouchDown];
    [cancelButton setTitle:@"CANCEL" forState:UIControlStateNormal];
    [cancelButton setTitleColor:RGB(214, 45, 58) forState:UIControlStateNormal];
    cancelButton.titleLabel.font = [FontProperties getTitleFont];
    cancelButton.layer.borderColor = RGB(214, 45, 58).CGColor;
    cancelButton.layer.borderWidth = 0.5;
    [self.view addSubview:cancelButton];
    
}


- (void)makeCoverPressed {
    [[RWBlurPopover instance] dismissViewControllerAnimated:YES completion:nil];
}

- (void)deletePressed {
    [[Profile user] removeImageURL:_imageURL];
    [[Profile user] save];
    [[RWBlurPopover instance] dismissViewControllerAnimated:YES completion:nil];
}

- (void)cancelPressed {
    [[RWBlurPopover instance] dismissViewControllerAnimated:YES completion:nil];
}


@end
