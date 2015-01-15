//
//  TopSchoolViewController.m
//  Wigo
//
//  Created by Alex Grinman on 1/15/15.
//  Copyright (c) 2015 Alex Grinman. All rights reserved.
//

#import "TopSchoolViewController.h"
#import "TopSchool.h"
#import "Globals.h"
#import "UIButtonAligned.h"

@interface TopSchoolViewController ()

@end

@implementation TopSchoolViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Top 5 Schools";
    self.navigationItem.titleView.tintColor = [FontProperties getOrangeColor];
    self.navigationController.navigationBar.tintColor = [FontProperties getOrangeColor];
    [self initializeLeftBarButton];
    
    self.navigationController.navigationBar.backgroundColor = RGB(235, 235, 235);
    self.tableView.tableFooterView = [[UIView alloc] init];
    //self.tableView.separatorColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
    
    self.tableView.frame = self.view.frame;
    
    [self.tableView registerClass:[TopSchoolCell class] forCellReuseIdentifier: @"TopSchoolCell"];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame: CGRectZero];
}

- (void) initializeLeftBarButton {
    UIButtonAligned *barBt =[[UIButtonAligned alloc] initWithFrame:CGRectMake(0, 0, 65, 44) andType:@0];
    [barBt setImage:[UIImage imageNamed:@"backIcon"] forState:UIControlStateNormal];
    [barBt setTitle:@" Back" forState:UIControlStateNormal];
    [barBt setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
    barBt.titleLabel.font = [FontProperties getSmallFont];
    [barBt addTarget:self action: @selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barItem =  [[UIBarButtonItem alloc]init];
    [barItem setCustomView:barBt];
    self.navigationItem.leftBarButtonItem = barItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [TopSchoolCell rowHeight];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.topSchools.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TopSchoolCell *cell = [tableView dequeueReusableCellWithIdentifier: @"TopSchoolCell" forIndexPath:indexPath];
    
    TopSchool *school = self.topSchools[indexPath.row];

    cell.rankLabel.text = [NSString stringWithFormat:@"%d", (int)(indexPath.row + 1)];
    cell.nameLabel.text = school.name;
    cell.countLabel.text = school.numberRegistered.stringValue;
    
    return cell;
}

@end

@implementation TopSchoolCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle: style reuseIdentifier: reuseIdentifier];
    
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [TopSchoolCell rowHeight];

    self.rankLabel = [[UILabel alloc] initWithFrame: CGRectMake(10, 0, 20, height)];
    self.rankLabel.textColor = [FontProperties getBlueColor];
    self.rankLabel.font = [FontProperties mediumFont: 24];
    [self.contentView addSubview: self.rankLabel];
    
    self.nameLabel = [[UILabel alloc] initWithFrame: CGRectMake(30, 0, width-60, height)];
    self.nameLabel.textColor = [FontProperties getBlueColor];
    self.nameLabel.font = [FontProperties mediumFont: 24];
    [self.contentView addSubview: self.nameLabel];

    self.countLabel = [[UILabel alloc] initWithFrame: CGRectMake(width-60, 0, 50, height)];
    self.countLabel.textColor = [FontProperties getOrangeColor];
    self.countLabel.font = [FontProperties mediumFont: 24];
    self.countLabel.textAlignment = NSTextAlignmentRight;
    [self.contentView addSubview: self.countLabel];

    return self;
}
+ (CGFloat)rowHeight {
    return 60.0;
}

@end
