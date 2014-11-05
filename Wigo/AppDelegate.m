//
//  AppDelegate.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/14/14.
//  Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import "AppDelegate.h"
#import <QuartzCore/QuartzCore.h>
#import <Parse/Parse.h>
#import <Crashlytics/Crashlytics.h>
#import "LocalyticsSession.h"
#import "FontProperties.h"
#import "Network.h"
#import "GAI.h"
#import "Time.h"
#import "PopViewController.h"

NSNumber *indexOfSelectedTab;
NSNumber *numberOfNewMessages;
NSNumber *numberOfNewNotifications;
NSDate *firstLoggedTime;


@implementation AppDelegate

- (void) initializeLocalytics {
#if DEBUG
    [[LocalyticsSession shared] LocalyticsSession:@"b6cd95cf2fdb16d4a9c6442-0646de50-12de-11e4-224f-004a77f8b47f"];
#else
    [[LocalyticsSession shared] LocalyticsSession:@"708a99db734a53dbd326638-47f80b0a-12dc-11e4-9e90-005cf8cbabd8"];
#endif
    //    [[LocalyticsSession shared] setLoggingEnabled:YES];
}

- (void) initializeGoogleAnalytics {
    [GAI sharedInstance].trackUncaughtExceptions = YES;
    [GAI sharedInstance].dispatchInterval = 20;
    [[GAI sharedInstance] trackerWithTrackingId:@"UA-54234727-2"];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"canFetchAppStartup"];
    [Crashlytics startWithAPIKey:@"c08b20670e125cf177b5a6e7bb70d6b4e9b75c27"];
    BOOL googleAnalyticsEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"googleAnalyticsEnabled"];
    BOOL localyticsEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"localyticsEnabled"];
    [Profile setLocalyticsEnabled:localyticsEnabled];
    [Profile setGoogleAnalyticsEnabled:googleAnalyticsEnabled];
    
    if ([[launchOptions allKeys]
         containsObject:UIApplicationLaunchOptionsRemoteNotificationKey])
    {
        if ([Profile localyticsEnabled]) {
            [[LocalyticsSession shared] resume];
            [[LocalyticsSession shared] handleRemoteNotification:[launchOptions
                                                                  objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey]];
        }
    }
    if ([Profile googleAnalyticsEnabled]) {
        [self initializeGoogleAnalytics];
    }
    
    NSString *parseApplicationId = PARSE_APPLICATIONID; // just for ease of debugging
    NSString *parseClientKey = PARSE_CLIENTKEY;
    
    [Parse setApplicationId:parseApplicationId
                  clientKey:parseClientKey];
    
    
    self.notificationDictionary = [[NSMutableDictionary alloc] init];
    
    // Override point for customization after application launch.
    UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
    UITabBar *tabBar = tabBarController.tabBar;
    tabBar.tintColor = [UIColor clearColor];
    [[UITabBarItem appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName : [UIColor clearColor] } forState:UIControlStateSelected];
    
    [self addTabBarDelegate];
    [self changeTabBarToOrange];
    [self addNotificationHandlers];
    [self logFirstTimeLoading];

    return YES;
}



							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    if ([Profile localyticsEnabled]) {
        [[LocalyticsSession shared] close];
        [[LocalyticsSession shared] upload];
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    if ([Profile localyticsEnabled]) {
        [[LocalyticsSession shared] close];
        [[LocalyticsSession shared] upload];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [self reloadTabBarNotifications];
    [self updateGoingOutIfItsAnotherDay];
    [self fetchAppStart];
    if ([Profile localyticsEnabled]) {
        [[LocalyticsSession shared] resume];
        [[LocalyticsSession shared] upload];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    if ([Profile localyticsEnabled]) {
   
        [self initializeLocalytics];
        [[LocalyticsSession shared] resume];
        [[LocalyticsSession shared] upload];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    if ([Profile localyticsEnabled]) {
        [[LocalyticsSession shared] close];
        [[LocalyticsSession shared] upload];
    }
}

- (void)application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    currentInstallation[@"api_version"] = API_VERSION;
    [currentInstallation setDeviceTokenFromData:deviceToken];
    [currentInstallation saveInBackground];
    
    if ([Profile localyticsEnabled]) {
        [[LocalyticsSession shared] setPushToken:deviceToken];
    }
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    if (error.code == 3010) {
        NSLog(@"Push notifications are not supported in the iOS Simulator.");
    } else {
        NSLog(@"application:didFailToRegisterForRemoteNotificationsWithError: %@", error);
    }
}


- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    if ([Profile localyticsEnabled]) {
        [[LocalyticsSession shared] handleRemoteNotification:userInfo];
    }
    if (application.applicationState == UIApplicationStateActive) {
        [self reloadTabBarNotifications];
        NSDictionary *aps = [userInfo objectForKey:@"aps"];
        if ([aps isKindOfClass:[NSDictionary class]]) {
            NSDictionary *alert = [aps objectForKey:@"alert"];
            if ([alert isKindOfClass:[NSDictionary class]]) {
                NSString *locKeyString = [alert objectForKey:@"loc-key"];
                if ([locKeyString isEqualToString:@"M"]) {
                    NSArray *locArgs = [alert objectForKey:@"loc-args"];
                    NSString *messageString = locArgs[1];
                    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithObject:messageString forKey:@"message"];
                    if ([[userInfo allKeys] containsObject:@"from_user"]) {
                        NSDictionary *fromUserDict = [userInfo objectForKey:@"from_user"];
                        if ([[fromUserDict allKeys] containsObject:@"id"]) {
                            [dictionary setObject:[fromUserDict objectForKey:@"id"] forKey:@"id"];
                        }
                    }
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateConversation" object:nil userInfo:[NSDictionary dictionaryWithDictionary:dictionary]];
                }
            }
        }
    }
    else { // If it's was at the background or inactive
        UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
        UINavigationController *navController = (UINavigationController*)tabBarController.selectedViewController;
        
        NSDictionary *aps = [userInfo objectForKey:@"aps"];
        if ([aps isKindOfClass:[NSDictionary class]]) {
            NSDictionary *alert = [aps objectForKey:@"alert"];
            if ([alert isKindOfClass:[NSDictionary class]]) {
                NSString *locKeyString = [alert objectForKey:@"loc-key"];
                if ([locKeyString isEqualToString:@"M"]) {
                    if ([locKeyString isEqualToString:@"M"]) {
                        [navController popToRootViewControllerAnimated:NO];
                        tabBarController.selectedIndex = 2;
                        indexOfSelectedTab = @2;
                    }
                    else if ([locKeyString isEqualToString:@"T"]) {
                        [navController popToRootViewControllerAnimated:NO];
                        tabBarController.selectedIndex = 3;
                    }
                    else if ([locKeyString isEqualToString:@"F"] || [locKeyString isEqualToString:@"FR"]) {
                        [navController popToRootViewControllerAnimated:NO];
                        tabBarController.selectedIndex = 3;
                    }
                    else if ([locKeyString isEqualToString:@"G"]) {
                        [navController popToRootViewControllerAnimated:NO];
                        tabBarController.selectedIndex = 0;
                    }

                }
            }
        }
    }
}

#pragma mark - Custom actions

- (void)application:(UIApplication *)application
handleActionWithIdentifier:(NSString *)identifier
forRemoteNotification:(NSDictionary *)userInfo
  completionHandler:(void (^)())completionHandler {
    
    UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
    UINavigationController *navController = (UINavigationController*)tabBarController.selectedViewController;

    if ([identifier isEqualToString: @"tap_with_diff_event"]) {
        NSDictionary *event = [userInfo objectForKey:@"event"];
        NSNumber *eventID = [event objectForKey:@"id"];
        NSDictionary *aps = [userInfo objectForKey:@"aps"];
        if (eventID  && [aps isKindOfClass:[NSDictionary class]]) {
            NSDictionary *alert = [aps objectForKey:@"alert"];
            if ([alert isKindOfClass:[NSDictionary class]]) {
                NSString *locKeyString = [alert objectForKey:@"loc-key"];
                if ([locKeyString isEqualToString:@"T"]) {
                    if ([Profile user] && [Profile user].key) {
                        [[Profile user] setIsGoingOut:YES];
                        [[Profile user] setEventID:eventID];
                        [[Profile user] setIsAttending:YES];
                        [[Profile user] setAttendingEventID:eventID];
                        [Network postGoingToEventNumber:[eventID intValue]];
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"fetchUserInfo" object:nil];
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"fetchEvents" object:nil];
                    }
                    [navController popToRootViewControllerAnimated:NO];
                    tabBarController.selectedIndex = 1;
                    indexOfSelectedTab = @1;
                    [self changeTabBarToBlue];
                }
            }
        }
    }
    completionHandler();
}


- (void)addTabBarDelegate {
    UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
    tabBarController.delegate = self;
}

- (void)tabBarController:(UITabBarController *)theTabBarController didSelectViewController:(UIViewController *)viewController {
    indexOfSelectedTab = [NSNumber numberWithUnsignedInteger:[theTabBarController.viewControllers indexOfObject:viewController]];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"scrollUp" object:nil];
}

- (void) changeTabBarToOrange {
    [[UITabBar appearance] setBackgroundImage:[[UIImage alloc] init]];
    [[UITabBar appearance] setShadowImage:[[UIImage alloc] init]];
    UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
    UITabBar *tabBar = tabBarController.tabBar;
    tabBar.layer.borderWidth = 0.5;
    UIFont *smallFont = [FontProperties scMediumFont:11.0f];
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
        notificationLabel.textColor = [UIColor whiteColor];
    }
}

- (void) changeTabBarToBlue {
    indexOfSelectedTab = @1;
    [[UITabBar appearance] setBackgroundImage:[[UIImage alloc] init]];
    [[UITabBar appearance] setShadowImage:[[UIImage alloc] init]];
    UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
    UITabBar *tabBar = tabBarController.tabBar;
    tabBar.layer.borderWidth = 0.5;
    UIFont *smallFont = [FontProperties scMediumFont:11.0f];
    [[UITabBarItem appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName:[FontProperties getBlueColor], NSFontAttributeName:smallFont } forState:UIControlStateNormal];
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
        notificationLabel.textColor = [UIColor whiteColor];

    }
}

- (void)addNotificationHandlers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeTabBarToOrange) name:@"changeTabBarToOrange" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeTabBarToBlue) name:@"changeTabBarToBlue" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeTabs) name:@"changeTabs" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTabBarNotifications) name:@"reloadTabBarNotifications" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadColorWhenTabBarIsMessage) name:@"reloadColorWhenTabBarIsMessage" object:nil];
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(goingOutForRateApp) name:@"goingOutForRateApp" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(presentPush) name:@"presentPush" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchAppStart) name:@"fetchAppStart" object:nil];
}

- (void)presentPush {
    BOOL triedToRegister =  [[NSUserDefaults standardUserDefaults] boolForKey: @"triedToRegister"];
    if (!triedToRegister) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"FYI"
                                  message:@"WiGo only sends notifications from your closest friends at your school and important updates."
                                  delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles: nil];
        [alertView show];
        alertView.delegate = self;
    }

}

- (void)changeTabs {
    UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
    tabBarController.selectedViewController = [tabBarController.viewControllers objectAtIndex:1];
    [self changeTabBarToBlue];
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

- (void)areThereNotificationsWithHandler:(IsThereResult)handler {
    if ([Profile user] && [[Profile user] key]) {
        [Network queryAsynchronousAPI:@"users/me" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                if ([[jsonResponse allKeys] containsObject:@"status"]) {
                    if (![[jsonResponse objectForKey:@"status"] isEqualToString:@"error"]) {
                        User *user = [[User alloc] initWithDictionary:jsonResponse];
                        [Profile setUser:user];
                        numberOfNewMessages = (NSNumber *)[user objectForKey:@"num_unread_conversations"];
                        numberOfNewNotifications = (NSNumber *)[user objectForKey:@"num_unread_notifications"];
                        [self updateBadge];
                        handler(numberOfNewMessages, numberOfNewNotifications);
                    }
                }
                else {
                    User *user = [[User alloc] initWithDictionary:jsonResponse];
                    [Profile setUser:user];
                    numberOfNewMessages = (NSNumber *)[user objectForKey:@"num_unread_conversations"];
                    numberOfNewNotifications =  (NSNumber *)[user objectForKey:@"num_unread_notifications"];
                    [self updateBadge];
                    handler(numberOfNewMessages, numberOfNewNotifications);
                }
            });
        }];
    }
}

#pragma mark - Notification Tab Bar

- (void)addNotificationNumber:(NSNumber *)number toTabBar:(NSNumber *)tabBarNumber containNumber:(BOOL)itDoes {
    CGSize origin;
    if ([tabBarNumber isEqualToNumber:@2]) { // Chats notification
        origin = CGSizeMake(216, 6);
    }
    else { //Other notifications
        origin = CGSizeMake(295, 6);
    }
    
    UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
    UITabBar *tabBar = tabBarController.tabBar;
    
    UILabel *numberOfNotificationsLabel;
    if ([[self.notificationDictionary allKeys] containsObject:[tabBarNumber stringValue]]) {
        numberOfNotificationsLabel = [self.notificationDictionary objectForKey:[tabBarNumber stringValue]];
    }
    else numberOfNotificationsLabel = [[UILabel alloc] init];
    
    if (itDoes) {
        numberOfNotificationsLabel.frame = CGRectMake(origin.width, origin.height, 16, 12);
        numberOfNotificationsLabel.text = [number stringValue];
        numberOfNotificationsLabel.textAlignment = NSTextAlignmentCenter;
        numberOfNotificationsLabel.textColor = [UIColor whiteColor];
        numberOfNotificationsLabel.font = [FontProperties mediumFont:10.0f];
    }
    else numberOfNotificationsLabel.frame = CGRectMake(origin.width, origin.height, 8, 8);

  
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
    if ([[self.notificationDictionary allKeys] containsObject:[tabBarNumber stringValue]]) {
        UILabel *numberOfNotificationLabel = [self.notificationDictionary valueForKey:[tabBarNumber stringValue]];
        [numberOfNotificationLabel removeFromSuperview];
        [self.notificationDictionary removeObjectForKey:[tabBarNumber stringValue]];
    }
}

- (void)updateBadge {
    int total = [numberOfNewMessages intValue] + [numberOfNewNotifications intValue];
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    if (currentInstallation.badge != 0) {
        currentInstallation.badge = total;
        currentInstallation[@"api_version"] = API_VERSION;
        [currentInstallation saveEventually];
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:total];
    }

}

- (void)reloadTabBarNotifications {
    [self areThereNotificationsWithHandler:^(NSNumber *numberOFNewMessages, NSNumber *numberOfNewNotifications) {
        if ([numberOFNewMessages intValue] > 0) {
            [self addNotificationNumber:numberOFNewMessages toTabBar:@2 containNumber:YES];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"fetchMessages" object:nil];
        }
        else [self clearNotificationAtTabBar:@2];
        if ([numberOfNewNotifications intValue] > 0) {
            [self addNotificationNumber:numberOfNewNotifications toTabBar:@3 containNumber:NO];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"fetchNotifications" object:nil];
        }
        else [self clearNotificationAtTabBar:@3];
    }];
}

- (void)reloadColorWhenTabBarIsMessage {
    if ([[self.notificationDictionary allKeys] containsObject:@"2"]) {
        UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
        UITabBar *tabBar = tabBarController.tabBar;
        UILabel *numberOfNotificationsLabel = [self.notificationDictionary objectForKey:@"2"];
        numberOfNotificationsLabel.backgroundColor = [UIColor whiteColor];
        numberOfNotificationsLabel.textColor = [FontProperties getOrangeColor];
        [tabBar addSubview:numberOfNotificationsLabel];
    }
}

#pragma mark - Save the time


- (void) logFirstTimeLoading {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    [dateFormatter setTimeZone:timeZone];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *utcTimeString = [dateFormatter stringFromDate:[NSDate date]];
    
    NSDateFormatter *utcDateFormat = [[NSDateFormatter alloc] init];
    [utcDateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *dateInUTC = [utcDateFormat dateFromString:utcTimeString];
    NSTimeInterval timeZoneSeconds = [[NSTimeZone defaultTimeZone] secondsFromGMT];
    firstLoggedTime = [dateInUTC dateByAddingTimeInterval:timeZoneSeconds];
    [self saveDatesAccessed];
}

- (void)updateGoingOutIfItsAnotherDay {
    if (firstLoggedTime) {
        NSDateComponents *firstLoggedDay = [[NSCalendar currentCalendar] components:NSDayCalendarUnit|NSHourCalendarUnit fromDate:firstLoggedTime];
        NSDateComponents *nowTime = [[NSCalendar currentCalendar] components: NSDayCalendarUnit|NSHourCalendarUnit fromDate:[NSDate date]];
        if ([nowTime day] == [firstLoggedDay day]) {
            if ([firstLoggedDay hour] < 6 && [nowTime hour] >= 6) [self reloadAllData];
        }
        else {
            [self reloadAllData];
        }
    }
    
}

- (void)reloadAllData {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"fetchMessages" object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"fetchEvents" object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"fetchFollowing" object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"fetchUserInfo" object:nil];
    [self logFirstTimeLoading];
}

#pragma mark - Save Info for showing rate app

- (void)saveDatesAccessed {
    NSArray *datesAccessed = [[NSUserDefaults standardUserDefaults] objectForKey:@"datesAccessed"];
    if (!datesAccessed) {
        NSDate *firstSaveDate = [NSDate date];
        datesAccessed = @[firstSaveDate];
        [[NSUserDefaults standardUserDefaults] setObject:datesAccessed forKey: @"datesAccessed"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    else if ([datesAccessed count] < 3){
        NSDate *lastDateAccessed = (NSDate *)[datesAccessed lastObject];
        NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSDateComponents *differenceDateComponents = [gregorianCalendar
                                                      components:NSYearCalendarUnit|NSMonthCalendarUnit|NSWeekOfYearCalendarUnit|NSDayCalendarUnit |NSMinuteCalendarUnit
                                                      fromDate:lastDateAccessed
                                                      toDate:firstLoggedTime
                                                      options:0];
        if ([differenceDateComponents day] == 1) {
            NSMutableArray *mutableDatesAccessed = [[NSMutableArray alloc] initWithArray:datesAccessed];
            [mutableDatesAccessed addObject:firstLoggedTime];
            [[NSUserDefaults standardUserDefaults] setObject:[NSArray arrayWithArray:mutableDatesAccessed] forKey: @"datesAccessed"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        else if ([differenceDateComponents day] > 1) {
            [[NSUserDefaults standardUserDefaults] setObject:@[firstLoggedTime] forKey: @"datesAccessed"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
        }
    }
}

-(void)goingOutForRateApp {
    NSArray *datesAccessed = [[NSUserDefaults standardUserDefaults] objectForKey:@"datesAccessed"];
    if ([datesAccessed count] == 3) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Love WiGo?"
                                  message:@"Looks like you love WiGo. The feeling is mutual. Share your love on the App Store."
                                  delegate:self
                                  cancelButtonTitle:@"Not now"
                                  otherButtonTitles:@"Rate WiGo", nil];
        [alertView show];
        NSMutableArray *mutableDatesAccessed = [[NSMutableArray alloc] initWithArray:datesAccessed];
        [mutableDatesAccessed addObject:firstLoggedTime];
        [[NSUserDefaults standardUserDefaults] setObject:[NSArray arrayWithArray:mutableDatesAccessed] forKey: @"datesAccessed"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([alertView.title isEqualToString:@"FYI"]) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
        if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
            UIUserNotificationCategory *category = [self registerActions];
            NSSet *categories = [NSSet setWithObjects:category, nil];
            [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:categories]];
            [[UIApplication sharedApplication] registerForRemoteNotifications];
        } else {
            [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
             (UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert)];
        }
#else
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
         (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
#endif
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"triedToRegister"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    else {
        if ((int)buttonIndex == 1) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/wigo-who-is-going-out/id689401759?mt=8"]];
        }
    }
}

- (UIMutableUserNotificationCategory*)registerActions {
    UIMutableUserNotificationAction* acceptLeadAction = [[UIMutableUserNotificationAction alloc] init];
    acceptLeadAction.identifier = @"tap_with_diff_event";
    acceptLeadAction.title = @"Go Here";
    acceptLeadAction.activationMode = UIUserNotificationActivationModeForeground;
    acceptLeadAction.destructive = false;
    acceptLeadAction.authenticationRequired = false;
    
    UIMutableUserNotificationCategory* category = [[UIMutableUserNotificationCategory alloc] init];
    category.identifier = @"tap_with_diff_event";
    [category setActions:@[acceptLeadAction] forContext: UIUserNotificationActionContextDefault];
    return category;
}

- (void)fetchAppStart {
    BOOL canFetchAppStartUp = [[NSUserDefaults standardUserDefaults] boolForKey:@"canFetchAppStartup"];
    if (canFetchAppStartUp && [self shouldFetchAppStartup] && [Profile user]) {
        [Network queryAsynchronousAPI:@"app/startup?force=true" withHandler:^(NSDictionary *jsonResponse, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                if (!error) {
                    if ([[jsonResponse allKeys] containsObject:@"prompt"]) {
                        NSDictionary *prompt = [jsonResponse objectForKey:@"prompt"];
                        UIViewController *rootViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
                        if (prompt) [rootViewController presentViewController:[[PopViewController alloc] initWithDictionary:prompt] animated:YES completion:nil];
                    }
                    if ([[jsonResponse allKeys] containsObject:@"cdn"]) {
                        NSDictionary *cdnDictionary = [jsonResponse objectForKey:@"cdn"];
                        if ([[cdnDictionary allKeys] containsObject:@"uploads"]) {
                            NSString *cdn = [cdnDictionary objectForKey:@"uploads"];
                            [Profile setCDNPrefix:cdn];
                        }
                    }
                    if ([[jsonResponse allKeys] containsObject:@"analytics"]) {
                        NSDictionary *analytics = [jsonResponse objectForKey:@"analytics"];
                        if (analytics) {
                            BOOL gAnalytics = YES;
                            NSNumber *gval = [analytics objectForKey:@"gAnalytics"];
                            if (gval) {
                                gAnalytics = [gval boolValue];
                            }
                            
                            [Profile setGoogleAnalyticsEnabled:gAnalytics];
                            [[NSUserDefaults standardUserDefaults] setBool:gAnalytics forKey:@"googleAnalyticsEnabled"];
                            
                            BOOL localytics = YES;
                            NSNumber *lval = [analytics objectForKey:@"localytics"];
                            if (lval) {
                                localytics = [lval boolValue];
                            }
                            [Profile setLocalyticsEnabled:localytics];
                            [[NSUserDefaults standardUserDefaults] setBool:localytics forKey:@"localyticsEnabled"];
                            [[NSUserDefaults standardUserDefaults] synchronize];
                            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                            if (gAnalytics) [appDelegate initializeGoogleAnalytics];
                            if (localytics) [appDelegate initializeLocalytics];
                        }
                    }
                }
            });
        }];
    }
}

- (BOOL)shouldFetchAppStartup {
    NSDate *dateAccessed = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastTimeAccessed"];
    if (!dateAccessed) {
        NSDate *firstSaveDate = [NSDate date];
        [[NSUserDefaults standardUserDefaults] setObject:firstSaveDate forKey: @"lastTimeAccessed"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        return YES;
    }
    else {
        NSDate *newDate = [NSDate date];
        NSDateComponents *differenceDateComponents = [Time differenceBetweenFromDate:dateAccessed toDate:newDate];
        if ([differenceDateComponents hour] > 0 || [differenceDateComponents day] > 0 || [differenceDateComponents weekOfYear] > 0 || [differenceDateComponents month] > 0) {
            [[NSUserDefaults standardUserDefaults] setObject:newDate forKey: @"lastTimeAccessed"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            return YES;
        }
    }
    return NO;
}

@end
