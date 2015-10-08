//
//  AAAGlobals.h
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 08/12/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class AAAAds;

#pragma mark - Flurry

static NSString* const FlurryEventAdOpened = @"Ad opened";
static NSString* const FlurryEventAdTapped = @"Ad tapped";//this is exactly as the one above, but that event name was not used properly, so this is a try to fix that
static NSString* const FlurryEventAdFailedToLoad = @"Ad failed to load";
static NSString* const FlurryEventAdServed = @"Ad served";
static NSString* const FlurryEventCatalogOpened = @"Catalog watched";
static NSString* const FlurryEventMarketOpened = @"Market opened";
static NSString* const FlurryEventCatalogPercentageSeen = @"Percentage of catalog seen";
static NSString* const FlurryEventPrivacyPolicyOpened = @"Privacy Policy opened";
static NSString* const FlurryEventMarketsReloadedManually = @"Markets reloaded manually";
static NSString* const FlurryEventEditMenuOpened = @"Opened Edit Menu";
static NSString* const FlurryEventErrorFromServer = @"Server error";
static NSString* const FlurryEventErrorNoInternet = @"No internet";
static NSString* const FlurryEventStartedFromNotification = @"Started from notification";
static NSString* const FlurryEventDidRegisterForNotification = @"Did Register For Notification";
static NSString* const FlurryEventDidTryToBuyNoAds = @"Did try to buy no ads";
static NSString* const FlurryEventDidBuyNoAds = @"Did buy no ads";
static NSString* const FlurryEventDidTryToRestore = @"Did try to restore purchases";
static NSString* const FlurryEventDidRestore = @"Did restore purchases";

static NSString* const FlurryParameterAdType = @"AD type";
static NSString* const FlurryParameterPercentage = @"Percentage";
static NSString* const FlurryParameterMarketName = @"Market";
static NSString* const FlurryParameterMarketPriority = @"Market priority";
static NSString* const FlurryParameterCatalogIndex = @"Catalog index";
static NSString* const FlurryParameterCatalogPriority = @"Catalog priority";
static NSString* const FlurryParameterCatalogId = @"Catalog id";
static NSString* const FlurryParameterBOOL = @"boolean";

@interface AAAGlobals : NSObject

@property (nonatomic, strong) AAAAds* ads;

+(AAAGlobals*) sharedInstance;
//-(AAAAds *)adsViewWithRootViewController:(UIViewController*) rootViewController;
+(UIImage*)imageWithShadowForImage:(UIImage *)initialImage;
-(NSString*) flurryId;
-(NSString*) privacyPolicyURL;
@end
