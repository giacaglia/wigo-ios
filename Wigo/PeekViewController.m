//
//  PeekViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 12/1/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "PeekViewController.h"
#import "Globals.h"
#define kSchoolCellName @"SchoolCell"


@interface PeekViewController ()
@property (nonatomic, strong) UITableView *schoolsTableView;
@end

@implementation PeekViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [FontProperties getBlueColor];
    [self initializeTitleView];
    [self initializeTableView];
}

- (void)initializeTitleView {
    UIButton *aroundBackButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 30, 50, 50)];
    [aroundBackButton addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:aroundBackButton];
    UIImageView *backImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 15, 15)];
    backImageView.image = [UIImage imageNamed:@"whiteCloseButton"];
    [aroundBackButton addSubview:backImageView];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(45, 24, self.view.frame.size.width - 90, 50)];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.numberOfLines = 0;
    titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    titleLabel.text = @"PEEK";
    titleLabel.textColor = UIColor.whiteColor;
    titleLabel.font = [FontProperties getTitleFont];
    [self.view addSubview:titleLabel];
}

- (void)goBack {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)initializeTableView {
    self.schoolsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64)];
    self.schoolsTableView.dataSource = self;
    self.schoolsTableView.delegate = self;
    self.schoolsTableView.backgroundColor = [UIColor whiteColor];
    [self.schoolsTableView registerClass:[SchoolCell class] forCellReuseIdentifier:kSchoolCellName];
    [self.view addSubview:self.schoolsTableView];
    
}


-  (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 1;
    else if (section == 1) return 3;
    else return 100;
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SchoolCell *myCell = [tableView dequeueReusableCellWithIdentifier:kSchoolCellName];
    myCell.schoolLabel.text = @"Blade University";
    return myCell;
}
@end


@implementation SchoolCell

- (id) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder: aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame: frame];
    if (self) {
        [self setup];
    }
    
    return self;
}


- (void) setup {
    self.frame = CGRectMake(0, 0, 320, 50);
    self.backgroundColor = UIColor.clearColor;
    self.schoolLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, 295, 50)];
    self.schoolLabel.textColor = UIColor.whiteColor;
    self.schoolLabel.textAlignment = NSTextAlignmentLeft;
    self.schoolLabel.font = [FontProperties mediumFont:18.0f];
    [self.contentView addSubview:self.schoolLabel];
}
@end
