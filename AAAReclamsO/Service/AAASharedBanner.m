//
//  AAASharedBanner.m
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 08/12/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import "AAASharedBanner.h"
#import "GADRequest.h"

@interface AAASharedBanner()
{
}

@end

@implementation AAASharedBanner


-(instancetype)initWithAdUnitId:(NSString*) adUnitId
{
    if (self = [super init])
    {
        self.bannerView = [[GADBannerView alloc] initWithAdSize:GADAdSizeFullWidthPortraitWithHeight(50)];
        self.bannerView.hidden = YES;
        self.bannerView.adUnitID = adUnitId;
    }
    return self;
}

-(void)setRootViewController:(UIViewController *)vc
{
    self.bannerView.rootViewController = vc;
    GADRequest* gadRequest = [GADRequest request];
    gadRequest.testDevices = @[GAD_SIMULATOR_ID];
    [self.bannerView loadRequest:gadRequest];
}

//#pragma mark - GADBannerView Delegate
//
//-(void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error
//{
//    gadBannerLoaded = NO;
//    [self layoutBanner:NO animated:YES];
//    NSLog(@"didFailToReceiveAdWithError :%@", error);
//}
//
//-(void)adViewDidReceiveAd:(GADBannerView *)view
//{
//    gadBannerLoaded = YES;
//    if (!isMinimized) {
//        [self layoutBanner:YES animated:YES];
//    }
//    NSLog(@"adViewDidReceiveAd");
//}
//
//-(void)adViewDidDismissScreen:(GADBannerView *)adView
//{
//    [self showPageViewController:YES animated:YES];
//    NSLog(@"adViewDidDismissScreen");
//}
//
//-(void)adViewWillLeaveApplication:(GADBannerView *)adView
//{
//    NSLog(@"adViewWillLeaveApplication");
//}
//
//-(void)adViewWillPresentScreen:(GADBannerView *)adView
//{
//    [self showTopBar:[NSNumber numberWithBool:NO]];
//    [self showPageViewController:NO animated:YES];
//    NSLog(@"adViewWillPresentScreen");
//}

@end
