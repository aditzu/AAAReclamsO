//
//  AAANotificationsHandler.h
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 14/01/15.
//  Copyright (c) 2015 Adrian Ancuta. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AAANotificationsHandler : NSObject

+(AAANotificationsHandler*) instance;

-(void) scheduleNextLocalNotifications;

@end
