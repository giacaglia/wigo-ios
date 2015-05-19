//
//  MessageViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/27/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "MessageViewController.h"
#import "Globals.h"
#import "UIButtonAligned.h"
#import "ConversationViewController.h"

@interface MessageViewController ()
@property UISearchBar *searchBar;
@end

@implementation MessageViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;

    self.allFriends = [[WGCollection alloc] initWithType:[WGUser class]];
    self.content = [[WGCollection alloc] initWithType:[WGUser class]];
    self.isFetchingEveryone = NO;
        
    UIView *blueBannerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 20)];
    blueBannerView.backgroundColor = [FontProperties getBlueColor];
    [self.view addSubview:blueBannerView];

    // Title setup
    [self initializeNavigationItem];
    [self initializeTableListOfFriends];
    [self fetchFirstPageEveryone];
}

- (void) initializeNavigationItem {
    self.title = @"New Message";

    UIButtonAligned *barBt = [[UIButtonAligned alloc] initWithFrame:CGRectMake(0, 0, 60, 44) andType:@0];
    [barBt setImage:[UIImage imageNamed:@"whiteBackIcon"] forState:UIControlStateNormal];
    [barBt setTitle:@" Back" forState:UIControlStateNormal];
    [barBt setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    barBt.titleLabel.font = [FontProperties getSubtitleFont];
    [barBt addTarget:self action: @selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barItem =  [[UIBarButtonItem alloc] init];
    [barItem setCustomView:barBt];
    self.navigationItem.leftBarButtonItem = barItem;
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [WGAnalytics tagView:@"new_chat"];
    [self.tableView reloadData];
}

-(void) goBack {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) initializeTableListOfFriends {
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64)];
    [self.tableView registerClass:[MessageCell class] forCellReuseIdentifier:kMessageCellName];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50)];
    _searchBar.placeholder = @"Search By Name";
    _searchBar.delegate = self;
    self.tableView.tableHeaderView = _searchBar;
    self.tableView.contentOffset = CGPointMake(0, 50);
    [self.view addSubview:self.tableView];
}

#pragma Network Functions

- (void) fetchFirstPageEveryone {
    if (self.isFetchingEveryone) return;
    self.isFetchingEveryone = YES;
    __weak typeof(self) weakSelf = self;
    [WGSpinnerView addDancingGToCenterView:self.view];
    [WGProfile.currentUser getFriends:^(WGCollection *collection, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            __strong typeof(self) strongSelf = weakSelf;
            [WGSpinnerView removeDancingGFromCenterView:strongSelf.view];
            strongSelf.isFetchingEveryone = NO;
            if (error) {
                [[WGError sharedInstance] logError:error forAction:WGActionLoad];
                return;
            }
            strongSelf.allFriends = collection;
            strongSelf.content = strongSelf.allFriends;
            [strongSelf.tableView reloadData];
        });
    }];

}

- (void) fetchNextPage {
    if (self.isFetchingEveryone) return;
    if (!self.content.nextPage) return;
    self.isFetchingEveryone = YES;
    __weak typeof(self) weakSelf = self;
    [self.content addNextPage:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            __strong typeof(self) strongSelf = weakSelf;
            strongSelf.isFetchingEveryone = NO;
            if (error) {
                [[WGError sharedInstance] logError:error forAction:WGActionLoad];
                return;
            }
            [strongSelf.tableView reloadData];
        });
    }];
}

#pragma mark - Tablew View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.content.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MessageCell *cell = [tableView dequeueReusableCellWithIdentifier:kMessageCellName forIndexPath:indexPath];
    
    if (indexPath.row == self.content.count - 5) [self fetchNextPage];
    WGUser *user = [self getUserAtIndex:indexPath];
    if (!user) return cell;
    cell.user = user;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [MessageCell height];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WGUser *user = [self getUserAtIndex:indexPath];
    if (!user) return;
    
    [self.navigationController pushViewController:[[ConversationViewController alloc] initWithUser:user] animated:YES];
}

- (WGUser *)getUserAtIndex:(NSIndexPath *)indexPath {
    WGUser *user;
    int sizeOfArray = (int)self.content.count;
    if (sizeOfArray > 0 && sizeOfArray > indexPath.row)
        user = (WGUser *)[self.content objectAtIndex:[indexPath row]];
    return user;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [_searchBar endEditing:YES];
}


#pragma mark - UISearchBarDelegate


- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if([searchText length] != 0) {
        [self performBlock:^(void){[self searchTableList];}
                afterDelay:0.25
     cancelPreviousRequest:YES];
    } else {
        self.content = self.allFriends;
        self.isSearching = NO;
        [self.tableView reloadData];
    }

}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self performBlock:^(void){[self searchTableList];}
            afterDelay:0.25
 cancelPreviousRequest:YES];
}

- (void)searchTableList {
    NSString *oldString = _searchBar.text;
    NSString *searchString = [oldString urlEncodeUsingEncoding:NSUTF8StringEncoding];
    __weak typeof(self) weakSelf = self;
    if ([oldString isEqualToString:@"Initiate meltdown"]) {
        [self showMeltdown];
    }
    [WGProfile.currentUser searchNotMe:searchString withHandler:^(WGCollection *collection, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            __strong typeof(self) strongSelf = weakSelf;
            strongSelf.isFetchingEveryone = NO;
            if (error) {
                [[WGError sharedInstance] logError:error forAction:WGActionLoad];
                return;
            }
            strongSelf.isSearching = YES;
            strongSelf.content = collection;
            [strongSelf.tableView reloadData];
        });
    }];
  
}

- (void)showMeltdown {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Meltdown"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"api.wigo.us";
    }];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              UITextField *textField = alert.textFields[0];
                                                              NSString *text = textField.text;
                                                              if ([text isEqualToString:@"dev"] || [text isEqualToString:@"dev-api.wigo.us"]) {
                                                                  [WGApi setBaseURLString:@"https://dev-api.wigo.us/api/%@"];
                                                              }
                                                              else if ([text isEqualToString:@"stage"] || [text isEqualToString:@"stage-api.wigo.us"]) {
                                                                  [WGApi setBaseURLString:@"https://stage-api.wigo.us/api/%@"];
                                                              }
                                                              else if ([text isEqualToString:@"prod"] || [text isEqualToString:@"api.wigo.us"]) {
                                                                  [WGApi setBaseURLString:@"https://api.wigo.us/api/%@"];
                                                              }
                                                              else {
                                                                  NSMutableString *newMutableString = [NSMutableString stringWithString:text];
                                                                  [newMutableString appendString:@"/api/%@"];
                                                                  [WGApi setBaseURLString:newMutableString];
                                                              }
                                                          }];
    
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}

@end


@implementation MessageCell

+ (CGFloat) height {
    return 75.0f;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}

- (void) setup {
    self.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [MessageCell height]);
    self.contentView.frame = self.frame;
    self.contentView.backgroundColor = UIColor.whiteColor;
    
    self.profileImageView = [[UIImageView alloc]initWithFrame:CGRectMake(15, 7, 60, 60)];
    self.profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.profileImageView.clipsToBounds = YES;
    self.profileImageView.layer.borderWidth = 1.0f;
    self.profileImageView.layer.borderColor = UIColor.clearColor.CGColor;
    self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.width/2;
    [self.contentView addSubview:self.profileImageView];
    
    self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(85, [MessageCell height]/2 - 10, 150, 20)];
    self.nameLabel.font = [FontProperties getSubtitleFont];
    [self.contentView addSubview:self.nameLabel];
}

- (void)setUser:(WGUser *)user {
    _user = user;
    [self.profileImageView setSmallImageForUser:user completed:nil];
    self.nameLabel.text = user.fullName;
}

@end