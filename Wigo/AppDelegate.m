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
#import "RWBlurPopover.h"
#import "WGI.h"
#import "WGNavigateParser.h"
#define kImageQuality @"quality"
#define kImageMultiple @"multiple"


NSNumber *numberOfNewMessages;
NSNumber *numberOfNewNotifications;
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

    if ([[WGProfile currentUser].googleAnalyticsEnabled boolValue]) {
        [self initializeGoogleAnalytics];
    }
    
    NSString *parseApplicationId = PARSE_APPLICATIONID; // just for ease of debugging
    NSString *parseClientKey = PARSE_CLIENTKEY;
    
    [Parse setApplicationId:parseApplicationId
                  clientKey:parseClientKey];
    
    
    self.notificationDictionary = [[NSMutableDictionary alloc] init];
    
    // Override point for customization after application launch.

    [self addNotificationHandlers];
    [self logFirstTimeLoading];
    [WGI openedTheApp];

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
    [WGI closedTheApp];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [self updateGoingOutIfItsAnotherDay];
    [self fetchAppStart];
    [WGI openedTheApp];
}

- (void) dismissEverythingWithUserInfo:(NSDictionary *)userInfo {
    if ([RWBlurPopover instance]) [[RWBlurPopover instance] dismissViewControllerAnimated:NO completion:nil];
    
    UINavigationController *navController = (UINavigationController *)[[[[UIApplication sharedApplication] delegate] window] rootViewController];
    UIViewController *presentedController = [navController presentedViewController];
    UIViewController *visibleController = [navController topViewController];

    if (![visibleController isKindOfClass:[PlacesViewController class]]) {
        if (presentedController != nil) {
            [presentedController dismissViewControllerAnimated:NO completion:^{[self dismissEverythingWithUserInfo:userInfo];}];
        } else {
            [navController popViewControllerAnimated:NO];
            [self dismissEverythingWithUserInfo:userInfo];
        }
    } else {
        [self doneWithUserInfo:userInfo];
    }
}

- (void) doneWithUserInfo:(NSDictionary *)userInfo {
    if ([self doesUserInfo:userInfo hasString:@"M"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"goToChat" object:nil];
    }
    if ([self doesUserInfo:userInfo hasString:@"T"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"goToProfile" object:nil userInfo:[userInfo objectForKey:@"event"]];
    }
    if ([[userInfo allKeys] containsObject:@"navigate"]) {
        NSString *place = [userInfo objectForKey:@"navigate"];
        NSDictionary *notificationUserInfo = [WGNavigateParser userInfoFromString:place];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"navigate"
                                                             object:nil
                                                           userInfo:notificationUserInfo];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
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
    if (application.applicationState == UIApplicationStateInactive) {
        [self dismissEverythingWithUserInfo:userInfo];
    }

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
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(goingOutForRateApp) name:@"goingOutForRateApp" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(presentPush) name:@"presentPush" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchAppStart) name:@"fetchAppStart" object:nil];
}

- (void)presentPush {
    BOOL triedToRegister =  [[NSUserDefaults standardUserDefaults] boolForKey: @"triedToRegister"];
    if (!triedToRegister) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"FYI"
                                  message:@"Wigo only sends notifications from your closest friends and important updates."
                                  delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles: nil];
        [alertView show];
        alertView.delegate = self;
    }

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

#pragma mark - Save the time

- (void) logFirstTimeLoading {
    NSDateFormatter *utcDateFormat = [[NSDateFormatter alloc] init];
    [utcDateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *dateInUTC = [utcDateFormat dateFromString:[NSDate nowStringUTC]];
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

- (void)saveDatesAccessed {
    NSArray *datesAccessed = [[NSUserDefaults standardUserDefaults] objectForKey:@"datesAccessed"];
    if (!datesAccessed) {
        NSDate *firstSaveDate = [NSDate dateInLocalTimezone];
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
                                  initWithTitle:@"Love Wigo?"
                                  message:@"Looks like you love Wigo. The feeling is mutual. Share your love on the App Store."
                                  delegate:self
                                  cancelButtonTitle:@"Not now"
                                  otherButtonTitles:@"Rate Wigo", nil];
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
    } else {
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
