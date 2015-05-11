//
//  EventPeopleScrollView.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 10/29/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WGEvent.h"
#import "Delegate.h"
#import "EventPeopleModalViewController.h"
typedef enum  {
    STARTED_ANIMATION_AND_NETWORK,
    ONE_OF_THEM_IS_CONCLUDED,
    BOTH_OF_THEM_ARE_DONE
} AnimationState;

#define kScrollViewHeader @"scrollViewHeader"
#define kScrollViewCellName @"scrollViewCellName"
#define kInviteSection 0
#define kPeopleSection 1
@interface ScrollViewCell : UICollectionViewCell
@property (nonatomic, strong) WGUser *user;
@property (nonatomic, strong) UIButton *imageButton;
@property (nonatomic, strong) UIImageView *imgView;
@property (nonatomic, strong) UILabel *imgViewLabel;
@property (nonatomic, strong) UILabel *profileNameLabel;
@property (nonatomic, strong) UIView *blueOverlayView;
@property (nonatomic, strong) UILabel *goHereLabel;
@end

@interface EventPeopleScrollView : UICollectionView <UICollectionViewDataSource, UICollectionViewDelegate, UIGestureRecognizerDelegate>

+(CGFloat) containerHeight;
-(void) scrollToSavedPosition;
-(void) saveScrollPosition;


@property EventPeopleModalViewController *eventPeopleModalViewController;
@property (nonatomic, assign) id <UserSelectDelegate> userSelectDelegate;
@property (nonatomic, assign) id <PlacesDelegate> placesDelegate;
@property (nonatomic, strong) NSNumber *groupID;
@property (nonatomic, assign) int eventOffset;
@property (nonatomic, assign) BOOL fetchingEventAttendees;
@property (nonatomic, strong) NSNumber *page;
@property (nonatomic, assign) int xPosition;
@property (nonatomic, strong) WGEvent *event;
@property (nonatomic, assign) int widthOfEachCell;
@property (nonatomic, assign) int rowOfEvent;
@property (nonatomic, assign) BOOL isPeeking;
@property (nonatomic, assign) BOOL isOld;

@property (nonatomic, strong) UIButton *hiddenInviteButton;
@property (nonatomic, assign) AnimationState animationState;
@property (nonatomic, strong) ScrollViewCell *scrollCell;
@end



@interface ScrollViewLayout : UICollectionViewFlowLayout
- (id)initWithWidth:(int)width;
@property (nonatomic, assign) int widthOfFrame;
@end