//
//  EventStoryViewController.h
//  Wigo
//
//  Created by Alex Grinman on 10/24/14.
//  Copyright (c) 2014 Alex Grinman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Globals.h"
#import "EventPeopleScrollView.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "Delegate.h"
#import "EventConversationViewController.h"

typedef enum
{
    PRESENTFACESTATE,
    FIRSTTIMEPRESENTCAMERASTATE,
    SECONDTIMEPRESENTCAMERASTATE,
    DONOTPRESENTANYTHINGSTATE
} GOHERESTATE;

@interface EventStoryViewController : UIViewController
    <UINavigationControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UITextViewDelegate, StoryDelegate, UserSelectDelegate>
@property (nonatomic, strong) NSNumber *groupNumberID;
@property (nonatomic, strong) WGEvent *event;
@property (nonatomic, strong) MPMoviePlayerController *moviePlayer;
@property (nonatomic, strong) NSData *fileData;
@property (nonatomic, strong) NSDictionary *options;
@property (nonatomic, strong) EventPeopleScrollView *eventPeopleScrollView;
@property (nonatomic, strong) UILabel *numberGoingLabel;
@property (nonatomic, strong) UIButton *inviteButton;
@property (nonatomic, strong) UIButton *goHereButton;
@property (nonatomic, strong) EventConversationViewController *conversationViewController;
@property (nonatomic, strong) id<PlacesDelegate> placesDelegate;
- (void)presentFirstTimeGoingToEvent;

@property (nonatomic, assign) BOOL cancelFetchMessages;
@property (nonatomic, strong) WGCollection *eventMessages;
@property (nonatomic, strong) UICollectionView *facesCollectionView;
@property (nonatomic, strong) UIVisualEffectView *visualEffectView;

@end

@interface StoryFlowLayout : UICollectionViewFlowLayout

@end