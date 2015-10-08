//
//  AAASharedBanner.m
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 08/12/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import "AAAAds.h"

@interface AAAAds()
{
    BOOL _enabled;
    NSString* _interstitialId;
}

@property (nonatomic, strong) GADBannerView* gadBannerAdView;
@property (nonatomic, strong) GADInterstitial* interstitialView;
@end

@implementation AAAAds

-(id)initWithBannerAdUnitId:(NSString *)bannerId andInterstitialUnitId:(NSString *)interstitialId
{
    if(self = [super init])
    {
        _enabled = YES;
        self.gadBannerAdView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeSmartBannerPortrait];
        self.gadBannerAdView.adUnitID = bannerId;
        self.gadBannerAdView.delegate = self;
        
        _interstitialId = interstitialId;
        self.interstitialView = [self createAndLoadInterstitial];
    }
    return  self;
}

-(GADRequest*) gadRequest
{
    GADRequest* request = [GADRequest request];
    request.testDevices = @[@"30593b4cd33a3334b05bd269484fdc4c", kGADSimulatorID];
    return request;
}

-(GADInterstitial*) createAndLoadInterstitial
{
    GADInterstitial* interstitialView = [[GADInterstitial alloc] initWithAdUnitID:_interstitialId];
    interstitialView.delegate = self;
    [interstitialView loadRequest:[self gadRequest]];
    return interstitialView;
}

-(CGSize) bannerFrameSize
{
    return kGADAdSizeBanner.size;
}

-(UIView *)bannerView
{
    return self.gadBannerAdView;
}

#pragma mark - Public

-(void)setBannerRootViewController:(UIViewController *)vc
{
    if(!_enabled) return;
    self.gadBannerAdView.rootViewController = vc;
    [self.gadBannerAdView loadRequest:[self gadRequest]];
}

-(void)tryShowInterstitialWithRootController:(UIViewController *)vc
{
    if(!_enabled) return;
    if(self.interstitialView && self.interstitialView.isReady){
        [self.interstitialView presentFromRootViewController:vc];
    }
    if ((self.interstitialView && self.interstitialView.hasBeenUsed) || !self.interstitialView) {
        self.interstitialView = [self createAndLoadInterstitial];
    }
}

-(void) disable
{
    self.gadBannerAdView = nil;
    self.interstitialView = nil;
    _enabled = NO;
}

#pragma mark - GadBannerDelegate

-(void)adView:(GADBannerView *)bannerView didFailToReceiveAdWithError:(GADRequestError *)error
{
//    NSLog(@"didFailToReceiveAdWithError: %@", error);
    if (self.delegate && [self.delegate respondsToSelector:@selector(adRequestFailedWithError:adType:)])
    {
        [self.delegate adRequestFailedWithError:error adType:AdTypeBanner];
    }
}

-(void)adViewDidDismissScreen:(GADBannerView *)bannerView
{
//    NSLog(@"adViewDidDismissScreen");
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(adModalDidDismiss: adType:)])
    {
        [self.delegate adModalDidDismiss:self.gadBannerAdView.adUnitID adType:AdTypeBanner];
    }
}

-(void)adViewDidReceiveAd:(GADBannerView *)bannerView
{
//    NSLog(@"adViewDidReceiveAd");

    if (self.delegate && [self.delegate respondsToSelector:@selector(adRequestSuccesfulForAdType:)])
    {
        [self.delegate adRequestSuccesfulForAdType:AdTypeBanner];
    }
}

-(void)adViewWillDismissScreen:(GADBannerView *)bannerView
{
//    NSLog(@"adViewWillDismissScreen");
    if (self.delegate && [self.delegate respondsToSelector:@selector(adModalWillDismiss:adType:)])
    {
        [self.delegate adModalWillDismiss:self.gadBannerAdView.adUnitID adType:AdTypeBanner];
    }
}

-(void)adViewWillLeaveApplication:(GADBannerView *)bannerView
{
//    NSLog(@"adViewWillLeaveApplication");
    if (self.delegate && [self.delegate respondsToSelector:@selector(adWasTapped:adType:)])
    {
        [self.delegate adWasTapped:self.gadBannerAdView.adUnitID adType:AdTypeBanner];
    }
}

-(void)adViewWillPresentScreen:(GADBannerView *)bannerView
{
//    NSLog(@"adViewWillPresentScreen");
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(adWasTapped:adType:)])
    {
        [self.delegate adWasTapped:self.gadBannerAdView.adUnitID adType:AdTypeBanner];
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(adModalWillAppear:adType:)])
    {
        [self.delegate adModalWillAppear:self.gadBannerAdView.adUnitID adType:AdTypeBanner];
    }
}

#pragma mark - GadInterstitialDelegate


/// Called when an interstitial ad request succeeded. Show it at the next transition point in your
/// application such as when transitioning between view controllers.
- (void)interstitialDidReceiveAd:(GADInterstitial *)ad
{
//    NSLog(@"interstitialDidReceiveAd");
    if(self.delegate && [self.delegate respondsToSelector:@selector(adRequestSuccesfulForAdType:)])
    {
        [self.delegate adRequestSuccesfulForAdType:AdTypeInterstitial];
    }
}

/// Called when an interstitial ad request completed without an interstitial to
/// show. This is common since interstitials are shown sparingly to users.
- (void)interstitial:(GADInterstitial *)ad didFailToReceiveAdWithError:(GADRequestError *)error
{
//    NSLog(@"interstitial didFailToReceiveAdWithError");
    if(self.delegate && [self.delegate respondsToSelector:@selector(adRequestFailedWithError:adType:)])
    {
        [self.delegate adRequestFailedWithError:error adType:AdTypeInterstitial];
    }
    self.interstitialView = [self createAndLoadInterstitial];
}

/// Called just before presenting an interstitial. After this method finishes the interstitial will
/// animate onto the screen. Use this opportunity to stop animations and save the state of your
/// application in case the user leaves while the interstitial is on screen (e.g. to visit the App
/// Store from a link on the interstitial).
- (void)interstitialWillPresentScreen:(GADInterstitial *)ad
{
//    NSLog(@"interstitialWillPresentScreen");
    if(self.delegate && [self.delegate respondsToSelector:@selector(adModalWillAppear:adType:)])
    {
        [self.delegate adModalWillAppear:_interstitialId adType:AdTypeInterstitial];
    }
}

/// Called before the interstitial is to be animated off the screen.
- (void)interstitialWillDismissScreen:(GADInterstitial *)ad
{
//    NSLog(@"interstitialWillDismissScreen");
    self.interstitialView = [self createAndLoadInterstitial];
    if(self.delegate && [self.delegate respondsToSelector:@selector(adModalWillDismiss:adType:)])
    {
        [self.delegate adModalWillDismiss:_interstitialId adType:AdTypeInterstitial];
    }
}

/// Called just after dismissing an interstitial and it has animated off the screen.
- (void)interstitialDidDismissScreen:(GADInterstitial *)ad
{
//    NSLog(@"interstitialDidDismissScreen");
    if(self.delegate && [self.delegate respondsToSelector:@selector(adModalDidDismiss:adType:)])
    {
        [self.delegate adModalDidDismiss:_interstitialId adType:AdTypeInterstitial];
    }
}

/// Called just before the application will background or terminate because the user clicked on an
/// ad that will launch another application (such as the App Store). The normal
/// UIApplicationDelegate methods, like applicationDidEnterBackground:, will be called immediately
/// before this.
- (void)interstitialWillLeaveApplication:(GADInterstitial *)ad
{
//    NSLog(@"interstitialWillLeaveApplication");
    if (self.delegate && [self.delegate respondsToSelector:@selector(adWasTapped:adType:)]) {
        [self.delegate adWasTapped:_interstitialId adType:AdTypeInterstitial];
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(applicationWillTerminateFromAd)]) {
        [self.delegate applicationWillTerminateFromAd];
    }
}

@end
