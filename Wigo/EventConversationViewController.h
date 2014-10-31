//
//  EventConversationViewController.h
//  Wigo
//
//  Created by Alex Grinman on 10/17/14.
//  Copyright (c) 2014 Alex Grinman. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "Globals.h"

@interface EventConversationViewController : UIViewController<UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
@property (nonatomic, strong) Event *event;
@property (nonatomic, strong) NSMutableArray *eventMessages;
@property (nonatomic, strong) UICollectionView *facesCollectionView;
@end

@interface FaceCell : UICollectionViewCell

@property (nonatomic, assign) BOOL rightLineEnabled;
@property (nonatomic, assign) BOOL isActive;
@property (nonatomic)
@end


@interface FaceLayout : UICollectionViewLayout

@end