//
//  FacebookAlbumTableViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 7/7/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "FacebookAlbumTableViewController.h"
#import "Profile.h"
#import "SDWebImage/UIImageView+WebCache.h"
#import "UIImageCrop.h"

@interface FacebookAlbumTableViewController ()

@property NSArray *albumArray;

@end

@implementation FacebookAlbumTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        _albumArray = [[NSArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
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
                                                                    _albumArray = (NSArray *)[result objectForKey:@"data"];
                                                                    [self.tableView reloadData];
                                                                }];

                                      }
                                  }];
    
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
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    FBGraphObject *albumFBGraphObject = [_albumArray objectAtIndex:[indexPath row]];
    
    UILabel *albumName = [[UILabel alloc] initWithFrame:CGRectMake(75, 20, self.view.frame.size.width - 75, 20)];
    albumName.text = [albumFBGraphObject objectForKey:@"name"];
    albumName.font = [UIFont fontWithName:@"Whitney-Light" size:18.0f];
    albumName.textColor = [UIColor blackColor];
    albumName.textAlignment = NSTextAlignmentLeft;
    [cell.contentView addSubview:albumName];
    
    NSString *imageURL = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=album&access_token=%@", [albumFBGraphObject objectForKey:@"id"], [[Profile user] accessToken]];
    UIImageView *coverImageView = [[UIImageView alloc] init];
    coverImageView.frame = CGRectMake(10, 10, 45, 45);
    coverImageView.contentMode = UIViewContentModeScaleAspectFill;
    coverImageView.clipsToBounds = YES;
    [coverImageView setImageWithURL:[NSURL URLWithString:imageURL]];
    coverImageView.backgroundColor = [UIColor whiteColor];
    [cell.contentView addSubview:coverImageView];
    
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
