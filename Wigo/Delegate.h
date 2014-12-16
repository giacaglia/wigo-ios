//
//  Delegate.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 12/4/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#ifndef Wigo_Delegate_h
#define Wigo_Delegate_h

#import "User.h"
#import "Event.h"

@protocol UserSelectDelegate <NSObject>
- (void)showUser:(User *)user;
@end

@protocol PlacesDelegate <UserSelectDelegate>
- (void)showConversationForEvent:(Event *)event;
- (void)showStoryForEvent:(Event*)event;
- (void)setGroupID:(NSNumber *)groupID andGroupName:(NSString *)groupName;
@property (nonatomic, strong) NSMutableDictionary *eventOffsetDictionary;
- (void)updateEvent:(Event *)newEvent;
@end

@protocol StoryDelegate <NSObject>
- (void)readEventMessageIDArray:(NSArray *)pages;
@end

@protocol EventConversationDelegate <NSObject>
- (void)focusOnContent;
@property (nonatomic, assign) BOOL isFocusing;
- (void)reloadUIForEventMessages:(NSMutableArray *)eventMessages;
- (void)addLoadingBanner;
- (void)showErrorMessage;
- (void)showCompletedMessage;
- (void)dismissView;
- (void)promptCamera;
@end

#endif
