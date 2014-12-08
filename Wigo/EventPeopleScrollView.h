//
//  EventPeopleScrollView.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 10/29/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Event.h"
#import "Party.h"
#import "Delegate.h"

@interface EventPeopleScrollView : UIScrollView <UIScrollViewDelegate>
- (id)initWithEvent:(Event*)event;
@property (nonatomic, assign) id <PlacesDelegate> placesDelegate;
@property (nonatomic, strong) Party *partyUser;
@property (nonatomic, strong) NSNumber *groupID;
- (void)updateUI;
@property (nonatomic, assign) int eventOffset;

@property (nonatomic, assign) BOOL fetchingEventAttendees;
@property (nonatomic, strong) NSNumber *page;
@property (nonatomic, assign) int xPosition;
@property (nonatomic, strong) Event *event;
@end