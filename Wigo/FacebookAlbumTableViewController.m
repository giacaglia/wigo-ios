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

@interface FacebookAlbumTableViewController ()

@property NSArray *albumArray;

@end

NSMutableArray *idAlbumArray;
NSMutableArray *coverIDArray;
NSMutableArray *coverAlbumArray;

@implementation FacebookAlbumTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        _albumArray = [NSArray new];
        idAlbumArray = [NSMutableArray new];
        coverIDArray = [NSMutableArray new];
        coverAlbumArray = [NSMutableArray new];
        self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [WiGoSpinnerView addDancingGToCenterView:self.view];
    [FBSession openActiveSessionWithReadPermissions:@[@"public_profile", @"email", @"user_friends", @"user_photos"]
                                       allowLoginUI:YES
                                  completionHandler:^(FBSession *session,
                                                      FBSessionState state,
                                                      NSError *error) {
                                      if (error) {
                                          UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                                              message:error.localizedDescription
                                                                                             delegate:nil
                                                                                    cancelButtonTitle:@"OK"
                                                                                    otherButtonTitles:nil];
                                          [alertView show];
                                      } else if (session.isOpen) {
                                              [FBRequestConnection startWithGraphPath:@"/me/albums"
                                                                           parameters:nil
                                                                           HTTPMethod:@"GET"
                                                                    completionHandler:^(
                                                                                        FBRequestConnection *connection,
                                                                                        id result,
                                                                                        NSError *error
                                                                                        ) {
                                                                        dispatch_async(dispatch_get_main_queue(), ^(void){
                                                                            NSArray *nonCleanAlbums = (NSArray *)[result objectForKey:@"data"];
                                                                            NSMutableArray *cleanAlbums = [NSMutableArray new];
                                                                            for (FBGraphObject *albumFBGraphObject in nonCleanAlbums) {
                                                                                NSString *nameFBAlbum = [albumFBGraphObject objectForKey:@"name"];
                                                                                if ([nameFBAlbum isEqualToString:@"Profile Pictures"] ||
                                                                                    [nameFBAlbum isEqualToString:@"Instagram Photos"]) {
                                                                                    [cleanAlbums addObject:albumFBGraphObject];
                                                                                    [idAlbumArray addObject:[albumFBGraphObject objectForKey:@"id"]];
                                                                                    [coverIDArray addObject:[albumFBGraphObject objectForKey:@"cover_photo"]];
                                                                                }
                                                                            }
                                                                            _albumArray = [NSArray arrayWithArray:cleanAlbums];
                                                                            [WiGoSpinnerView removeDancingGFromCenterView:self.view];

                                                                            [self getAlbumDetails];
                                                                            [self.tableView reloadData];
                                                                        });
                                                                    }];
                                      }
                                  }];
    
}

- (void)getAlbumDetails {
    for (int k = 0; k < [coverIDArray count]; k++) {
        [coverAlbumArray addObject:@""];
    }
    for (int i = 0; i < [coverIDArray count]; i++) {
        NSString *photoID = [coverIDArray objectAtIndex:i];
        [FBRequestConnection startWithGraphPath:[NSString stringWithFormat:@"/%@", photoID]
                                     parameters:nil
                                     HTTPMethod:@"GET"
                              completionHandler:^(
                                                  FBRequestConnection *connection,
                                                  id result,
                                                  NSError *error
                                                  ) {
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
