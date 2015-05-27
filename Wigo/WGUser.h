//
//  WGUser.h
//  Wigo
//
//  Created by Adam Eagle on 12/15/14.
//  Copyright (c) 2014 Adam Eagle. All rights reserved.
//

#import "WGObject.h"
#import "WGCollection.h"
#import "WGGroup.h"
#import "JSQMessagesViewController/JSQMessages.h"

#define kFriendRequestSent @"sent"
#define kFriendRequestReceived @"received"
#define kPropertiesKey @"properties"

#define kStatusWaiting @"waiting"
#define kStatusImported @"imported"

@class WGEvent;

typedef enum Gender {
    MALE,
    FEMALE,
    UNKNOWN
} Gender;

typedef enum Privacy {
    PUBLIC,
    PRIVATE,
    OTHER
} Privacy;

typedef enum State {
    NOT_LOADED_STATE,
    CURRENT_USER_STATE,
    NOT_FRIEND_STATE,
    FRIEND_USER_STATE,
    BLOCKED_USER_STATE,
    OTHER_SCHOOL_USER_STATE,
    SENT_REQUEST_USER_STATE,
    RECEIVED_REQUEST_USER_STATE
} State;

@interface WGUser : WGObject <JSQMessageAvatarImageDataSource>

typedef void (^WGUserResultBlock)(WGUser *object, NSError *error);

@property NSString* key;
@property (nonatomic, assign) Privacy privacy;
@property NSNumber *isInvited;
@property NSNumber* isTapped;
@property BOOL isFriendRequestRead;
@property NSNumber* isBlocked;
@property NSNumber* isBlocking;
@property NSString* bio;
@property NSString* image;
@property NSDate* modified;

@property NSString* lastName;
@property NSNumber* isGoingOut;
@property NSDate* lastMessageRead;
@property NSDate* lastNotificationRead;
@property NSDate* lastUserRead;

@property NSDictionary* properties;
@property NSArray* images;
@property NSString* instaHandle;
@property NSString* hometown;
@property NSString* work;
@property NSString* education;
@property NSString* birthday;
@property NSArray* triggers;
@property BOOL findReferrer;
@property NSArray* arrayTooltipTracked;
@property NSDictionary* events;

@property NSString* firstName;
@property (nonatomic, assign) Gender gender;
@property NSString* email;
@property NSString* facebookId;
@property NSString* facebookAccessToken;
@property NSNumber* numFriends;
@property NSString* username;
@property WGEvent* eventAttending;
@property WGGroup* group;
@property NSNumber* groupRank;
@property NSNumber* isTapPushNotificationEnabled;

@property NSNumber* numUnreadConversations;
@property NSNumber* numUnreadNotifications;
@property NSNumber* numUnreadUsers;
@property NSNumber *numMutualFriends;
@property NSString *status;
@property NSDictionary *friendsMetaDict;
@property UIImageView *avatarView;

// meta properties
-(void) setFriendsIds:(NSArray*)friendsIds;
@property NSNumber* isFriend;
@property NSString* friendRequest;
- (void)setMetaObject:(id)object forKey:(NSString *)key;
- (id)metaObjectForKey:(NSString *)key;


+(WGUser *)serialize:(NSDictionary *)json;

-(NSString *) privacyName;
-(NSString *) genderName;
+(Gender) genderFromName:(NSString *)name;
-(NSString *) fullName;
-(NSString *) age;
-(NSNumber *) waitListPos;

-(State) state;


-(void) addTootltipTracked:(NSString *)tooltipTracked;
-(void) setReferredBy:(NSNumber *)referredByNumber;
-(void) setImageDictionary:(NSDictionary *)imageDictionary forIndex:(NSInteger)index;
-(void) removeImageAtIndex:(NSInteger)index;
-(void) makeImageAtIndexCoverImage:(NSInteger)index;
-(NSURL *) coverImageURL;
-(NSURL *) smallCoverImageURL;
-(NSDictionary *) coverImageArea;
-(NSDictionary *) smallCoverImageArea;
-(NSArray *) imagesArea;
-(NSArray *) imagesURL;
-(NSArray *) smallImagesURL;
-(void) addImageURL:(NSString *)imageURL;
-(void) addImageDictionary:(NSDictionary *)imageDictionary;
-(void) followUser;

-(BOOL) isCurrentUser;

+(void) getOrderedById:(WGCollectionResultBlock)handler;
+(void) getNewestUser:(WGUserResultBlock)handler;
+(void) getReferals:(WGCollectionResultBlock)handler;
+(void) getOnboarding:(WGCollectionResultBlock)handler;
+(void) searchUsers:(NSString *)query withHandler:(WGSerializedCollectionResultBlock)handler;
+(void) getSuggestions:(WGCollectionResultBlock)handler;
+(void) getLikesForEvent:(WGEvent *)event
         andEventMessage:(WGObject *)message
             withHandler:(WGCollectionResultBlock)handler;
+(void) getInvites:(WGCollectionResultBlock)handler;
+(void) searchInvites:(NSString *)query withHandler:(WGCollectionResultBlock)handler;

-(void) getFriends:(WGCollectionResultBlock)handler;
-(void) getFriendRequests:(WGCollectionResultBlock)handler;
-(void) getNumMutualFriends:(WGNumResultBlock)handler;
-(void) getMeta:(BoolResultBlock)handler;
-(void) getMutualFriends:(WGCollectionResultBlock)handler;
-(void) getNotMeForMessage:(WGCollectionResultBlock)handler;
+(void) searchReferals:(NSString *)query withHandler:(WGSerializedCollectionResultBlock)handler;
-(void) searchNotMe:(NSString *)query withContext:(NSString *)contextString withHandler:(WGCollectionResultBlock)handler;
-(void) searchNotMe:(NSString *)query withHandler:(WGCollectionResultBlock)handler;
-(void) friendUser:(WGUser *)user withHandler:(BoolResultBlock)handler;
-(void) unfollow:(WGUser *)user withHandler:(BoolResultBlock)handler;
-(void) acceptFriendRequestFromUser:(WGUser *)user withHandler:(BoolResultBlock)handler;
-(void) rejectFriendRequestForUser:(WGUser *)user withHandler:(BoolResultBlock)handler;
-(void)inviteUser:(WGUser *)user
          atEvent:(WGEvent *)event
      withHandler:(BoolResultBlock)handler;
-(void) tapUser:(WGUser *)user withHandler:(BoolResultBlock)handler;
-(void) tapAllUsersToEvent:(WGEvent *)event  withHandler:(BoolResultBlock)handler;
-(void) tapUsers:(WGCollection *)users withHandler:(BoolResultBlock)handler;
-(void) untap:(WGUser *)user withHandler:(BoolResultBlock)handler;
-(void) sendInvites:(NSArray *)numbers withHandler:(BoolResultBlock)handler;
-(void) unblock:(WGUser *)user withHandler:(BoolResultBlock)handler;
-(void) block:(WGUser *)user withType:(NSString *)type andHandler:(BoolResultBlock)handler;
-(void) goingOut:(BoolResultBlock)handler;
-(void) goingToEvent:(WGEvent *)event withHandler:(BoolResultBlock)handler;
-(void) readConversation:(BoolResultBlock)handler;
-(void) deleteConversation:(BoolResultBlock)handler;
-(void) getConversation:(WGCollectionResultBlock)handler;
-(void) refetchUserWithGroup:(NSNumber *)groupID andHandler:(BoolResultBlock)handler;
-(void) broadcastMessage:(NSString *) message withHandler:(BoolResultBlock)handler;
-(void) resendVerificationEmail:(BoolResultBlock) handler;

#pragma mark - Meta objects
@property (nonatomic, strong) NSDictionary *dayMetaUserProperties;
-(void) setDayMetaObject:(id)object forKey:(NSString *)key;
-(id) dayMetaObjectForKey:(NSString *)key;
@end
