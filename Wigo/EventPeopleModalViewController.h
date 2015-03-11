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
#import "InviteView.h"

@interface EventPeopleModalViewController : UIViewController
    <UICollectionViewDataSource, UICollectionViewDelegate,
    EventPeopleModalDelegate>
@property (nonatomic, assign) BOOL isPeeking;
@property (nonatomic, assign) BOOL fetchingEventAttendees;
@property (nonatomic, strong) UIImage *backgroundImage;
@property (nonatomic, assign) int startIndex;
@property (nonatomic, strong) UICollectionView *attendeesPhotosScrollView;
@property (nonatomic, strong) WGEvent *event;
@property (nonatomic, assign) id <PlacesDelegate> placesDelegate;
@property (nonatomic, assign) CGPoint pointNow;
- (id)initWithEvent:(WGEvent *)event startIndex:(int)index andBackgroundImage:(UIImage *)image;
@end

#define kAttendeesCellName @"attendeesCellName"
@interface AttendeesPhotoCell : UICollectionViewCell <InviteCellDelegate>
@property (nonatomic, strong) UIButton *imageButton;
@property (nonatomic, strong) UIImageView *imgView;
@property (nonatomic, strong) UILabel *backgroundNameLabel;
@property (nonatomic, strong) UILabel *profileNameLabel;
@property (nonatomic, strong) InviteView *inviteView;
@property (nonatomic, strong) UIButton *chatButton;
@property (nonatomic, strong) UIButton *followButton;
@property (nonatomic, assign) id<EventPeopleModalDelegate> eventPeopleModalDelegate;
@property (nonatomic, strong ) WGUser *user;
- (void)inviteTapped;
@end

@interface AttendeesLayout : UICollectionViewFlowLayout
@end
