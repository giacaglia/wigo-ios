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


+ (void)checkForIndexes {
    
}

+ (void)addNotificationTo:(int)index forVC:(UIViewController *)vc {
    float distance = [UIScreen mainScreen].bounds.size.width/5 * (index + 0.6f);
    UITabBarController *tabBarController = vc.tabBarController;
    UITabBar *tabBar = tabBarController.tabBar;
    UIView *orangeView = [[UIView alloc] initWithFrame:CGRectMake(distance, 3, 16, 16)];
    orangeView.backgroundColor = [FontProperties getOrangeColor];
    orangeView.layer.borderColor = UIColor.clearColor.CGColor;
    orangeView.layer.borderWidth = 1.0f;
    orangeView.layer.cornerRadius = orangeView.frame.size.width/2.0f;
    [tabBar addSubview:orangeView];
}


@end
