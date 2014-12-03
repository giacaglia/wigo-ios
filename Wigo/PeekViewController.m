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
#define kHeaderSchoolCellName @"HeaderSchoolCell"


@interface PeekViewController ()
@property (nonatomic, strong) UITableView *schoolsTableView;
@end

@implementation PeekViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.schoolSections = [NSArray new];
    self.view.backgroundColor = RGB(100, 173, 215);
    [self initializeTitleView];
    [self initializeTableView];
    [self fetchSchools];
}

- (void)initializeTitleView {
    UIButton *aroundBackButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 30, 50, 50)];
    [aroundBackButton addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:aroundBackButton];
    UIImageView *backImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 15, 15)];
    backImageView.image = [UIImage imageNamed:@"whiteCloseButton"];
    [aroundBackButton addSubview:backImageView];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(45, 22, self.view.frame.size.width - 90, 50)];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.numberOfLines = 0;
    titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    titleLabel.text = @"Peek";
    titleLabel.textColor = UIColor.whiteColor;
    titleLabel.font = [FontProperties getTitleFont];
    [self.view addSubview:titleLabel];
    
    UIButton *searchButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 30 - 15, 40 - 40, 60, 80)];
    [searchButton addTarget:self action:@selector(searchPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:searchButton];
    UIImageView *searchImageView = [[UIImageView alloc] initWithFrame:CGRectMake(14, 35, 15, 16)];
    searchImageView.image = [UIImage imageNamed:@"whiteSearchIcon"];
    [searchButton addSubview:searchImageView];
}

- (void)goBack {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)searchPressed {
    
}

- (void)initializeTableView {
    self.schoolsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64)];
    self.schoolsTableView.dataSource = self;
    self.schoolsTableView.delegate = self;
    self.schoolsTableView.backgroundColor = RGB(115, 181, 219);
    self.schoolsTableView.separatorColor = RGB(100, 173, 215);
    [self.schoolsTableView registerClass:[SchoolCell class] forCellReuseIdentifier:kSchoolCellName];
    [self.schoolsTableView registerClass:[SchoolHeaderCell class] forHeaderFooterViewReuseIdentifier:kHeaderSchoolCellName];
    [self.view addSubview:self.schoolsTableView];
    
}


-  (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.schoolSections.count;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    NSDictionary *sectionDictionary = [self.schoolSections objectAtIndex:section];
    NSArray *arrayOfSchools = [sectionDictionary objectForKey:@"schools"];
    return [arrayOfSchools count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SchoolCell *myCell = [tableView dequeueReusableCellWithIdentifier:kSchoolCellName];
    NSDictionary *sectionDictionary = [self.schoolSections objectAtIndex:indexPath.section];
    NSArray *arrayOfSchools = [sectionDictionary objectForKey:@"schools"];
    NSDictionary *schoolDictionary = [arrayOfSchools objectAtIndex:indexPath.row];
    myCell.schoolLabel.text = [schoolDictionary objectForKey:@"name"];
    return myCell;
}

- (CGFloat)tableView:(UITableView *)tableView
heightForHeaderInSection:(NSInteger)section {
    return 59;
}

- (UIView *)tableView:(UITableView *)tableView
viewForHeaderInSection:(NSInteger)section {
    SchoolHeaderCell *schoolHeaderCell = [tableView dequeueReusableHeaderFooterViewWithIdentifier:kHeaderSchoolCellName];
    NSDictionary *sectionDictionary = [self.schoolSections objectAtIndex:section];
    schoolHeaderCell.headerTitleLabel.text =  [sectionDictionary objectForKey:@"title"];
    return schoolHeaderCell;
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)fetchSchools {
    [Network queryAsynchronousAPI:@"groups/peek/" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        if (!error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.schoolSections = [jsonResponse objectForKey:@"sections"];
                [self.schoolsTableView reloadData];
            });
        }
    }];
}


@end


@implementation SchoolCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
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
    
    UIImageView *schoolLinkImageView = [[UIImageView alloc] initWithFrame:CGRectMake(295, self.frame.size.height/2 - 9, 10, 18)];
    schoolLinkImageView.image = [UIImage imageNamed:@"schoolLink"];
    [self.contentView addSubview:schoolLinkImageView];
}


@end


@implementation SchoolHeaderCell

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}

- (void) setup {
    self.frame = CGRectMake(0, 0, 320, 59);
    self.contentView.backgroundColor = RGB(100, 173, 215);
    self.headerTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 20, 295, 39)];
    self.headerTitleLabel.textColor = UIColor.whiteColor;
    self.headerTitleLabel.textAlignment = NSTextAlignmentLeft;
    self.headerTitleLabel.font = [FontProperties scLightFont:15.0f];
    [self.contentView addSubview:self.headerTitleLabel];
}
@end

