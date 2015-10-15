//
//  AppDelegate.m
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 10/11/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import "AppDelegate.h"
#import "Flurry.h"
#import "AAAGlobals.h"
#import "AAANotificationsHandler.h"
#import <Parse/Parse.h>
#import "AAAPurchasesHandler.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [Flurry startSession:[[AAAGlobals sharedInstance] flurryId]];
    
    [Parse enableLocalDatastore];
    [Parse setApplicationId:@"7OJjQorhEeo52BlycAYTzpBRKrhDMg4oXE4hTNcR" clientKey:@"SN9159nLpY2eH0Auue8AZiCVDBike83WRZbLMbNm"];

    [AAAPurchasesHandler instance];
    if (application.applicationState != UIApplicationStateBackground) {
        // Track an app open here if we launch with a push, unless
        // "content_available" was used to trigger a background push (introduced
        // in iOS 7). In that case, we skip tracking here to avoid double
        // counting the app-open.
        BOOL preBackgroundPush = ![application respondsToSelector:@selector(backgroundRefreshStatus)];
        BOOL oldPushHandlerOnly = ![self respondsToSelector:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)];
        BOOL noPushPayload = ![launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        if (preBackgroundPush || oldPushHandlerOnly || noPushPayload) {
            [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
        }
    }
    

    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
    #ifdef __IPHONE_8_0
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeAlert
                                                                                             | UIUserNotificationTypeBadge
                                                                                             | UIUserNotificationTypeSound) categories:nil];
        [application registerUserNotificationSettings:settings];
        [application registerForRemoteNotifications];
    #endif
    } else {
        UIRemoteNotificationType myTypes = UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound;
        [application registerForRemoteNotificationTypes:myTypes];
    }
    
    NSDictionary *notification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (notification) {
        [Flurry logEvent:FlurryEventStartedFromNotification];
    }
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    if (currentInstallation.badge != 0) {
        currentInstallation.badge = 0;
        [currentInstallation saveEventually];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

-(void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    [[AAANotificationsHandler instance] scheduleNextLocalNotifications];
    application.applicationIconBadgeNumber = 0;
    [Flurry logEvent:FlurryEventDidRegisterForNotification withParameters:@{FlurryParameterBOOL:@YES}];
}

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    if (application.applicationState == UIApplicationStateInactive) {
        // The application was just brought from the background to the foreground,
        // so we consider the app as having been "opened by a push notification."
        [PFAnalytics trackAppOpenedWithRemoteNotificationPayload:userInfo];
    }
}

-(void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    [self registerToParseWithDeviceToken:deviceToken];
}

-(void) registerToParseWithDeviceToken:(NSData*) deviceToken
{
    [[PFInstallation currentInstallation] saveInBackground];
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    currentInstallation.channels = @[ @"global" ];
    [currentInstallation saveInBackground];
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    [Flurry logEvent:FlurryEventDidRegisterForNotification withParameters:@{FlurryParameterBOOL:@NO}];
}

@end
