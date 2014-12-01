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

@interface EventStoryViewController : UIViewController <IQMediaPickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UITextViewDelegate>

@property (nonatomic, strong) Event *event;
@end

@interface StoryFlowLayout : UICollectionViewFlowLayout

@end