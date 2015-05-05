//
//  WaitListViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/5/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import "WaitListViewController.h"
#import "Globals.h"


@implementation WaitListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initializeThanks];
    // Do any additional setup after loading the view.
}

-(void) initializeThanks {
    UILabel *thankYouLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 60, self.view.frame.size.width, 100)];
    thankYouLabel.text = @"Thank you";
    thankYouLabel.textColor = UIColor.blackColor;
    thankYouLabel.font = [FontProperties semiboldFont:30.0f];
    [self.view addSubview:thankYouLabel];
    
    UILabel *subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 160, self.view.frame.size.width, 200)];
    subtitleLabel.text = @"We have added you to our signup queue.";
    subtitleLabel.textColor = UIColor.blackColor;
    subtitleLabel.font = [FontProperties lightFont:20.0f];
    [self.view addSubview:subtitleLabel];
}

-(void) initializePuzzle {
    UIImageView *puzzleImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 302, 160)];
    puzzleImgView.image = [UIImage imageNamed:@"puzzle"];
    
}



@end
