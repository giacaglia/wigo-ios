//
//  TapViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 7/25/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "TapViewController.h"
#import "Globals.h"
#import "UIImageViewShake.h"
#import "UIButtonAligned.h"

@interface TapViewController ()

@property Party *tapParty;
@property NSDictionary *properties;
@end

@implementation TapViewController

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
    
    _tapParty = [[Party alloc] initWithObjectName:@"User"];
    
    [self initializeLeftBarButton];
    [self initializeTitle];
    [self initializeCollectionView];
    [self initializeTapsLabel];
    [self fetchTaps];
}

- (void) initializeLeftBarButton {
    UIButtonAligned *barBt =[[UIButtonAligned alloc] initWithFrame:CGRectMake(0, 0, 65, 44) andType:@0];
    [barBt setImage:[UIImage imageNamed:@"backIcon"] forState:UIControlStateNormal];
    [barBt setTitle:@" Back" forState:UIControlStateNormal];
    [barBt setTitleColor:[FontProperties getOrangeColor] forState:UIControlStateNormal];
    barBt.titleLabel.font = [FontProperties getSubtitleFont];
    [barBt addTarget:self action: @selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barItem =  [[UIBarButtonItem alloc]init];
    [barItem setCustomView:barBt];
    self.navigationItem.leftBarButtonItem = barItem;
}

- (void) goBack {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) initializeTapsLabel {
    UILabel *tapsLabel = [[UILabel alloc] initWithFrame:CGRectMake(7, 64 + 5, self.view.frame.size.width - 14, 15)];
    tapsLabel.text = @"PEOPLE WHO WANT TO SEE YOU OUT";
    tapsLabel.textAlignment = NSTextAlignmentCenter;
    tapsLabel.font = SC_LIGHT_FONT(14.0f);
    [self.view addSubview:tapsLabel];
}

- (void)initializeTitle {
    self.navigationItem.titleView = nil;
    self.navigationItem.title = @"Taps";
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [FontProperties getOrangeColor], NSFontAttributeName:[FontProperties getTitleFont]};
}

- (void) initializeCollectionView {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumLineSpacing = 5;
    layout.minimumInteritemSpacing = 4;
    layout.headerReferenceSize = CGSizeMake(self.view.frame.size.width, 30);
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0
                                                                         , self.view.frame.size.width, self.view.frame.size.height - 64 - 49) collectionViewLayout:layout];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    [_collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:collectionViewCellIdentifier];
    [_collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:headerCellIdentifier];
    _collectionView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_collectionView];
}

#pragma mark - UICollectionViewDataSource

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:collectionViewCellIdentifier forIndexPath:indexPath];
    if (cell == nil) cell = [[UICollectionViewCell alloc] init];
    cell.contentView.hidden = YES;
    
    NSArray *userArray;
    if ([[_tapParty getObjectArray] count] == 0) return cell;
    userArray = [_tapParty getObjectArray];

    int tag = [indexPath row];
   
    User *user = [userArray objectAtIndex:[indexPath row]];
    
    UIImageView *imgView = [[UIImageView alloc] init];
    imgView.contentMode = UIViewContentModeScaleAspectFill;
    imgView.clipsToBounds = YES;
    [imgView setImageWithURL:[NSURL URLWithString:[user coverImageURL]]];
    imgView.frame = CGRectMake(0, 0, cell.contentView.frame.size.width, cell.contentView.frame.size.height);
    imgView.userInteractionEnabled = YES;
    imgView.alpha = 1.0;
    imgView.tag = tag;
    [cell.contentView addSubview:imgView];
    
    UIButton *profileButton = [[UIButton alloc] initWithFrame:CGRectMake(0, imgView.frame.size.height * 0.5, imgView.frame.size.width, imgView.frame.size.height * 0.5)];
    [imgView bringSubviewToFront:profileButton];
    [imgView addSubview:profileButton];
    
    UILabel *profileName = [[UILabel alloc] init];
    profileName.text = [user firstName];
    profileName.textColor = [UIColor whiteColor];
    profileName.backgroundColor = RGBAlpha(0, 0, 0, 0.6f);
    profileName.textAlignment = NSTextAlignmentCenter;
    profileName.frame = CGRectMake(0, cell.contentView.frame.size.width - 25, cell.contentView.frame.size.width, 25);
    profileName.font = [FontProperties getSmallFont];
    profileName.tag = -1;
    [imgView addSubview:profileName];
    
    if ([user isFavorite]) {
        UIImageView *favoriteSmall = [[UIImageView alloc] initWithFrame:CGRectMake(6, 7, 10, 10)];
        favoriteSmall.image = [UIImage imageNamed:@"favoriteSmall"];
        [profileName addSubview:favoriteSmall];
    }
    
    UIButton *tapButton = [[UIButton alloc] initWithFrame:CGRectMake(imgView.frame.size.width/2, 0, imgView.frame.size.width/2, imgView.frame.size.height/2)];
    [tapButton addTarget:self action:@selector(selectedProfile:) forControlEvents:UIControlEventTouchUpInside];
    [imgView bringSubviewToFront:tapButton];
    [imgView addSubview:tapButton];
    tapButton.enabled = [[Profile user] isGoingOut] ? YES : NO;
    tapButton.tag = tag;
    
    UIImageViewShake *tappedImageView = [[UIImageViewShake alloc] initWithFrame:CGRectMake(imgView.frame.size.width - 30 - 5, 5, 30, 30)];
    tappedImageView.tintColor = [FontProperties getOrangeColor];
    tappedImageView.hidden = [[Profile user] isGoingOut] ? NO : YES;
    if ([user isTapped]) {
        tappedImageView.tag = -1;
        tappedImageView.image = [UIImage imageNamed:@"tapFilled"];
    }
    else {
        tappedImageView.tag = 1;
        tappedImageView.image = [UIImage imageNamed:@"tapUnfilled"];
    }
    [imgView addSubview:tappedImageView];
    
    [user setObject:tapButton forKey:@"tapButton"];
    [user setObject:tappedImageView forKey:@"tappedImageView"];
    cell.contentView.hidden = NO;
    return cell;
}

- (void) selectedProfile:(id)sender {
    UIButton *buttonSender = (UIButton *)sender;
    int tag = buttonSender.tag;
    UIImageView *imageView = (UIImageView *)[buttonSender superview];
    
    for (UIView *subview in imageView.subviews)
    {
        if (subview.tag == 1) {
            if ([subview isMemberOfClass:[UIImageViewShake class]]) {
                UIImageViewShake *imageView = (UIImageViewShake *)subview;
                [imageView newShake];
                imageView.image = [UIImage imageNamed:@"tapFilled"];
                subview.tag = -1;
                [self sendTapToUserWithTag:tag];
            }
        }
        else if (subview.tag == -1) {
            if ([subview isMemberOfClass:[UIImageViewShake class]]) {
                UIImageView *imageView = (UIImageView *)subview;
                imageView.image = [UIImage imageNamed:@"tapUnfilled"];
                subview.tag = 1;
            }
        }
    }
}

- (void) sendTapToUserWithTag:(int)tag {
    User *user = [[_tapParty getObjectArray] objectAtIndex:tag];
    if (![user isTapped]) {
        [Network sendTapToUserWithIndex:[user objectForKey:@"id"]];
    }
}

#pragma mark - UICollectionViewDelegate

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    int NImages = 3;
    int distanceOfEachImage = 4;
    int totalDistanceOfAllImages = distanceOfEachImage * (NImages - 1); // 10 pts is the distance of each image
    int sizeOfEachImage = self.view.frame.size.width - totalDistanceOfAllImages; // 10 pts on the extreme left and extreme right
    sizeOfEachImage /= NImages;
    return CGSizeMake(sizeOfEachImage, sizeOfEachImage);
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [[_tapParty getObjectArray] count];
}

#pragma mark - Network Functions

- (void)fetchTaps {
    [Network queryAsynchronousAPI:@"taps/?date=tonight&ordering=-id&tapped=me" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            
            NSArray *arrayOfFollowObjects = [jsonResponse objectForKey:@"objects"];
            NSMutableArray *arrayOfUsers = [[NSMutableArray alloc] initWithCapacity:[arrayOfFollowObjects count]];
            for (NSDictionary *object in arrayOfFollowObjects) {
                NSDictionary *userDictionary = [object objectForKey:@"user"];
                if ([userDictionary isKindOfClass:[NSDictionary class]]) {
                    if ([Profile isUserDictionaryProfileUser:userDictionary]) {
                        [arrayOfUsers addObject:[[Profile user] dictionary]];
                    }
                    else {
                        [arrayOfUsers addObject:userDictionary];
                    }
                }
            }
            [_tapParty addObjectsFromArray:arrayOfUsers];
            [_collectionView reloadData];
//            if ([[jsonResponse allKeys] containsObject:@"total"]) {
//                NSNumber *totalNumberOfPeople = [jsonResponse objectForKey:@"total"];
//                [_yourSchoolButton setTitle:[NSString stringWithFormat:@"%d\nSchool", [totalNumberOfPeople intValue]] forState:UIControlStateNormal];
//            }
        });
    }];
}



@end
