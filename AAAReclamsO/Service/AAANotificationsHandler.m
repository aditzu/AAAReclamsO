//
//  AAANotificationsHandler.m
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 14/01/15.
//  Copyright (c) 2015 Adrian Ancuta. All rights reserved.
//

#import "AAANotificationsHandler.h"
#import <UIKit/UIKit.h>

@implementation AAANotificationsHandler

static AAANotificationsHandler* _instance;
const static int NUMBER_OF_DAYS_TO_SCHEDULE_NOTIFICATION = 7;
const static int HOUR_TO_FIRE_NOTIFICATION = 19;

+(AAANotificationsHandler *)instance
{
    if (!_instance) {
        _instance = [[AAANotificationsHandler alloc] init];
    }
    return _instance;
}

-(void)scheduleNextLocalNotifications
{
    UIApplication* sharedApp = [UIApplication sharedApplication];
    [sharedApp cancelAllLocalNotifications];
    
    UILocalNotification* localNotification = [[UILocalNotification alloc] init];
    if (!localNotification) {
        return;
    }
    localNotification.fireDate = [self notificationScheduledFireDate];
    localNotification.alertAction = @"";
    localNotification.alertBody = @"Nu uita să verifici ultimele cataloage!";
    localNotification.applicationIconBadgeNumber = 1;
    localNotification.repeatInterval = NSCalendarUnitWeekday;
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    [sharedApp scheduleLocalNotification:localNotification];
}


-(NSDate*)notificationScheduledFireDate
{
    NSDate* now = [NSDate date];
    NSDate* scheduledDate = [now dateByAddingTimeInterval:NUMBER_OF_DAYS_TO_SCHEDULE_NOTIFICATION*24*3600];
    
    NSCalendar* currentCalendar = [NSCalendar autoupdatingCurrentCalendar];
    NSDateComponents* dateComponents = [currentCalendar components: NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMonth | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:scheduledDate];
    
    [dateComponents setHour:HOUR_TO_FIRE_NOTIFICATION + (int)([currentCalendar timeZone].secondsFromGMT / 3600)];
    [dateComponents setMinute:0];
    [dateComponents setSecond:0];
    
    NSDate* correctDateToScheduleNotification = [currentCalendar dateFromComponents:dateComponents];
    return correctDateToScheduleNotification;
}

@end
