//
//  EventConversationViewController.h
//  Wigo
//
//  Created by Alex Grinman on 10/17/14.
//  Copyright (c) 2014 Alex Grinman. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "Globals.h"
#import "ImagesScrollView.h"

@interface EventConversationViewController : UIViewController<UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
@property (nonatomic, strong) Event *event;
@property (nonatomic, strong) NSMutableArray *eventMessages;
@property (nonatomic, strong) ImagesScrollView *imagesScrollView;
@property (nonatomic, strong) IBOutlet UICollectionView *facesCollectionView;
@end

@interface FaceCell : UICollectionViewCell

- (void) resetToInactive;

@property (nonatomic, assign) BOOL rightLineEnabled;
@property (nonatomic, assign) BOOL isActive;
@property (nonatomic, strong) UIImageView *faceImageView;

@property (nonatomic, strong) UIView *rightLine;

@end

@interface FaceFlowLayout : UICollectionViewFlowLayout

@end