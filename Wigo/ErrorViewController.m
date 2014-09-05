//
//  ErrorViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 9/4/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "ErrorViewController.h"
#import "Globals.h"

UIScrollView *scrollView;
@implementation ErrorViewController

- (id)init {
    self = [super init];
    if (self) {
        self.view.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 64 + 5, 160, 40)];
    textLabel.text = @"To access pictures:";
    [self.view addSubview:textLabel];
    [self loadScrollView];
}

- (void)loadScrollView {
     scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(15, 120, self.view.frame.size.width - 30, self.view.frame.size.height - 120)];
    [self addImage:@"3.png" andText:@"1. Go to the Facebook app, click the 'More' tab, and click 'Settings'" forItemNumber:0];
    [self addImage:@"4.png" andText:@"2. Click 'Apps'" forItemNumber:1];
    [self addImage:@"5.png" andText:@"3. Click 'wigo'" forItemNumber:2];
    [self addImage:@"6.png" andText:@"4. Click 'Remove wigo'" forItemNumber:3];
    [self addImage:@"7.png" andText:@"5. Click 'Remove'" forItemNumber:4];

    [self.view addSubview:scrollView];
}

- (void)addImage:(NSString *)imageName andText:(NSString *)text forItemNumber:(int)itemNumber {
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(itemNumber * (170), 0 , 160, 284)];
    imageView.image = [UIImage imageNamed:imageName];
    scrollView.contentSize = CGSizeMake(35 + itemNumber * (170) + 160, self.view.frame.size.height - 120);
    [scrollView addSubview:imageView];
    
    UILabel *textLabel = [[UILabel alloc] init];
    if (itemNumber == 1 || itemNumber == 2 || itemNumber == 4) {
        textLabel.frame = CGRectMake(itemNumber * (170), 284 + 5, 160, 30);
    }
    else if (itemNumber == 3) {
        textLabel.frame = CGRectMake(itemNumber * (170), 284 + 5, 160, 50);
    }
    else {
        textLabel.frame = CGRectMake(itemNumber * (170), 284 + 5, 160, 100);
    }
    textLabel.text = text;
    textLabel.textAlignment = NSTextAlignmentLeft;
    textLabel.numberOfLines = 0;
    textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [scrollView addSubview:textLabel];
}



@end
