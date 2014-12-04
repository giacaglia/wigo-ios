//
//  EventStoryViewController.h
//  Wigo
//
//  Created by Alex Grinman on 10/24/14.
//  Copyright (c) 2014 Alex Grinman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Globals.h"
#import "IQMediaPickerController.h"
#import "EventPeopleScrollView.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface EventStoryViewController : UIViewController <IQMediaPickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UITextViewDelegate>
@property (nonatomic, strong) Event *event;
@property (nonatomic, strong) MPMoviePlayerController *moviePlayer;
@property (nonatomic, strong) NSData *fileData;
@property (nonatomic, strong) NSDictionary *options;
@property (nonatomic, strong) EventPeopleScrollView *eventPeopleScrollView;
@end

@interface StoryFlowLayout : UICollectionViewFlowLayout

@end