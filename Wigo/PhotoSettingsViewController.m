//
//  PhotoSettingsViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/19/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import "PhotoSettingsViewController.h"
#import "Globals.h"
#import "EventMessagesConstants.h"

@interface PhotoSettingsViewController ()

@end

@implementation PhotoSettingsViewController

-(void) viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.bgView = [[UIView alloc] initWithFrame:self.view.frame];
    self.bgView.backgroundColor = RGBAlpha(74, 74, 74, 0.6f);
    self.bgView.alpha = 0.0f;
    [self.view addSubview:self.bgView];
    [self.view sendSubviewToBack:self.bgView];
    
    int heightOfGrayView = 2*68 + 3*7;
    
    self.grayView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height , self.view.frame.size.width, heightOfGrayView)];
    self.grayView.backgroundColor = RGB(247, 247, 247);
    [self.view addSubview:self.grayView];
    
    int yPosition = 7;

    UIButton  *deleteButton = [[UIButton alloc] initWithFrame:CGRectMake(6, yPosition, self.view.frame.size.width - 12, 68)];
    deleteButton.backgroundColor = UIColor.whiteColor;
    [deleteButton addTarget:self action:@selector(deletePressed) forControlEvents:UIControlEventTouchUpInside];
    if ([self.eventMsg.user isCurrentUser]) {
        if ([self.eventMsg.mediaMimeType isEqual:kImageEventType]) {
            [deleteButton setTitle:@"Delete this photo" forState:UIControlStateNormal];
        }
        else {
            [deleteButton setTitle:@"Delete this video" forState:UIControlStateNormal];
        }
    }
    else {
        if ([self.eventMsg.mediaMimeType isEqual:kImageEventType]) {
            [deleteButton setTitle:@"Flag this photo" forState:UIControlStateNormal];
        }
        else {
            [deleteButton setTitle:@"Flag this video" forState:UIControlStateNormal];
        }
    }
   
    [deleteButton setTitleColor:RGB(236, 61, 83) forState:UIControlStateNormal];
    deleteButton.titleLabel.font = [FontProperties getTitleFont];
    deleteButton.layer.borderColor = RGB(177, 177, 177).CGColor;
    deleteButton.layer.borderWidth = 0.5f;
    [self.grayView addSubview:deleteButton];
    
    yPosition += 68 + 7;
    
    UIButton *cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(6, yPosition, self.view.frame.size.width - 12, 68)];
    cancelButton.backgroundColor = UIColor.whiteColor;
    [cancelButton addTarget:self action:@selector(cancelPressed) forControlEvents:UIControlEventTouchUpInside];
    [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [cancelButton setTitleColor:RGB(74, 74, 74) forState:UIControlStateNormal];
    cancelButton.titleLabel.font = [FontProperties getTitleFont];
    cancelButton.layer.borderColor = RGB(177, 177, 177).CGColor;
    cancelButton.layer.borderWidth = 0.5f;
    [self.grayView addSubview:cancelButton];
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    int heightOfGrayView = 2*68 + 3*7;
    [UIView animateWithDuration:0.5f animations:^{
        self.bgView.alpha = 1.0f;
    }];

    [UIView animateWithDuration:0.15f animations:^{
        self.grayView.frame = CGRectMake(0, self.view.frame.size.height - heightOfGrayView, self.view.frame.size.width, heightOfGrayView);
    }];
}


-(void) cancelPressed {
    [UIView animateWithDuration:0.5f animations:^{
        self.bgView.alpha = 0.0f;
    }];
    
    [UIView animateWithDuration:0.15f animations:^{
        self.grayView.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, self.grayView.frame.size.height);
    } completion:^(BOOL finished) {
        [self willMoveToParentViewController:nil];
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
    }];
   
}

-(void) deletePressed {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"deletePhoto" object:nil];
    [UIView animateWithDuration:0.5f animations:^{
        self.bgView.alpha = 0.0f;
    }];
    
    [UIView animateWithDuration:0.15f animations:^{
        self.grayView.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, self.grayView.frame.size.height);
    } completion:^(BOOL finished) {
        [self willMoveToParentViewController:nil];
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
    }];
}

-(void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
