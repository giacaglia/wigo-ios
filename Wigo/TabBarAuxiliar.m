//
//  TabBarAuxiliar.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 4/24/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import "TabBarAuxiliar.h"
#import "Globals.h"

@implementation TabBarAuxiliar


+ (void)checkIndex:(int)index ForDate:(NSDate *)date {
    //For chats
    if (index == kIndexOfChats) {
        if ([WGProfile.currentUser.lastMessageRead compare:date] == NSOrderedAscending) {
            [TabBarAuxiliar addNotificationTo:kIndexOfChats];
        }
    }
    else if (index == kIndexOfFriends) {
        if ([WGProfile.currentUser.lastUserRead compare:date] == NSOrderedAscending) {
            [TabBarAuxiliar addNotificationTo:kIndexOfFriends];
        }
    }
    else {
        if ([WGProfile.currentUser.lastNotificationRead compare:date] == NSOrderedAscending) {
            [TabBarAuxiliar addNotificationTo:kIndexOfProfile];
        }
    }
}

+ (void)addNotificationTo:(int)index {
    UINavigationController *navigationController = (UINavigationController *)[UIApplication sharedApplication].keyWindow.rootViewController;
    NSArray *viewControllers = navigationController.viewControllers;
    UITabBarController *tabBarController = [viewControllers objectAtIndex:0];
    float distance = [UIScreen mainScreen].bounds.size.width/5 * (index + 0.6f);
    UITabBar *tabBar = tabBarController.tabBar;
    UIView *orangeView = [[UIView alloc] initWithFrame:CGRectMake(distance, 3, 16, 16)];
    orangeView.backgroundColor = [FontProperties getOrangeColor];
    orangeView.layer.borderColor = UIColor.clearColor.CGColor;
    orangeView.layer.borderWidth = 1.0f;
    orangeView.layer.cornerRadius = orangeView.frame.size.width/2.0f;
    [tabBar addSubview:orangeView];
}


@end
