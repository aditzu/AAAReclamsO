//
//  AAAMarket.m
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 11/11/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import "AAAMarket.h"
#import "AAAwww.h"

@implementation AAAMarket

@synthesize name, miniLogoURL, logoURL, identifier;

-(instancetype)init
{
    if (self = [super init])
    {
        self.catalogs = [NSMutableArray array];
    }
    return self;
}

+(instancetype)marketWithName:(NSString *)title andLogoImage:(UIImage*) img;
{
    AAAMarket* market = [[AAAMarket alloc] init];
    market.name = title;
    market.imgLogo = img;
    market.catalogs = [NSMutableArray array];
    return market;
}

-(void)setLogoURL:(NSString *)_logoURL
{
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"http://.*\\.com/" options:NSRegularExpressionCaseInsensitive error:&error];
    
    NSString *modifiedString = [regex stringByReplacingMatchesInString:_logoURL options:0 range:NSMakeRange(0, [_logoURL length]) withTemplate:@""];
    logoURL = [NSString stringWithFormat:@"%@/%@",[[AAAwww instance] host], [modifiedString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]]];
}

-(void)setMiniLogoURL:(NSString *)_miniLogoURL
{
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"http://.*\\.com/" options:NSRegularExpressionCaseInsensitive error:&error];
    
    NSString *modifiedString = [regex stringByReplacingMatchesInString:_miniLogoURL options:0 range:NSMakeRange(0, [_miniLogoURL length]) withTemplate:@""];
    miniLogoURL = [NSString stringWithFormat:@"%@/%@",[[AAAwww instance] host], [modifiedString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]]];
}

-(BOOL)isEqual:(id)object
{
    return self.identifier == ((AAAMarket*)object).identifier;
}

-(NSUInteger)hash
{
    return identifier;
}

@end
