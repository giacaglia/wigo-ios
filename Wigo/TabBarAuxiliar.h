//
//  TabBarAuxiliar.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 4/24/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kIndexOfChats 1
#define kIndexOfFriends 3
#define kIndexOfProfile 4

@interface TabBarAuxiliar : NSObject

+ (void)clearOutAllNotifications;
+ (void)checkIndex:(int)index forDate:(NSDate *)date;
+ (void)clearIndex:(int)index;
+ (void)startTabBarItems;
+ (UIView *)defaultChatOrangeView;
+ (UIView *)defaultFriendsOrangeView;
+ (UIView *)defaultProfileOrangeView;
+ (NSDate *)biggestFriendsDate;
+ (void)setBiggestFriendsDate:(NSDate *)date;
@end
