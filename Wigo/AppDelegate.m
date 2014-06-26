//
//  AppDelegate.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/14/14.
//  Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import "AppDelegate.h"
#import "FontProperties.h"
#import <QuartzCore/QuartzCore.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
    UITabBar *tabBar = tabBarController.tabBar;
    
//    tabBar.barTintColor = RGB(244, 245, 245);
    tabBar.tintColor = [UIColor clearColor];
    [[UITabBarItem appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName : [UIColor clearColor],  } forState:UIControlStateSelected];
    [self changeTabBarToOrange];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeTabBarToOrange) name:@"changeTabBarToOrange" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeTabBarToBlue) name:@"changeTabBarToBlue" object:nil];

    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void) changeTabBarToOrange {
    UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
    UITabBar *tabBar = tabBarController.tabBar;
    tabBar.layer.borderWidth = 0.5;
    [[UITabBarItem appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName : [FontProperties getOrangeColor], NSFontAttributeName:[UIFont fontWithName:@"Whitney-MediumSC" size:11.0f] } forState:UIControlStateNormal];
    UITabBarItem *firstTab = [tabBar.items objectAtIndex:0];
    firstTab.image = [[UIImage imageNamed:@"peopleIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    firstTab = [tabBar.items objectAtIndex:1];
    firstTab.image = [[UIImage imageNamed:@"placesIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    firstTab = [tabBar.items objectAtIndex:2];
    firstTab.image = [[UIImage imageNamed:@"chatsIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    firstTab = [tabBar.items objectAtIndex:3];
    firstTab.image = [[UIImage imageNamed:@"notificationsIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

- (void) changeTabBarToBlue {
    UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
    UITabBar *tabBar = tabBarController.tabBar;
    tabBar.layer.borderWidth = 0.5;
    [[UITabBarItem appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName : [FontProperties getBlueColor], NSFontAttributeName:[UIFont fontWithName:@"Whitney-MediumSC" size:11.0f] } forState:UIControlStateNormal];
    UITabBarItem *firstTab = [tabBar.items objectAtIndex:0];
    firstTab.image = [[UIImage imageNamed:@"peopleIconBlue"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal ];
        firstTab = [tabBar.items objectAtIndex:2];
    firstTab.image = [[UIImage imageNamed:@"chatsIconBlue"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal ];
    firstTab = [tabBar.items objectAtIndex:3];
    firstTab.image = [[UIImage imageNamed:@"notificationsIconBlue"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal ];
}

@end
