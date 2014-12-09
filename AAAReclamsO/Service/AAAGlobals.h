//
//  AAAGlobals.h
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 08/12/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <iAd/iAd.h>

@interface AAAGlobals : NSObject

+(AAAGlobals*) sharedInstance;
-(ADBannerView*) sharedBannerView;
-(NSString*) googleAdsId;

@end
