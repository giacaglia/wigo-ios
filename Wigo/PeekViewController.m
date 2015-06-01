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

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    
    [WGAnalytics tagEvent: @"Peek View"];
    [WGAnalytics tagView:@"peek" withTargetUser:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
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
}

- (void)goBack {
    [self dismissViewControllerAnimated:YES completion:nil];
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    return self.groups.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SchoolCell *myCell = [tableView dequeueReusableCellWithIdentifier:kSchoolCellName];
    if (indexPath.row == self.groups.count - 5 || indexPath.row == self.groups.count - 1) [self fetchNextPage];
    WGGroup *group = (WGGroup *)[self.groups objectAtIndex:indexPath.row];
    myCell.schoolLabel.text = group.name;
    return myCell;
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WGGroup *group = (WGGroup *)[self.groups objectAtIndex:indexPath.row];
    [self.placesDelegate setGroupID:group.id andGroupName:group.name];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)fetchSchools {
    [WGSpinnerView addDancingGToCenterView:self.view];
    __weak typeof(self) weakSelf = self;
    [WGApi get:@"groups/" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [WGSpinnerView removeDancingGFromCenterView:strongSelf.view];
        if (error) return;
        
        NSError *dataError;
        WGCollection *objects;
        @try {
            objects = [WGCollection serializeResponse:jsonResponse andClass:[WGGroup class]];
        }
        @catch (NSException *exception) {
            NSString *message = [NSString stringWithFormat: @"Exception: %@", exception];
            
            dataError = [NSError errorWithDomain: @"WGEvent" code: 0 userInfo: @{NSLocalizedDescriptionKey : message }];
        }
        @finally {
            strongSelf.groups = objects;
            [strongSelf.schoolsTableView reloadData];
            return;
        }
    }];
}

- (void)fetchNextPage {
    if (self.isFetching || !self.groups.nextPage) return;
    self.isFetching = YES;
    __weak typeof(self) weakSelf = self;
    [self.groups addNextPage:^(BOOL success, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.isFetching = NO;
        if (error) return;
        [strongSelf.schoolsTableView reloadData];
    }];
}


@end


@implementation SchoolCell

+ (CGFloat)height {
    return 43;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}

- (void) setup {
    self.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [SchoolCell height]);
    self.backgroundColor = UIColor.clearColor;
    self.schoolLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, self.frame.size.width - 25, [SchoolCell height])];
    self.schoolLabel.textColor = UIColor.whiteColor;
    self.schoolLabel.textAlignment = NSTextAlignmentLeft;
    self.schoolLabel.font = [FontProperties mediumFont:18.0f];
    [self.contentView addSubview:self.schoolLabel];
    
    UIImageView *schoolLinkImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width - 25, self.frame.size.height/2 - 9, 10, 18)];
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
    self.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 59);
    self.contentView.backgroundColor = RGB(100, 173, 215);
    self.headerTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 20, self.frame.size.width - 25, 39)];
    self.headerTitleLabel.textColor = UIColor.whiteColor;
    self.headerTitleLabel.textAlignment = NSTextAlignmentLeft;
    self.headerTitleLabel.font = [FontProperties scLightFont:15.0f];
    [self.contentView addSubview:self.headerTitleLabel];
}
@end

