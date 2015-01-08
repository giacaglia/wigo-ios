//
//  Delegate.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 12/4/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#ifndef Wigo_Delegate_h
#define Wigo_Delegate_h

#import "WGUser.h"
#import "WGCollection.h"
#import "WGEvent.h"

@protocol UserSelectDelegate <NSObject>
- (void)showUser:(WGUser *)user;
@end

@protocol PlacesDelegate <UserSelectDelegate>
- (void)showHighlights;
- (void)showConversationForEvent:(WGEvent *)event;
- (void)showStoryForEvent:(WGEvent*)event;
- (void)setGroupID:(NSNumber *)groupID andGroupName:(NSString *)groupName;
@property (nonatomic, strong) NSMutableDictionary *eventOffsetDictionary;
@property (nonatomic, assign) BOOL visitedProfile;
- (void)updateEvent:(WGEvent *)newEvent;
@end

@protocol StoryDelegate <NSObject>
- (void)readEventMessageIDArray:(NSArray *)pages;
@end

@protocol EventConversationDelegate <NSObject>
- (void)focusOnContent;
@property (nonatomic, assign) BOOL isFocusing;
- (void)reloadUIForEventMessages:(WGCollection *)eventMessages;
- (void)addLoadingBanner;
- (void)showErrorMessage;
- (void)showCompletedMessage;
- (void)dismissView;
- (void)promptCamera;
@end

#endif
