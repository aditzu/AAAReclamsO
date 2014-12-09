//
//  AAASharedBanner.m
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 08/12/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import "AAASharedBanner.h"

@interface AAASharedBanner()
{
}

@end

@implementation AAASharedBanner


-(instancetype)init
{
    if (self = [super init])
    {
        self.bannerView = [[ADBannerView alloc] initWithAdType:ADAdTypeBanner];
        self.bannerView.delegate = self;
    }
    return self;
}

#pragma mark - delegate methods

-(void)bannerViewWillLoadAd:(ADBannerView *)banner
{
    NSLog(@"bannerViewWillLoadAd");
}

-(void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    NSLog(@"bannerViewDidLoadAd");
}

-(BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
{
    NSLog(@"bannerViewActionShouldBegin");
    return YES;
}

-(void)bannerViewActionDidFinish:(ADBannerView *)banner
{
    NSLog(@"bannerViewActionDidFinish");
}

-(void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    NSLog(@"didFailToReceiveAdWithError: %@", error);
}

@end
