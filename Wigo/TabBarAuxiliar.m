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
static NSDate *biggestDate;

@implementation TabBarAuxiliar

+(void) clearOutAllNotifications {
    WGProfile.currentUser.lastMessageRead = [NSDate date];
    WGProfile.currentUser.lastUserRead = [NSDate date];
    WGProfile.currentUser.lastNotificationRead = [NSDate date];
}

+(NSDate *) biggestFriendsDate {
    return biggestDate;
}

+(void) setBiggestFriendsDate:(NSDate *)date {
    biggestDate = date;
}

+(UIView *) defaultChatOrangeView {
    if (chatOrangeView == nil) {
        float distance = [UIScreen mainScreen].bounds.size.width/5 * (kIndexOfChats + 0.65f);
        chatOrangeView = [[UIView alloc] initWithFrame:CGRectMake(distance, 3, 10, 10)];
        chatOrangeView.backgroundColor = [FontProperties getOrangeColor];
        chatOrangeView.layer.borderColor = UIColor.clearColor.CGColor;
        chatOrangeView.layer.borderWidth = 1.0f;
        chatOrangeView.layer.cornerRadius = chatOrangeView.frame.size.width/2.0f;
        chatOrangeView.hidden = YES;
        [TabBarAuxiliar addViewToTabBar:chatOrangeView];
    }
    return chatOrangeView;
}

+(UIView *) defaultFriendsOrangeView {
    if (friendsOrangeView == nil) {
        float distance = [UIScreen mainScreen].bounds.size.width/5 * (kIndexOfFriends + 0.65f);
        friendsOrangeView = [[UIView alloc] initWithFrame:CGRectMake(distance, 3, 10, 10)];
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
    if (profileOrangeView == nil) {
        float distance = [UIScreen mainScreen].bounds.size.width/5 * (kIndexOfProfile + 0.65f);
        profileOrangeView = [[UIView alloc] initWithFrame:CGRectMake(distance, 3, 10, 10)];
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
    [tabBar setFrame:CGRectMake(tabBar.frame.origin.x, tabBar.frame.origin.y + 5, tabBar.frame.size.width, tabBar.frame.size.height - 5)];
    tabBar.translucent = NO;

    [TabBarAuxiliar addTabBarImage:@"homeIcon"
                     withBlueImage:@"blueHomeIcon" atIndex:0 atTabBar:tabBar];

    [TabBarAuxiliar addTabBarImage:@"chatTabIcon"
                     withBlueImage:@"blueChatsIcon" atIndex:1 atTabBar:tabBar];
    
    UITabBarItem *item = [tabBar.items objectAtIndex:2];
    item.enabled = NO;
    
    [TabBarAuxiliar addTabBarImage:@"friendsIcon"
                     withBlueImage:@"blueFriendsIcon" atIndex:3 atTabBar:tabBar];

    [TabBarAuxiliar addTabBarImage:@"profileIcon"
                     withBlueImage:@"blueProfileIcon" atIndex:4 atTabBar:tabBar];

    [[UITabBarItem appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName : RGB(200, 200, 200) } forState:UIControlStateNormal];
    [[UITabBarItem appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName :[FontProperties getBlueColor] } forState:UIControlStateSelected];

}

+(void)addTabBarImage:(NSString *)imageName
        withBlueImage:(NSString *)blueImage
              atIndex:(int)index
             atTabBar:(UITabBar *)tabBar;
{
    UITabBarItem *item = [tabBar.items objectAtIndex:index];
    item.image = [[UIImage imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    item.imageInsets = UIEdgeInsetsMake(-2, 0, 2, 0);
    item.selectedImage = [UIImage imageNamed:blueImage];
    item.titlePositionAdjustment = UIOffsetMake(0.0, -6.0);
}

+ (void)checkIndex:(int)index forDate:(NSDate *)date {
    if (!date) return;
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
        [TabBarAuxiliar setBiggestFriendsDate:date];
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

+ (void)clearIndex:(int)index {
    if (index == kIndexOfFriends) {
        if ([TabBarAuxiliar biggestFriendsDate] == nil) return;
        WGProfile.currentUser.lastUserRead = [TabBarAuxiliar biggestFriendsDate];
        [TabBarAuxiliar defaultFriendsOrangeView].hidden = YES;
    }
}


@end
