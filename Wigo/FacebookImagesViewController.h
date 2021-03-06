//
//  FacebookImagesViewController.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 7/7/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>

@interface FacebookImagesViewController : UIViewController

- (id)initWithAlbumID:(NSString *)newAlbumID;
@property (nonatomic, strong) NSMutableArray *profilePicturesURL;
@property (nonatomic, strong) NSMutableArray *imagesArray;


@end
