//
//  AAASharedBanner.m
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 08/12/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#define MILLENNIAL_IPHONE_AD_VIEW_FRAME CGRectMake(0, 0, 320, 50)
#define MILLENNIAL_IPAD_AD_VIEW_FRAME CGRectMake(0, 0, 728, 90)
#define MILLENNIAL_AD_VIEW_FRAME ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? MILLENNIAL_IPAD_AD_VIEW_FRAME : MILLENNIAL_IPHONE_AD_VIEW_FRAME)


#import "AAASharedBanner.h"

#import <MillennialMedia/MMSDK.h>
#import <MillennialMedia/MMAdView.h>
//#import "GADRequest.h"

@interface AAASharedBanner()
{
    BOOL didFailToLoadLocation;
    BOOL isStarted;
}

@property (nonatomic, strong) CLLocationManager* locationManager;
@property (nonatomic, strong) MMAdView* mmBannerAdView;
@property (nonatomic, strong) NSTimer* adsTimer;
@end

@implementation AAASharedBanner

-(instancetype)initWithAdUnitId:(NSString*) adUnitId andRootViewController:(UIViewController*) rootVC
{
    if (self = [super init])
    {
        self.locationManager = [[CLLocationManager alloc] init];
        [self.locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
        self.locationManager.delegate = self;
        [self.locationManager startUpdatingLocation];
        
        // Notification will fire when an ad causes the application to terminate or enter the background
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillTerminateFromAd:)
                                                     name:MillennialMediaAdWillTerminateApplication
                                                   object:nil];
        
        // Notification will fire when an ad is tapped.
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(adWasTapped:)
                                                     name:MillennialMediaAdWasTapped
                                                   object:nil];
        
        // Notification will fire when an ad modal will appear.
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(adModalWillAppear:)
                                                     name:MillennialMediaAdModalWillAppear
                                                   object:nil];
        
        // Notification will fire when an ad modal did appear.
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(adModalDidAppear:)
                                                     name:MillennialMediaAdModalDidAppear
                                                   object:nil];
        
        // Notification will fire when an ad modal will dismiss.
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(adModalWillDismiss:)
                                                     name:MillennialMediaAdModalWillDismiss
                                                   object:nil];
        
        // Notification will fire when an ad modal did dismiss.
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(adModalDidDismiss:)
                                                     name:MillennialMediaAdModalDidDismiss
                                                   object:nil];
        
        CGRect rootVCFrame = rootVC.view.bounds;
        CGRect mmBannerFrame = CGRectMake((rootVCFrame.size.width - MILLENNIAL_AD_VIEW_FRAME.size.width)/2, rootVCFrame.size.height - MILLENNIAL_AD_VIEW_FRAME.size.height, MILLENNIAL_AD_VIEW_FRAME.size.width, MILLENNIAL_AD_VIEW_FRAME.size.height);
        // Returns an autoreleased MMAdView object
        self.mmBannerAdView = [[MMAdView alloc] initWithFrame:mmBannerFrame
                                                   apid:adUnitId
                                     rootViewController:rootVC];        
    }
    return self;
}

-(NSTimer *)adsTimer
{
    if (_adsTimer && _adsTimer.isValid) {
        return _adsTimer;
    }
    _adsTimer = [NSTimer timerWithTimeInterval:30.0f target:self selector:@selector(getAd) userInfo:nil repeats:YES];
    return _adsTimer;
}

-(UIView *)bannerView
{
    return self.mmBannerAdView;
}

-(void)dealloc
{
    [_adsTimer invalidate];
    _adsTimer = nil;
    
    // Remove notification observers
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MillennialMediaAdWillTerminateApplication
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MillennialMediaAdWasTapped
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MillennialMediaAdModalWillAppear
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MillennialMediaAdModalDidAppear
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MillennialMediaAdModalWillDismiss
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MillennialMediaAdModalDidDismiss
                                                  object:nil];
}

- (void)getAd
{
    // Create an MMRequest object with location data
    MMRequest *request = didFailToLoadLocation ? [MMRequest request] : [MMRequest requestWithLocation:self.locationManager.location];
    
    // Get a banner ad
    [self.mmBannerAdView getAdWithRequest:request onCompletion:^(BOOL success, NSError *error) {
        if (success) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(adRequestSuccesful)]) {
                [self.delegate adRequestSuccesful];
            }
            NSLog(@"AD REQUEST SUCCEEDED");
        }
        else {
            if (self.delegate && [self.delegate respondsToSelector:@selector(adRequestFailedWithError:)]) {
                [self.delegate adRequestFailedWithError:error];
            }
            NSLog(@"AD REQUEST FAILED WITH ERROR %@", error);
        }
    }];
}

#pragma mark - Public

-(void)start
{
    if (isStarted) {
        NSLog(@"Ads are started.\nTried to start serving ads when has not been stopped before!");
        return;
    }
    isStarted = YES;
    [self getAd];
    [self.adsTimer fire];
}

-(void)stop
{
    isStarted = NO;
    [self.adsTimer invalidate];
}

-(void)setRootViewController:(UIViewController *)vc
{
    self.mmBannerAdView.rootViewController = vc;
}

#pragma mark - Millennial Media Notification Methods

- (void)adWasTapped:(NSNotification *)notification
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(adWasTapped:apId:)])
    {
        NSString* adType = [[notification userInfo] objectForKey:MillennialMediaAdTypeKey];
        NSString* apid = [[notification userInfo] objectForKey:MillennialMediaAPIDKey];
        [self.delegate adWasTapped:adType apId:apid];
    }
    
    NSLog(@"AD WAS TAPPED");
    NSLog(@"TAPPED AD IS TYPE %@", [[notification userInfo] objectForKey:MillennialMediaAdTypeKey]);
    NSLog(@"TAPPED AD APID IS %@", [[notification userInfo] objectForKey:MillennialMediaAPIDKey]);
    NSLog(@"TAPPED AD IS OBJECT %@", [[notification userInfo] objectForKey:MillennialMediaAdObjectKey]);
    
    if ([[notification userInfo] objectForKey:MillennialMediaAdObjectKey] == self.mmBannerAdView) {
        NSLog(@"TAPPED AD IS THE _bannerAdView INSTANCE VARIABLE");
    }
}

- (void)applicationWillTerminateFromAd:(NSNotification *)notification
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(applicationWillTerminateFromAd)]) {
        [self.delegate applicationWillTerminateFromAd];
    }
    NSLog(@"AD WILL OPEN SAFARI");
    // No User Info is passed for this notification
}

- (void)adModalWillDismiss:(NSNotification *)notification
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(adModalWillDismiss:apId:)])
    {
        NSString* adType = [[notification userInfo] objectForKey:MillennialMediaAdTypeKey];
        NSString* apid = [[notification userInfo] objectForKey:MillennialMediaAPIDKey];
        [self.delegate adModalWillDismiss:adType apId:apid];
    }
    
    NSLog(@"AD MODAL WILL DISMISS");
    NSLog(@"AD IS TYPE %@", [[notification userInfo] objectForKey:MillennialMediaAdTypeKey]);
    NSLog(@"AD APID IS %@", [[notification userInfo] objectForKey:MillennialMediaAPIDKey]);
    NSLog(@"AD IS OBJECT %@", [[notification userInfo] objectForKey:MillennialMediaAdObjectKey]);
}

- (void)adModalDidDismiss:(NSNotification *)notification
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(adModalDidDismiss:apId:)])
    {
        NSString* adType = [[notification userInfo] objectForKey:MillennialMediaAdTypeKey];
        NSString* apid = [[notification userInfo] objectForKey:MillennialMediaAPIDKey];
        [self.delegate adModalDidDismiss:adType apId:apid];
    }
    
    NSLog(@"AD MODAL DID DISMISS");
    NSLog(@"AD IS TYPE %@", [[notification userInfo] objectForKey:MillennialMediaAdTypeKey]);
    NSLog(@"AD APID IS %@", [[notification userInfo] objectForKey:MillennialMediaAPIDKey]);
    NSLog(@"AD IS OBJECT %@", [[notification userInfo] objectForKey:MillennialMediaAdObjectKey]);
}

- (void)adModalWillAppear:(NSNotification *)notification
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(adModalWillAppear:apId:)])
    {
        NSString* adType = [[notification userInfo] objectForKey:MillennialMediaAdTypeKey];
        NSString* apid = [[notification userInfo] objectForKey:MillennialMediaAPIDKey];
        [self.delegate adModalWillAppear:adType apId:apid];
    }
    
    NSLog(@"AD MODAL WILL APPEAR");
    NSLog(@"AD IS TYPE %@", [[notification userInfo] objectForKey:MillennialMediaAdTypeKey]);
    NSLog(@"AD APID IS %@", [[notification userInfo] objectForKey:MillennialMediaAPIDKey]);
    NSLog(@"AD IS OBJECT %@", [[notification userInfo] objectForKey:MillennialMediaAdObjectKey]);
}

- (void)adModalDidAppear:(NSNotification *)notification
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(adModalDidAppear:apId:)])
    {
        NSString* adType = [[notification userInfo] objectForKey:MillennialMediaAdTypeKey];
        NSString* apid = [[notification userInfo] objectForKey:MillennialMediaAPIDKey];
        [self.delegate adModalDidAppear:adType apId:apid];
    }
    
    NSLog(@"AD MODAL DID APPEAR");
    NSLog(@"AD IS TYPE %@", [[notification userInfo] objectForKey:MillennialMediaAdTypeKey]);
    NSLog(@"AD APID IS %@", [[notification userInfo] objectForKey:MillennialMediaAPIDKey]);
    NSLog(@"AD IS OBJECT %@", [[notification userInfo] objectForKey:MillennialMediaAdObjectKey]);
}

#pragma mark - CLLOcationmanager Delegate

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    didFailToLoadLocation = YES;
}

@end
