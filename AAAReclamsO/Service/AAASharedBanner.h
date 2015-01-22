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

@protocol AAASharedBannerDelegate<NSObject>
@optional
- (void) applicationWillTerminateFromAd;
- (void) adWasTapped:(NSString*) adType apId:(NSString*) apId;
- (void) adModalWillDismiss:(NSString*) adType apId:(NSString*) apId;
- (void) adModalDidDismiss:(NSString*) adType apId:(NSString*) apId;
- (void) adModalDidAppear:(NSString*) adType apId:(NSString*) apId;
- (void) adModalWillAppear:(NSString*) adType apId:(NSString*) apId;
- (void) adRequestSuccesful;
- (void) adRequestFailedWithError:(NSError*) error;
@end

@interface AAASharedBanner : NSObject<CLLocationManagerDelegate>

@property (nonatomic, strong, readonly) UIView* bannerView;
@property (nonatomic, weak) id<AAASharedBannerDelegate> delegate;

- (instancetype)initWithAdUnitId:(NSString*) adUnitId andRootViewController:(UIViewController*) rootVC;
- (void) setRootViewController:(UIViewController*) vc;
- (void) start;
- (void) stop;
-(CGSize) bannerFrameSize;
@end
