//
//  WGEventLikesViewController.m
//  Wigo
//
//  Created by Gabriel Mahoney on 5/19/15.
//  Copyright (c) 2015 Gabriel Mahoney. All rights reserved.
//

#import "WGEventLikesViewController.h"
#import "FontProperties.h"

@interface WGEventLikesViewController ()

@property (nonatomic) UIImageView *backgroundImageView;
@property (nonatomic) UIImageView *upvoteImageView;

@property (nonatomic) UIImageView *upArrowImageView;
@property (nonatomic) UILabel *numberOfVotesLabel;

@end


@implementation WGEventLikesViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self) {
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        
        self.numberOfVotesLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,
                                                                            0, 72.0, 20.0)];
        self.dismissButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 80.0, 28.0)];
    }
    return self;
}

- (void)viewDidLoad {
    
    self.backgroundImageView = [[UIImageView alloc] initWithImage:self.backgroundImage];
    [self.view addSubview:self.backgroundImageView];
    
    self.upvoteImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width-40,
                                                                         8,
                                                                         30,
                                                                         28)];
    self.upvoteImageView.image = [UIImage imageNamed:@"heart"];
    [self.view addSubview:self.upvoteImageView];
    
    
    
    self.numberOfVotesLabel.textColor = UIColor.whiteColor;
    self.numberOfVotesLabel.textAlignment = NSTextAlignmentCenter;
    self.numberOfVotesLabel.font = [FontProperties openSansSemibold:16.0f];
    
    self.upArrowImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"downArrow"]];
    self.upArrowImageView.frame = CGRectMake(0, 0, 36.0, 12.0);
    
    
    
    
    self.dismissButton.center = CGPointMake(self.view.frame.size.width/2.0, 18.0);
    
    
    self.numberOfVotesLabel.center = CGPointMake(self.dismissButton.frame.size.width/2.0,0.0);
    CGRect frame = self.numberOfVotesLabel.frame;
    frame.origin.y = 4.0;
    self.numberOfVotesLabel.frame = frame;
    
    self.upArrowImageView.center = CGPointMake(self.dismissButton.frame.size.width/2.0,0.0);
    frame = self.upArrowImageView.frame;
    frame.origin.y = CGRectGetMaxY(self.numberOfVotesLabel.frame);
    self.upArrowImageView.frame = frame;
    
    [self.dismissButton addSubview:self.numberOfVotesLabel];
    [self.dismissButton addSubview:self.upArrowImageView];
    
    [self.view addSubview:self.dismissButton];

}

@end
