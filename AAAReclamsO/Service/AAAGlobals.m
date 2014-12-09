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

-(ADBannerView *)sharedBannerView
{
    if (!bannerView) {
        bannerView = [[AAASharedBanner alloc] init];
    }
    return bannerView.bannerView;
}

-(NSString *)flurryId
{
    return @"QNVNYDDJXCM9FR583Q4T";
}

@end
