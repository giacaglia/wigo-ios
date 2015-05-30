//
//  FacebookAlbumTableViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 7/7/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "FacebookAlbumTableViewController.h"
#import "FacebookImagesViewController.h"
#import "Globals.h"
#import "UIButtonAligned.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

@interface FacebookAlbumTableViewController ()
@property NSArray *albumArray;
@end

NSMutableArray *idAlbumArray;
NSMutableArray *coverIDArray;
NSMutableArray *coverAlbumArray;

@implementation FacebookAlbumTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _albumArray = [NSArray new];
    idAlbumArray = [NSMutableArray new];
    coverIDArray = [NSMutableArray new];
    coverAlbumArray = [NSMutableArray new];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView registerClass:[AlbumTableCell class] forCellReuseIdentifier:kAlbumTableCellName];
    self.title = @"Choose Album";
    [self initializeBackBarButton];
    [self getFacebookAlbums];
}

- (void)initializeBackBarButton {
    UIButtonAligned *barBt = [[UIButtonAligned alloc] initWithFrame:CGRectMake(0, 0, 65, 44) andType:@0];
    [barBt setImage:[UIImage imageNamed:@"backIcon"] forState:UIControlStateNormal];
    [barBt setTitle:@" Back" forState:UIControlStateNormal];
    [barBt setTitleColor:[FontProperties getBlueColor] forState:UIControlStateNormal];
    barBt.titleLabel.font = [FontProperties getSubtitleFont];
    [barBt addTarget:self action: @selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barItem =  [[UIBarButtonItem alloc] init];
    [barItem setCustomView:barBt];
    self.navigationItem.leftBarButtonItem = barItem;
}

- (void)goBack {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)getFacebookAlbums {
    if (![FBSDKAccessToken currentAccessToken]) {
        [self requestReadPermissions];
        return;
    }
    [WGSpinnerView addDancingGToCenterView:self.view];
    [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me/albums" parameters:nil]
     startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
         [WGSpinnerView removeDancingGFromCenterView:self.view];
         if (error) {
             [self requestReadPermissions];
             [[WGError sharedInstance] logError:error forAction:WGActionFacebook];
             return;
         }
         NSArray *nonCleanAlbums = (NSArray *)[result objectForKey:@"data"];
         if (nonCleanAlbums.count == 0) [self requestReadPermissions];
         NSMutableArray *cleanAlbums = [NSMutableArray new];
         for (FBGraphObject *albumFBGraphObject in nonCleanAlbums) {
//             NSString *nameFBAlbum = [albumFBGraphObject objectForKey:@"name"];
//             if ([nameFBAlbum isEqualToString:@"Profile Pictures"] ||  [nameFBAlbum isEqualToString:@"Instagram Photos"]) {
                 [cleanAlbums addObject:albumFBGraphObject];
                 [idAlbumArray addObject:[albumFBGraphObject objectForKey:@"id"]];
                 if ([albumFBGraphObject objectForKey:@"cover_photo"]) [coverIDArray addObject:[albumFBGraphObject objectForKey:@"cover_photo"]];
//             }
         }
         _albumArray = [NSArray arrayWithArray:cleanAlbums];
         [self getAlbumDetails];
         [self.tableView reloadData];

     }];
}


- (void)requestReadPermissions {
    FBSDKLoginManager *loginManager = [[FBSDKLoginManager alloc] init];
    [loginManager logInWithReadPermissions:@[@"user_photos"] handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
        if (error) {
            [self showErrorNotAccess];
        }
        else {
            [self getFacebookAlbums];
        }
    }];
}

- (BOOL)gaveUserPermission:(NSDictionary *)userInfo {
    if ([[userInfo allKeys] containsObject:@"com.facebook.sdk:HTTPStatusCode"] && [[userInfo allKeys] containsObject:@"com.facebook.sdk:ParsedJSONResponseKey"]) {
        if ([[userInfo objectForKey:@"com.facebook.sdk:HTTPStatusCode"] isEqualToNumber:@403] &&
            [[[userInfo objectForKey:@"com.facebook.sdk:ParsedJSONResponseKey"] objectForKey:@"code"] isEqualToNumber:@403]) {
            return NO;
        }
        return YES;
    }
    return YES;
}

- (void)showErrorNotAccess {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"Could not load your Facebook Photos"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
}

- (void)getAlbumDetails {
    for (int k = 0; k < [coverIDArray count]; k++) {
        [coverAlbumArray addObject:@""];
    }
    for (int i = 0; i < [coverIDArray count]; i++) {
        [WGSpinnerView addDancingGToCenterView:self.view];
        NSString *graphPath = [NSString stringWithFormat:@"/%@", [coverIDArray objectAtIndex:i]];
        [[[FBSDKGraphRequest alloc] initWithGraphPath:graphPath
                                           parameters:nil]
         startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
                                [WGSpinnerView removeDancingGFromCenterView:self.view];
                                if (!error) {
                                    NSString *resultObject = [result objectForKey:@"source"];
                                    for (int j = 0; j < [coverIDArray count]; j++) {
                                        if ([[result objectForKey:@"id"] isEqualToString:[coverIDArray objectAtIndex:j]]) {
                                            [coverAlbumArray replaceObjectAtIndex:j withObject:resultObject];
                                        }
                                    }
                                    [self.tableView reloadData];
                                }
        }];
    }


}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_albumArray count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [AlbumTableCell height];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AlbumTableCell *cell = (AlbumTableCell*)[tableView dequeueReusableCellWithIdentifier:kAlbumTableCellName forIndexPath:indexPath];
    FBGraphObject *albumFBGraphObject = [_albumArray objectAtIndex:indexPath.row];
    cell.albumNameLabel.text = [albumFBGraphObject objectForKey:@"name"];
    if (indexPath.row < coverAlbumArray.count) {
        NSString *imageURL = [coverAlbumArray objectAtIndex:indexPath.row];
        [cell.coverImageView setImageWithURL:[NSURL URLWithString:imageURL]];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *albumID = [idAlbumArray objectAtIndex:(int)indexPath.row];
    [self.navigationController pushViewController:[[FacebookImagesViewController alloc] initWithAlbumID:albumID] animated:YES];
}

@end

@implementation AlbumTableCell

+ (CGFloat)height {
    return 70.0f;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}

-(void) setup {
    self.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [AlbumTableCell height]);
    
    self.coverImageView = [[UIImageView alloc] initWithFrame: CGRectMake(15, 10, 55, 55)];
    self.coverImageView.center = CGPointMake(self.coverImageView.center.x, self.center.y);
    self.coverImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.coverImageView.clipsToBounds = YES;
    [self.contentView addSubview:self.coverImageView];
    
    self.albumNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(70 + 10, 20, self.frame.size.width - 75, 20)];
    self.albumNameLabel.center = CGPointMake(self.albumNameLabel.center.x, self.center.y);
    self.albumNameLabel.font = [FontProperties mediumFont:18.0f];
    self.albumNameLabel.textColor = UIColor.blackColor;
    self.albumNameLabel.textAlignment = NSTextAlignmentLeft;
    [self.contentView addSubview:self.albumNameLabel];
    
    UIImageView *arrowMsgImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width - 30, [AlbumTableCell height]/2 - 9.5, 11, 19)];
    arrowMsgImageView.image = [UIImage imageNamed:@"arrowMessage"];
    [self.contentView addSubview:arrowMsgImageView];
}

@end
