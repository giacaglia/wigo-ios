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

    [self initializeBackBarButton];
    [self getFacebookAlbums];
}

- (void)initializeBackBarButton {
    UIButtonAligned *barBt = [[UIButtonAligned alloc] initWithFrame:CGRectMake(0, 0, 65, 44) andType:@0];
    [barBt setImage:[UIImage imageNamed:@"backIcon"] forState:UIControlStateNormal];
    [barBt setTitle:@" Back" forState:UIControlStateNormal];
    [barBt setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
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
    if ([FBSDKAccessToken currentAccessToken]) {
        [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me/albums" parameters:nil]
         startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
             if (error) {
                 if (![self gaveUserPermission:[error userInfo]]) [self requestReadPermissions];
                 else [self showErrorNotAccess];
                 [[WGError sharedInstance] logError:error forAction:WGActionFacebook];
                 return;
             }
             NSArray *nonCleanAlbums = (NSArray *)[result objectForKey:@"data"];
             if (nonCleanAlbums.count == 0) [self requestReadPermissions];
             NSMutableArray *cleanAlbums = [NSMutableArray new];
             for (FBGraphObject *albumFBGraphObject in nonCleanAlbums) {
                 NSString *nameFBAlbum = [albumFBGraphObject objectForKey:@"name"];
                 if ([nameFBAlbum isEqualToString:@"Profile Pictures"] ||  [nameFBAlbum isEqualToString:@"Instagram Photos"]) {
                     [cleanAlbums addObject:albumFBGraphObject];
                     [idAlbumArray addObject:[albumFBGraphObject objectForKey:@"id"]];
                     if ([albumFBGraphObject objectForKey:@"cover_photo"]) [coverIDArray addObject:[albumFBGraphObject objectForKey:@"cover_photo"]];
                 }
             }
             _albumArray = [NSArray arrayWithArray:cleanAlbums];
             [self getAlbumDetails];
             [self.tableView reloadData];

         }];
    }
}


- (void)requestReadPermissions {
    [FBSession.activeSession requestNewReadPermissions:@[@"user_photos"]
                                     completionHandler:^(FBSession *session, NSError *error) {
                                         if (!error) {
                                             if ([FBSession.activeSession.permissions
                                                  indexOfObject:@"user_photos"] == NSNotFound){
                                                 [self showErrorNotAccess];
                                             } else {
                                                 [self getFacebookAlbums];
                                             }
                                             
                                         } else {
                                             [self showErrorNotAccess];
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
        NSString *graphPath = [NSString stringWithFormat:@"/%@", [coverIDArray objectAtIndex:i]];
        [[[FBSDKGraphRequest alloc] initWithGraphPath:graphPath
                                           parameters:nil]
         startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
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
    // Dispose of any resources that can be recreated.
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
    return 60;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    [[cell.contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];

    
    FBGraphObject *albumFBGraphObject = [_albumArray objectAtIndex:[indexPath row]];
    
    UILabel *albumName = [[UILabel alloc] initWithFrame:CGRectMake(75, 20, self.view.frame.size.width - 75, 20)];
    albumName.text = [albumFBGraphObject objectForKey:@"name"];
    albumName.font = [FontProperties lightFont:18.0f];
    albumName.textColor = [UIColor blackColor];
    albumName.textAlignment = NSTextAlignmentLeft;
    [cell.contentView addSubview:albumName];
    
    
    if ([indexPath row] < [coverAlbumArray count]) {
        NSString *imageURL = [coverAlbumArray objectAtIndex:[indexPath row]];
        UIImageView *coverImageView = [[UIImageView alloc] init];
        coverImageView.frame = CGRectMake(10, 10, 45, 45);
        coverImageView.contentMode = UIViewContentModeScaleAspectFill;
        coverImageView.clipsToBounds = YES;
        [coverImageView setImageWithURL:[NSURL URLWithString:imageURL]];
        coverImageView.backgroundColor = [UIColor whiteColor];
        [cell.contentView addSubview:coverImageView];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    int tag = (int)[indexPath row];
    NSString *albumID = [idAlbumArray objectAtIndex:tag];
    [self.navigationController pushViewController:[[FacebookImagesViewController alloc] initWithAlbumID:albumID] animated:YES];
}



@end
