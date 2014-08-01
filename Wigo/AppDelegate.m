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
#import <Parse/Parse.h>
#import <Crashlytics/Crashlytics.h>
#import "LocalyticsSession.h"
#import "FontProperties.h"
#import "Network.h"

NSNumber *indexOfSelectedTab;

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Crashlytics startWithAPIKey:@"c08b20670e125cf177b5a6e7bb70d6b4e9b75c27"];
    if ([[launchOptions allKeys]
         containsObject:UIApplicationLaunchOptionsRemoteNotificationKey])
    {
        [[LocalyticsSession shared] resume];
        [[LocalyticsSession shared] handleRemoteNotification:[launchOptions
                                                              objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey]];
    }
    
    
    NSString *parseApplicationId = PARSE_APPLICATIONID; // just for ease of debugging
    NSString *parseClientKey = PARSE_CLIENTKEY;
    
    [Parse setApplicationId:parseApplicationId
                  clientKey:parseClientKey];
    [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge|
     UIRemoteNotificationTypeAlert|
     UIRemoteNotificationTypeSound];
    
    self.notificationDictionary = [[NSMutableDictionary alloc] init];
    
    // Override point for customization after application launch.
    UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
    UITabBar *tabBar = tabBarController.tabBar;
    tabBar.tintColor = [UIColor clearColor];
    [[UITabBarItem appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName : [UIColor clearColor] } forState:UIControlStateSelected];
    
    [self addTabBarDelegate];
    [self changeTabBarToOrange];
    [self addNotificationHandlers];

    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    [[LocalyticsSession shared] close];
    [[LocalyticsSession shared] upload];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [[LocalyticsSession shared] close];
    [[LocalyticsSession shared] upload];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [self areThereNewMessagesWithBoolReturned:^(BOOL boolResult) {
        if (boolResult) {
            [self addOneToTabBar:@2];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"fetchMessages" object:nil];
        }
    }];

    [[LocalyticsSession shared] resume];
    [[LocalyticsSession shared] upload];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    if (currentInstallation.badge != 0) {
        currentInstallation.badge = 0;
        [currentInstallation saveEventually];
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber: 0];
    }

#if DEBUG
    [[LocalyticsSession shared] LocalyticsSession:@"b6cd95cf2fdb16d4a9c6442-0646de50-12de-11e4-224f-004a77f8b47f"];
#else
    [[LocalyticsSession shared] LocalyticsSession:@"708a99db734a53dbd326638-47f80b0a-12dc-11e4-9e90-005cf8cbabd8"];
#endif
    
    [[LocalyticsSession shared] resume];
    [[LocalyticsSession shared] upload];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [[LocalyticsSession shared] close];
    [[LocalyticsSession shared] upload];
}

- (void)application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    [currentInstallation saveInBackground];
    
    [[LocalyticsSession shared] setPushToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    if (error.code == 3010) {
        NSLog(@"Push notifications are not supported in the iOS Simulator.");
    } else {
        // show some alert or otherwise handle the failure to register.
        NSLog(@"application:didFailToRegisterForRemoteNotificationsWithError: %@", error);
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [[LocalyticsSession shared] handleRemoteNotification:userInfo];

    UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
    UINavigationController *navController = [tabBarController.viewControllers objectAtIndex:tabBarController.selectedIndex];
    if (navController) [navController popToRootViewControllerAnimated:NO];
    
    NSDictionary *aps = [userInfo objectForKey:@"aps"];
    NSDictionary *alert = [aps objectForKey:@"alert"];
    NSString *locKeyString = [alert objectForKey:@"loc-key"];
    if ([locKeyString isEqualToString:@"M"]) {
        [self addOneToTabBar:@2];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"fetchMessages" object:nil];

    }
    else if ([locKeyString isEqualToString:@"F"] ||
        [locKeyString isEqualToString:@"FR"] ||
        [locKeyString isEqualToString:@"FA"]) {
        [self addOneToTabBar:@3];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"fetchNotifications" object:nil];

    }
    else if ([locKeyString isEqualToString:@"T"]) {
        [self addOneToTabBar:@3];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"fetchNotifications" object:nil];
    }
    else if ([locKeyString isEqualToString:@"G"]) {
        [self addOneToTabBar:@0];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"fetchFollowing" object:nil];

    }
}


- (void)addTabBarDelegate {
    UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
    tabBarController.delegate = self;
}

- (void)tabBarController:(UITabBarController *)theTabBarController didSelectViewController:(UIViewController *)viewController {
    indexOfSelectedTab = [NSNumber numberWithUnsignedInteger:[theTabBarController.viewControllers indexOfObject:viewController]];
    [self clearNotificationAtTabBar:indexOfSelectedTab];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"scrollUp" object:nil];
}

- (void) changeTabBarToOrange {
    UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;

    UITabBar *tabBar = tabBarController.tabBar;
    tabBar.layer.borderWidth = 0.5;
    UIFont *smallFont = SC_MEDIUM_FONT(11.0f);
    [[UITabBarItem appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName : [FontProperties getOrangeColor], NSFontAttributeName:smallFont } forState:UIControlStateNormal];
    UITabBarItem *tabItem = [tabBar.items objectAtIndex:0];
    tabItem.image = [[UIImage imageNamed:@"peopleIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [tabItem setTitlePositionAdjustment:UIOffsetMake(0, -2)];
    tabItem = [tabBar.items objectAtIndex:1];
    tabItem.image = [[UIImage imageNamed:@"placesIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [tabItem setTitlePositionAdjustment:UIOffsetMake(0, -2)];
    tabItem = [tabBar.items objectAtIndex:2];
    tabItem.image = [[UIImage imageNamed:@"chatsIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [tabItem setTitlePositionAdjustment:UIOffsetMake(0, -2)];
    tabItem = [tabBar.items objectAtIndex:3];
    tabItem.image = [[UIImage imageNamed:@"notificationsIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [tabItem setTitlePositionAdjustment:UIOffsetMake(0, -2)];
    for (NSString *key in [self.notificationDictionary allKeys] ) {
        UILabel *notificationLabel = [self.notificationDictionary objectForKey:key];
        notificationLabel.backgroundColor = [FontProperties getOrangeColor];
    }
}

- (void) changeTabBarToBlue {
    UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
    UITabBar *tabBar = tabBarController.tabBar;
    tabBar.layer.borderWidth = 0.5;
    UIFont *smallFont = SC_MEDIUM_FONT(11.0f);
    [[UITabBarItem appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName : [FontProperties getBlueColor], NSFontAttributeName:smallFont } forState:UIControlStateNormal];
    UITabBarItem *firstTab = [tabBar.items objectAtIndex:0];
    firstTab.image = [[UIImage imageNamed:@"peopleIconBlue"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [firstTab setTitlePositionAdjustment:UIOffsetMake(0, -2)];
    firstTab = [tabBar.items objectAtIndex:2];
    firstTab.image = [[UIImage imageNamed:@"chatsIconBlue"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [firstTab setTitlePositionAdjustment:UIOffsetMake(0, -2)];
    firstTab = [tabBar.items objectAtIndex:3];
    firstTab.image = [[UIImage imageNamed:@"notificationsIconBlue"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [firstTab setTitlePositionAdjustment:UIOffsetMake(0, -2)];
    for (NSString *key in [self.notificationDictionary allKeys] ) {
        UILabel *notificationLabel = [self.notificationDictionary objectForKey:key];
        notificationLabel.backgroundColor = [FontProperties getBlueColor];
    }
}

- (void)addOneToTabBar:(NSNumber *)tabBarNumber {
    [self addNotificationNumber:@1 toTabBar:tabBarNumber];
}

- (void)addNotificationNumber:(NSNumber *)number toTabBar:(NSNumber *)tabBarNumber {
    CGSize origin;
    if ([tabBarNumber isEqualToNumber:@2]) { // Chats notification
        origin = CGSizeMake(216, 6);
    }
    else { //Other notifications
        origin = CGSizeMake(295, 6);
    }
    
    UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
    UITabBar *tabBar = tabBarController.tabBar;
    
    UILabel *numberOfNotificationsLabel = [[UILabel alloc] init];
    numberOfNotificationsLabel.frame = CGRectMake(origin.width, origin.height, 8, 8);
    if ([indexOfSelectedTab isEqualToNumber:@1]) numberOfNotificationsLabel.backgroundColor = [FontProperties getBlueColor];
    else numberOfNotificationsLabel.backgroundColor = [FontProperties getOrangeColor];
    numberOfNotificationsLabel.layer.borderColor = [UIColor clearColor].CGColor;
    numberOfNotificationsLabel.layer.cornerRadius = 5;
    numberOfNotificationsLabel.layer.borderWidth = 1;
    numberOfNotificationsLabel.layer.masksToBounds = YES;
    
    [tabBar addSubview:numberOfNotificationsLabel];
    [self.notificationDictionary setValue:numberOfNotificationsLabel forKey:[tabBarNumber stringValue]];
}


- (void)clearNotificationAtTabBar:(NSNumber *)tabBarNumber {
    UILabel *numberOfNotificationLabel = [self.notificationDictionary valueForKey:[tabBarNumber stringValue]];
    [numberOfNotificationLabel removeFromSuperview];
}

- (void)addNotificationHandlers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeTabBarToOrange) name:@"changeTabBarToOrange" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeTabBarToBlue) name:@"changeTabBarToBlue" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeTabs) name:@"changeTabs" object:nil];

}

- (void)changeTabs {
    UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
    tabBarController.selectedViewController = [tabBarController.viewControllers objectAtIndex:1];
}

# pragma mark - Facebook Login

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    
    // Call FBAppCall's handleOpenURL:sourceApplication to handle Facebook app responses
    BOOL wasHandled = [FBAppCall handleOpenURL:url sourceApplication:sourceApplication];
    
    // You can add your app-specific url handling code here if needed
    [[NSNotificationCenter defaultCenter] postNotificationName:@"changeAlertToNotShown" object:nil];
    
    return wasHandled;
}

- (void)areThereNewMessagesWithBoolReturned:(IsThereResult)handler {
    NSString *queryString = @"unread/summary";
    [Network sendAsynchronousHTTPMethod:GET withAPIName:queryString withHandler:^(NSDictionary *jsonResponse, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            NSNumber *numberOfNewMessages = [jsonResponse objectForKey:@"messages"];
            NSNumber *numberOfNewNotifications = [jsonResponse objectForKey:@"notifications"];
            if ([numberOfNewMessages intValue] > 0) handler(YES);
            else handler(NO);
        });
    }];

}

//- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
//{
////    [(UINavigationController*)self.tabBarController.selectedViewController popToRootViewControllerAnimated:NO];
//    NSLog(@"here");
//    return YES;
//}

//- (void)handleSingleTap:(id)sender {
//    NSLog(@"here");
//
//}
//
//#pragma mark - Tap Gesture
//
//- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
//    // Disallow recognition of tap gestures in the TabbarItem control.
//    if ([touch.view isKindOfClass:[UIBarButtonItem class]]) {//change it to your condition
////        if (touch.view.tag != 50) {
////            return NO;
////        }
//        return YES;
//    }
//    return NO;
//}
@end
