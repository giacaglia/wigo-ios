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

@interface EventPeopleScrollView : UICollectionView <UICollectionViewDataSource, UICollectionViewDelegate, UIGestureRecognizerDelegate>

-(id) initWithEvent:(WGEvent*)event;
-(void) updateUI;
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
@property (nonatomic, assign) int sizeOfEachImage;
@end

#define kScrollViewHeader @"scrollViewHeader"
#define kScrollViewCellName @"scrollViewCellName"
@interface ScrollViewCell : UICollectionViewCell
@property (nonatomic, strong) UIButton *imageButton;
@property (nonatomic, strong) UIImageView *imgView;
@property (nonatomic, strong) UILabel *profileNameLabel;
- (void)setStateForUser:(WGUser *)user;
@end

@interface ScrollViewLayout : UICollectionViewFlowLayout
- (id)initWithSize:(int)size;
@property (nonatomic, assign) int sizeOfFrame;
@end