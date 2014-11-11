//
//  AAAMarket.m
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 11/11/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import "AAAMarket.h"

@implementation AAAMarket

+(instancetype)marketWithName:(NSString *)title andLogoImage:(UIImage*) img
{
    AAAMarket* market = [[AAAMarket alloc] init];
    market.name = title;
    market.imgLogo = img;
    market.catalogs = [NSMutableArray array];
    return market;
}

@end
