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
#import "WGMessage.h"

@protocol UserSelectDelegate <NSObject>
- (void)showUser:(WGUser *)user;
@end

@protocol PlacesDelegate <UserSelectDelegate>
- (void)showHighlights;
- (void)showConversationForEvent:(WGEvent *)event
               withEventMessages:(WGCollection *)eventMessages
                         atIndex:(int)index;
- (void)showConversationForEvent:(WGEvent *)event;
- (void)showStoryForEvent:(WGEvent*)event;
- (void)setGroupID:(NSNumber *)groupID andGroupName:(NSString *)groupName;
- (void)presentViewWithGroupID:(NSNumber *)groupID andGroupName:(NSString *)groupName;
- (void)showModalAttendees:(UIViewController *)modal;
- (void)showViewController:(UIViewController *)vc;
@property (nonatomic, strong) NSMutableDictionary *eventOffsetDictionary;
- (void)updateEvent:(WGEvent *)newEvent;
@property (nonatomic, assign) BOOL doNotReloadOffsets;
- (void)invitePressed;
- (void)showOverlayForInvite:(id)sender;
- (void)goHerePressed:(id)sender withHandler:(BoolResultBlock)handler;
- (void)presentConversationForUser:(WGUser *)user;
- (void)presentUserAferModalView:(WGUser *)user forEvent:(WGEvent *)event;
- (void)scrollUp;
@end

@protocol PrivacySwitchDelegate <NSObject>
- (void)updateUnderliningText;
@end

@protocol StoryDelegate <NSObject>
- (void)readEventMessageIDArray:(NSArray *)pages;
@end

@protocol EventConversationDelegate <NSObject>
- (void)focusOnContent;
- (void)upvotePressed;
@property (nonatomic, assign) BOOL isFocusing;
- (void)reloadUIForEventMessages:(WGCollection *)eventMessages;
- (void)addLoadingBanner;
- (void)showErrorMessage;
- (void)showCompletedMessage;
- (void)dismissView;
- (void)promptCamera;
- (void)presentUser:(WGUser *)user
           withView:(UIView *)view
      withStartFrame:(CGRect)startFrame;
- (void)dimOutToPercentage:(float)percentage;
- (void)createBlurViewUnderView:(UIView *)view;
- (void)presentHoleOnTopOfView:(UIView *)view;
@property (nonatomic, strong) UIButton *buttonCancel;
@end

@protocol ConversationCellDelegate <NSObject>
- (void)addMessageFromSender:(WGMessage *)message;
@end

@protocol PeopleViewDelegate <NSObject>
- (void)presentUser:(WGUser *)user;
- (void)updateButton:(id)sender withUser:(WGUser *)user;
@end

@protocol CameraDelegate <NSObject>
- (void)presentFocusPoint:(CGPoint)focusPoint;
@end

@protocol InviteCellDelegate
- (void) inviteTapped;
@optional
@property State userState;
@end

@protocol EventPeopleModalDelegate
- (void)chatPressed:(id)sender;
- (void)followPressed:(id)sender;
@end

#endif
