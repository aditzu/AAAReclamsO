//
//  AAAGlobals.m
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 08/12/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import "AAAGlobals.h"
#import "AAAAds.h"
@interface AAAGlobals()
{
    AAAAds* adView;
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

-(AAAAds *)ads
{
    if (!adView) {
        adView = [[AAAAds alloc] initWithBannerAdUnitId:[self bannerUnitId] andInterstitialUnitId:[self interstitialApId]];
    }
   return adView;
}

+(UIImage*)imageWithShadowForImage:(UIImage *)initialImage
{
    
    CGColorSpaceRef colourSpace = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = (CGBitmapInfo) kCGImageAlphaPremultipliedLast;
    CGContextRef shadowContext = CGBitmapContextCreate(NULL, initialImage.size.width, initialImage.size.height + 4, CGImageGetBitsPerComponent(initialImage.CGImage), 0, colourSpace, bitmapInfo);// kCGImageAlphaPremultipliedLast
    CGColorSpaceRelease(colourSpace);
    
    CGContextSetShadowWithColor(shadowContext, CGSizeMake(0,4), 70, [UIColor blackColor].CGColor);
    CGContextDrawImage(shadowContext, CGRectMake(0, 4, initialImage.size.width, initialImage.size.height), initialImage.CGImage);
    
    CGImageRef shadowedCGImage = CGBitmapContextCreateImage(shadowContext);
    CGContextRelease(shadowContext);
    
    UIImage * shadowedImage = [UIImage imageWithCGImage:shadowedCGImage];
    CGImageRelease(shadowedCGImage);
    
    return shadowedImage;
}

-(NSString *)flurryId
{
    return @"MKCBQ4PX57GQJS36H878";
}

-(NSString*) bannerUnitId
{
//    return @"1234";// @"ca-app-pub-2163416701589769/7779082332"; //gad
    return @"ca-app-pub-2163416701589769/2830834336";
//    return @"190723"; //millenial
}

-(NSString*) interstitialApId
{
    return @"ca-app-pub-2163416701589769/6702630730";
}

-(NSString *)privacyPolicyURL
{
    return @"http://alphaappers.com/ofertamea/disclaimer.html";
}

-(NSString *)fbPageURLOpenSafari
{
    return @"https://www.facebook.com/Alpha-Appers-803631623016706/?ref=ofertameaios";
}

-(NSString *)fbPageURLOpenApp
{
    return @"fb://profile/803631623016706/?ref=ofertameaiosApp";
}

@end
