//
//  EventPeopleModalViewViewController.h
//  Wigo
//
//  Created by Adam Eagle on 2/1/15.
//  Copyright (c) 2015 Adam Eagle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Globals.h"
#import "Delegate.h"

@interface EventPeopleModalViewController : UIViewController
    <UICollectionViewDataSource, UICollectionViewDelegate>

@property BOOL fetchingEventAttendees;
@property UIImage *backgroundImage;
@property int startIndex;
@property UICollectionView *attendeesPhotosScrollView;
@property WGEvent *event;
@property (nonatomic, assign) id <PlacesDelegate> placesDelegate;
- (id)initWithEvent:(WGEvent *)event startIndex:(int)index andBackgroundImage:(UIImage *)image;
@property (nonatomic, assign) CGPoint pointNow;
@end

#define kAttendeesCellName @"attendeesCellName"
@interface AttendeesPhotoCell : UICollectionViewCell
@property (nonatomic, strong) UIButton *imageButton;
@property (nonatomic, strong) UIImageView *imgView;
@property (nonatomic, strong) UILabel *backgroundNameLabel;
@property (nonatomic, strong) UILabel *profileNameLabel;
- (void)setStateForUser:(WGUser *)user;
@end

@interface AttendeesLayout : UICollectionViewFlowLayout
@end
