//
//  AAAGlobals.h
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 08/12/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class AAASharedBanner;

#pragma mark - Flurry

static NSString* const FlurryEventAdOpened = @"ad opened";
static NSString* const FlurryEventCatalogOpened = @"Catalog watched";
static NSString* const FlurryEventMarketOpened = @"Market opened";
static NSString* const FlurryEventCatalogPercentageSeen = @"Percentage of catalog seen";
static NSString* const FlurryEventAdServed = @"ad served";

static NSString* const FlurryParameterPercentage = @"Percentage";
static NSString* const FlurryParameterMarketName = @"Market";
static NSString* const FlurryParameterMarketPriority = @"Market priority";
static NSString* const FlurryParameterCatalogIndex = @"Catalog index";
static NSString* const FlurryParameterCatalogPriority = @"Catalog priority";
static NSString* const FlurryParameterCatalogId = @"Catalog id";

@interface AAAGlobals : NSObject

+(AAAGlobals*) sharedInstance;
-(AAASharedBanner *)sharedBannerViewWithRootViewController:(UIViewController*) rootViewController;
+(UIImage*)imageWithShadowForImage:(UIImage *)initialImage;
-(NSString*) flurryId;
-(NSString*) privacyPolicyURL;
@end
