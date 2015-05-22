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
#import "FontProperties.h"
#import "GAI.h"
#import "PopViewController.h"
#import "WGProfile.h"
#import "WGEvent.h"
#import "PlacesViewController.h"
#import "WGI.h"
#import "WGNavigateParser.h"
#import "ChatViewController.h"
#import "PeopleViewController.h"
#import "ProfileViewController.h"
#import "NetworkFetcher.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>

#define kImageQuality @"quality"
#define kImageMultiple @"multiple"

NSDate *firstLoggedTime;

@implementation AppDelegate

- (void) initializeGoogleAnalytics {
    [GAI sharedInstance].trackUncaughtExceptions = NO;
    
#if DEBUG
    [[GAI sharedInstance].logger setLogLevel:kGAILogLevelVerbose];
#else
    [[GAI sharedInstance].logger setLogLevel:kGAILogLevelNone];
#endif
    
    [GAI sharedInstance].dispatchInterval = 20;
    [[GAI sharedInstance] trackerWithTrackingId:@"UA-54234727-2"];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"canFetchAppStartup"];
    [Crashlytics startWithAPIKey:@"c08b20670e125cf177b5a6e7bb70d6b4e9b75c27"];

    if (WGProfile.currentUser.googleAnalyticsEnabled.boolValue) {
        [self initializeGoogleAnalytics];
    }
    
    NSString *parseApplicationId = PARSE_APPLICATIONID; // just for ease of debugging
    NSString *parseClientKey = PARSE_CLIENTKEY;
    
    [Parse setApplicationId:parseApplicationId
                  clientKey:parseClientKey];
    
    
    self.notificationDictionary = [NSMutableDictionary dictionaryWithDictionary:launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey]];
    
    // Override point for customization after application launch.

    [self addNotificationHandlers];
    [self logFirstTimeLoading];
    [WGI openedTheApp];
    
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                    didFinishLaunchingWithOptions:launchOptions];
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
    [WGI closedTheApp];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [self updateGoingOutIfItsAnotherDay];
    [self fetchAppStart];
    [WGI openedTheApp];
}

- (void)navigate:(NSString *)navigateString {
    
    if(!navigateString || [navigateString isEqual:[NSNull null]] || ![navigateString isKindOfClass:[NSString class]]) {
        return;
    }
    
    NSDictionary *navigationDict = [WGNavigateParser dictionaryFromString:navigateString];
    navigationDict = [WGNavigateParser userInfoFromString:navigateString];
    
    NSString *presentedView = navigationDict[kNameOfObjectKey];
    NSString *rootString = navigationDict[kRootObjetKey];
    NSString *tab = [WGNavigateParser applicationTabForObject:presentedView root:rootString];
    
    if(tab) {
        [self switchToTab:tab withOptions:navigationDict];
    }
}

- (void) switchToTab:(NSString *)tab withOptions:(NSDictionary *)options {
    
    // dismiss any existing modal or navigation views
    [self dismissEverythingWithUserInfo:nil];
    
    
    UITabBarController *tabController = nil;
    
    UINavigationController *navController = (UINavigationController *)[[[[UIApplication sharedApplication] delegate] window] rootViewController];
    
    if([navController isKindOfClass:[UITabBarController class]]) {
        tabController = (UITabBarController *)navController;
    }
    else {
        if(navController.viewControllers.count > 0 && [navController.viewControllers[0] isKindOfClass:[UITabBarController class]]) {
            tabController = navController.viewControllers[0];
        }
    }
    
    if(!tabController) {
        return;
    }
    
    Class selectedClass = nil;
    
    if([tab isEqualToString:kWGTabHome]) {
        selectedClass = [PlacesViewController class];
    }
    else if([tab isEqualToString:kWGTabChat]) {
        selectedClass = [ChatViewController class];
    }
    else if([tab isEqualToString:kWGTabDiscover]) {
        selectedClass = [PeopleViewController class];
    }
    else if([tab isEqualToString:kWGTabProfile]) {
        selectedClass = [ProfileViewController class];
    }
    
    if(selectedClass) {
        for(UIViewController *vc in tabController.viewControllers) {
            if([vc isKindOfClass:selectedClass]) {
                tabController.selectedViewController = vc;
                
                if([vc conformsToProtocol:@protocol(WGViewController)]) {
                    [(id <WGViewController>)vc updateViewWithOptions:options];
                }
            }
        }
    }
}

- (void) dismissEverythingWithUserInfo:(NSDictionary *)userInfo {
    UINavigationController *navController = (UINavigationController *)[[[[UIApplication sharedApplication] delegate] window] rootViewController];
    UIViewController *presentedController = [navController presentedViewController];
    //UIViewController *visibleController = [navController topViewController];
    
    if(presentedController) {
        [navController dismissViewControllerAnimated:NO
                                          completion:nil];
    }
    
    [navController popToRootViewControllerAnimated:NO];
}


- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    if (currentInstallation && currentInstallation.badge != 0) {
        currentInstallation.badge = 0;
        [currentInstallation saveEventually];
    }
    [NetworkFetcher.defaultGetter fetchMetaWithHandler:^(BOOL success, NSError *error) {}];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"startPrimer" object:nil];
    [FBSDKAppEvents activateApp];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    currentInstallation[@"api_version"] = API_VERSION;
    [currentInstallation setObject:@2.0f forKey:@"api_version_num"];
    currentInstallation[@"osVersion"] = [UIDevice currentDevice].systemVersion;
    [currentInstallation setDeviceTokenFromData:deviceToken];
    [currentInstallation saveInBackground];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    if (error.code == 3010) {
        NSLog(@"Push notifications are not supported in the iOS Simulator.");
    } else {
        NSLog(@"application:didFailToRegisterForRemoteNotificationsWithError: %@", error);
    }
}

- (UIViewController*) topMostController
{
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    return topController;
}

- (BOOL)isModal:(UIViewController *)vc {
    return vc.presentingViewController.presentedViewController == vc
    || vc.navigationController.presentingViewController.presentedViewController == vc.navigationController
    || [vc.tabBarController.presentingViewController isKindOfClass:[UITabBarController class]];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [NetworkFetcher.defaultGetter fetchMetaWithHandler:^(BOOL success, NSError *error) {}];
    
    if (application.applicationState == UIApplicationStateInactive) {
        
        if ([[userInfo allKeys] containsObject:@"navigate"]) {
            [self handleNavigationForUserInfo:userInfo];
        }
    }
    [UIApplication sharedApplication].applicationIconBadgeNumber = [[[userInfo objectForKey:@"aps"] objectForKey: @"badgecount"] intValue];

    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"fetchUserInfo" object:nil];
    if (application.applicationState == UIApplicationStateActive) {
        NSDictionary *aps = [userInfo objectForKey:@"aps"];
        if ([aps isKindOfClass:[NSDictionary class]]) {
            NSDictionary *aps = [userInfo objectForKey:@"aps"];
            if ([aps isKindOfClass:[NSDictionary class]]) {
                NSDictionary *alert = [aps objectForKey:@"alert"];
                if ([alert isKindOfClass:[NSDictionary class]]) {
                    NSString *locKeyString = [alert objectForKey:@"loc-key"];
                    if ([locKeyString isEqualToString:@"M"]) {
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"updateConversation" object:nil userInfo:userInfo];
                    }
                    
                }
            }
        }
    } else { // If it's was at the background or inactive
    }
}

- (void) handleNavigationForUserInfo:(NSDictionary *)userInfo {
    
    [self dismissEverythingWithUserInfo:userInfo];
    NSString *navigateString = [userInfo objectForKey:@"navigate"];
    [self navigate:navigateString];
}

- (BOOL)doesUserInfo:(NSDictionary *)userInfo hasString:(NSString *)checkString {
    NSDictionary *aps = [userInfo objectForKey:@"aps"];
    if ([aps isKindOfClass:[NSDictionary class]]) {
        NSDictionary *alert = [aps objectForKey:@"alert"];
        if ([alert isKindOfClass:[NSDictionary class]]) {
            NSString *locKeyString = [alert objectForKey:@"loc-key"];
            if ([locKeyString isEqualToString:checkString]) {
                return YES;
            }
        }
    }
    return NO;
}

#pragma mark - Custom actions

- (void)application:(UIApplication *)application
handleActionWithIdentifier:(NSString *)identifier
forRemoteNotification:(NSDictionary *)userInfo
  completionHandler:(void (^)())completionHandler {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"fetchUserInfo" object:nil];
    if ([identifier isEqualToString: @"tap_with_diff_event"]) {
        NSDictionary *event = [userInfo objectForKey:@"event"];
        NSDictionary *aps = [userInfo objectForKey:@"aps"];
        NSDictionary *alert = [aps objectForKey:@"alert"];
        NSString *locKeyString = [alert objectForKey:@"loc-key"];
        if ([locKeyString isEqualToString:@"T"]) {
            if ([WGProfile currentUser].key) {
                [WGProfile currentUser].isGoingOut = @YES;
                WGEvent *attendingEvent = [WGEvent serialize:event];
                [WGProfile currentUser].eventAttending = attendingEvent;
                
                [[WGProfile currentUser] goingToEvent:attendingEvent withHandler:^(BOOL success, NSError *error) {
                    completionHandler();
                }];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"fetchEvents" object:nil];
                return;
            }
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"fetchUserInfo" object:nil];
    completionHandler();
}


- (void)addNotificationHandlers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchAppStart) name:@"fetchAppStart" object:nil];
}

# pragma mark - Facebook Login

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                          openURL:url
                                                sourceApplication:sourceApplication
                                                       annotation:annotation];
}

#pragma mark - Save the time

- (void) logFirstTimeLoading {
    NSDateFormatter *utcDateFormat = [[NSDateFormatter alloc] init];
    [utcDateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *dateInUTC = [utcDateFormat dateFromString:[NSDate nowStringUTC]];
    NSTimeInterval timeZoneSeconds = [[NSTimeZone defaultTimeZone] secondsFromGMT];
    firstLoggedTime = [dateInUTC dateByAddingTimeInterval:timeZoneSeconds];
}

- (void)updateGoingOutIfItsAnotherDay {
    if (firstLoggedTime) {
        NSDateComponents *firstLoggedDay = [[NSCalendar currentCalendar] components:NSDayCalendarUnit|NSHourCalendarUnit fromDate:firstLoggedTime];
        NSDateComponents *nowTime = [[NSCalendar currentCalendar] components: NSDayCalendarUnit|NSHourCalendarUnit fromDate:[NSDate date]];
        if ([nowTime day] == [firstLoggedDay day]) {
            if ([firstLoggedDay hour] < 6 && [nowTime hour] >= 6) [self reloadAllData];
        } else {
            [self reloadAllData];
        }
    }
    
}

- (void)reloadAllData {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"fetchMessages" object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"fetchEvents" object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"fetchUserInfo" object:nil];
    [self logFirstTimeLoading];
}

#pragma mark - Save Info for showing rate app

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([alertView.title isEqualToString:@"Love Wigo"]) {
        if ((int)buttonIndex == 1) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/wigo-who-is-going-out/id689401759?mt=8"]];
        }
    }
}

- (void)fetchAppStart {
    BOOL canFetchAppStartUp = [[NSUserDefaults standardUserDefaults] boolForKey:@"canFetchAppStartup"];
    if (canFetchAppStartUp && [self shouldFetchAppStartup] && [WGProfile currentUser]) {
        [WGApi startup:^(NSString *cdnPrefix, NSNumber *googleAnalyticsEnabled, NSNumber *schoolStatistics, NSNumber *privateEvents, BOOL videoEnabled, BOOL crossEventPhotosEnabled, NSDictionary *imageProperties, NSError *error) {
            if (error) {
                return;
            }
            WGProfile.currentUser.cdnPrefix = cdnPrefix;
            WGProfile.currentUser.googleAnalyticsEnabled = googleAnalyticsEnabled;
            WGProfile.currentUser.schoolStatistics = schoolStatistics;
            WGProfile.currentUser.privateEvents = privateEvents;
            WGProfile.currentUser.videoEnabled = videoEnabled;
            WGProfile.currentUser.crossEventPhotosEnabled = crossEventPhotosEnabled;
            NSNumber *imageMultiple = [imageProperties objectForKey:kImageMultiple];
            NSNumber *imageQuality = [imageProperties objectForKey:kImageQuality];
            WGProfile.currentUser.imageMultiple = [imageMultiple floatValue];
            WGProfile.currentUser.imageQuality = [imageQuality floatValue];
        }];
    }
}

- (BOOL)shouldFetchAppStartup {
    NSDate *dateAccessed = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastTimeAccessed"];
    if (!dateAccessed) {
        NSDate *firstSaveDate = [NSDate dateInLocalTimezone];
        [[NSUserDefaults standardUserDefaults] setObject:firstSaveDate forKey: @"lastTimeAccessed"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        return YES;
    } else {
        NSDate *newDate = [NSDate dateInLocalTimezone];
        NSDateComponents *differenceDateComponents = [dateAccessed differenceBetweenDates:newDate];
        if ([differenceDateComponents hour] > 0 || [differenceDateComponents day] > 0 || [differenceDateComponents weekOfYear] > 0 || [differenceDateComponents month] > 0) {
            [[NSUserDefaults standardUserDefaults] setObject:newDate forKey: @"lastTimeAccessed"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            return YES;
        }
    }
    return NO;
}

@end
