//
//  AAASharedBanner.h
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 08/12/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>

@import GoogleMobileAds;

typedef enum AdType{None, AdTypeBanner, AdTypeInterstitial} AdType;

@protocol AAAAdsDelegate<NSObject>
@optional
- (void) applicationWillTerminateFromAd;
- (void) adWasTapped:(NSString*) apId adType:(AdType) adType;
- (void) adModalWillDismiss:(NSString*) apId adType:(AdType) adType;
- (void) adModalDidDismiss:(NSString*) apId adType:(AdType) adType;
- (void) adModalDidAppear:(NSString*) apId adType:(AdType) adType;
- (void) adModalWillAppear:(NSString*) apId adType:(AdType) adType;
- (void) adRequestSuccesfulForAdType:(AdType) adType;
- (void) adRequestFailedWithError:(NSError*) error adType:(AdType) adType;
@end

@interface AAAAds : NSObject<CLLocationManagerDelegate, GADBannerViewDelegate, GADInterstitialDelegate>

@property (nonatomic, strong, readonly) UIView* bannerView;
@property (nonatomic, weak) id<AAAAdsDelegate> delegate;

- (id) initWithBannerAdUnitId:(NSString*) bannerId andInterstitialUnitId:(NSString*) interstitialId;
- (void) setBannerRootViewController:(UIViewController*) vc;
- (void) tryShowInterstitialWithRootController:(UIViewController*) vc;
- (void) disable;
-(CGSize) bannerFrameSize;
@end
