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

-(AAASharedBanner *)sharedBannerViewWithRootViewController:(UIViewController*) rootViewController
{
    if (!bannerView) {
        bannerView = [[AAASharedBanner alloc] initWithAdUnitId:[self apId] andRootViewController:rootViewController];
    }
    else
    {
        [bannerView setRootViewController:rootViewController];
    }
    return bannerView;
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

-(NSString*) apId
{
//    return @"ca-app-pub-3940256099942544/2934735716";// @"ca-app-pub-2163416701589769/7779082332"; //gad
    return @"190723"; //millenial
}

-(NSString *)privacyPolicyURL
{
    return @"http://alphaappers.com/ofertamea/disclaimer.html";
}

@end
