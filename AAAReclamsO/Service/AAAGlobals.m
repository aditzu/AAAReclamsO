//
//  AAAGlobals.m
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 08/12/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import "AAAGlobals.h"
#import "AAASharedBanner.h"
@interface AAAGlobals()
{
    AAASharedBanner* bannerView;
}
@end

@implementation AAAGlobals

static AAAGlobals* _instance;

+(AAAGlobals *)sharedInstance
{
    if (!_instance) {
        _instance = [[AAAGlobals alloc] init];
    }
    return _instance;
}

-(AAASharedBanner *)sharedBannerView
{
    if (!bannerView) {
        bannerView = [[AAASharedBanner alloc] initWithAdUnitId:[self gadUnitId]];
    }
    return bannerView;
}

-(NSString *)flurryId
{
    return @"QNVNYDDJXCM9FR583Q4T";
}

-(NSString*) gadUnitId
{
    return @"ca-app-pub-3940256099942544/2934735716";// @"ca-app-pub-2163416701589769/7779082332";
}

-(NSString *)privacyPolicyURL
{
    return @"http://alphaappers.com/ofertamea/disclaimer.html";
}

@end
