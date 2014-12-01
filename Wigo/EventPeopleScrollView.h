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

@protocol PlacesDelegate <NSObject>
- (void)showUser:(User *)user;
- (void)showConversationForEvent:(Event*)event;
@end

@interface EventPeopleScrollView : UIScrollView <UIScrollViewDelegate>
- (id)initWithEvent:(Event*)event;
@property Event *event;
@property (nonatomic, assign) id <PlacesDelegate> placesDelegate;
@property (nonatomic, strong) Party *partyUser;
@end