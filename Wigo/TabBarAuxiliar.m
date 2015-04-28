//
//  TabBarAuxiliar.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 4/24/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import "TabBarAuxiliar.h"
#import "Globals.h"

static UIView *chatOrangeView;
static UIView *friendsOrangeView;
static UIView *profileOrangeView;

@implementation TabBarAuxiliar

+ (UIView *)defaultChatOrangeView {
    if (chatOrangeView == nil) {
        float distance = [UIScreen mainScreen].bounds.size.width/5 * (kIndexOfChats + 0.6f);
        chatOrangeView = [[UIView alloc] initWithFrame:CGRectMake(distance, 3, 12, 12)];
        chatOrangeView.backgroundColor = [FontProperties getOrangeColor];
        chatOrangeView.layer.borderColor = UIColor.clearColor.CGColor;
        chatOrangeView.layer.borderWidth = 1.0f;
        chatOrangeView.layer.cornerRadius = chatOrangeView.frame.size.width/2.0f;
        chatOrangeView.hidden = YES;
        [TabBarAuxiliar addViewToTabBar:chatOrangeView];
    }
    return chatOrangeView;
}

+ (UIView *)defaultFriendsOrangeView {
    if (friendsOrangeView == nil) {
        float distance = [UIScreen mainScreen].bounds.size.width/5 * (kIndexOfFriends + 0.6f);
        friendsOrangeView = [[UIView alloc] initWithFrame:CGRectMake(distance, 3, 12, 12)];
        friendsOrangeView.backgroundColor = [FontProperties getOrangeColor];
        friendsOrangeView.layer.borderColor = UIColor.clearColor.CGColor;
        friendsOrangeView.layer.borderWidth = 1.0f;
        friendsOrangeView.layer.cornerRadius = friendsOrangeView.frame.size.width/2.0f;
        friendsOrangeView.hidden = YES;
        [TabBarAuxiliar addViewToTabBar:friendsOrangeView];
    }
    return friendsOrangeView;
}

+ (UIView *)defaultProfileOrangeView {
    if (friendsOrangeView == nil) {
        float distance = [UIScreen mainScreen].bounds.size.width/5 * (kIndexOfProfile + 0.6f);
        profileOrangeView = [[UIView alloc] initWithFrame:CGRectMake(distance, 3, 12, 12)];
        profileOrangeView.backgroundColor = [FontProperties getOrangeColor];
        profileOrangeView.layer.borderColor = UIColor.clearColor.CGColor;
        profileOrangeView.layer.borderWidth = 1.0f;
        profileOrangeView.layer.cornerRadius = profileOrangeView.frame.size.width/2.0f;
        profileOrangeView.hidden = YES;
        [TabBarAuxiliar addViewToTabBar:profileOrangeView];
    }
    return profileOrangeView;
}


+ (void)addViewToTabBar:(UIView *)view {
    UINavigationController *navigationController = (UINavigationController *)[UIApplication sharedApplication].keyWindow.rootViewController;
    NSArray *viewControllers = navigationController.viewControllers;
    UITabBarController *tabBarController = [viewControllers objectAtIndex:0];
    UITabBar *tabBar = tabBarController.tabBar;
    [tabBar addSubview:view];
}

+ (void)startTabBarItems {
    UINavigationController *navigationController = (UINavigationController *)[UIApplication sharedApplication].keyWindow.rootViewController;
    NSArray *viewControllers = navigationController.viewControllers;
    UITabBarController *tabBarController = [viewControllers objectAtIndex:0];
    UITabBar *tabBar = tabBarController.tabBar;
    UITabBarItem *firstItem = [tabBar.items objectAtIndex:0];
    firstItem.image = [[UIImage imageNamed:@"homeIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    firstItem.selectedImage = [UIImage imageNamed:@"blueHomeIcon"];
    UITabBarItem *secondItem =  [tabBar.items objectAtIndex:1];
    secondItem.image = [[UIImage imageNamed:@"chatTabIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    secondItem.selectedImage = [UIImage imageNamed:@"blueChatsIcon"];
    UITabBarItem *thirdItem = [tabBar.items objectAtIndex:3];
    thirdItem.image = [[UIImage imageNamed:@"friendsIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    thirdItem.selectedImage = [UIImage imageNamed:@"blueFriendsIcon"];
    UITabBarItem *fourthItem = [tabBar.items objectAtIndex:4];
    fourthItem.image = [[UIImage imageNamed:@"profileIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    fourthItem.selectedImage = [UIImage imageNamed:@"blueProfileIcon"];
    [[UITabBarItem appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName : RGB(200, 200, 200) } forState:UIControlStateNormal];
    [[UITabBarItem appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName :[FontProperties getBlueColor] } forState:UIControlStateSelected];

}

+ (void)checkIndex:(int)index ForDate:(NSDate *)date {
    //For chats
    if (index == kIndexOfChats) {
        if (!WGProfile.currentUser.lastMessageRead ||
            [WGProfile.currentUser.lastMessageRead compare:date] == NSOrderedAscending) {
            [TabBarAuxiliar defaultChatOrangeView].hidden = NO;
        }
        else {
            [TabBarAuxiliar defaultChatOrangeView].hidden = YES;
        }
    }
    else if (index == kIndexOfFriends) {
        if (!WGProfile.currentUser.lastUserRead ||
            [WGProfile.currentUser.lastUserRead compare:date] == NSOrderedAscending) {
            [TabBarAuxiliar defaultFriendsOrangeView].hidden = NO;
        }
        else {
            [TabBarAuxiliar defaultFriendsOrangeView].hidden = YES;
        }
    }
    else {
        if (!WGProfile.currentUser.lastNotificationRead ||
            [WGProfile.currentUser.lastNotificationRead compare:date] == NSOrderedAscending) {
            [TabBarAuxiliar defaultProfileOrangeView].hidden = NO;
        }
        else {
            [TabBarAuxiliar defaultProfileOrangeView].hidden = YES;
        }
    }
}


@end
