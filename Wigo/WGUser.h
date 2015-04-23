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
    PRIVATE_STATE,
    PUBLIC_STATE,
    NOT_FOLLOWING_PUBLIC_USER_STATE,
    FOLLOWING_USER_STATE,
    ATTENDING_EVENT_FOLLOWING_USER_STATE,
    NOT_SENT_FOLLOWING_PRIVATE_USER_STATE,
    NOT_YET_ACCEPTED_PRIVATE_USER_STATE,
    ACCEPTED_PRIVATE_USER_STATE,
    ATTENDING_EVENT_ACCEPTED_PRIVATE_USER_STATE,
    BLOCKED_USER_STATE,
    OTHER_SCHOOL_USER_STATE
} State;

@interface WGUser : WGObject <JSQMessageAvatarImageDataSource>

typedef void (^WGUserResultBlock)(WGUser *object, NSError *error);

@property NSString* key;
@property (nonatomic, assign) Privacy privacy;
@property NSNumber* isTapped;
@property NSNumber* isBlocked;
@property NSNumber* isBlocking;
@property NSNumber* emailValidated;
@property NSString* bio;
@property NSString* image;
@property NSDate* modified;
@property NSNumber* isFriend;
@property NSString* friendRequest;
@property NSString* lastName;
@property NSNumber* isGoingOut;
@property NSNumber* lastMessageRead;
@property NSNumber* lastNotificationRead;
@property NSNumber* lastUserRead;
@property NSNumber* periodWentOut;

@property NSDictionary* properties;
@property NSArray* images;
@property NSString *instaHandle;
@property NSArray *triggers;
@property BOOL findReferrer;
@property NSArray *arrayTooltipTracked;
@property NSDictionary *events;

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

@property UIImageView *avatarView;

+(WGUser *)serialize:(NSDictionary *)json;

-(NSString *) privacyName;
-(NSString *) genderName;
+(Gender) genderFromName:(NSString *)name;
-(NSString *) fullName;

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
+(void) searchUsers:(NSString *)query withHandler:(WGCollectionResultBlock)handler;
+(void) getSuggestions:(WGCollectionResultBlock)handler;
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
-(void) tapUser:(WGUser *)user withHandler:(BoolResultBlock)handler;
-(void) tapAllUsersWithHandler:(BoolResultBlock)handler;
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

@end
