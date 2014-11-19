//
//  AAAJsObjCWrapper.m
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 19/11/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import "AAAwww.h"
#import "AAAMarket.h"
#import <RestKit/RestKit.h>

@interface AAAwww(){
}

@end

@implementation AAAwww

static AAAwww* _instance;

+(AAAwww *)instance
{
    if (!_instance) {
        _instance = [[AAAwww alloc] init];
    }
    return _instance;
}

-(void)downloadMarketsWithCompletionHandler:(DownloadMarketsBlock)completionHandler
{
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[AAAMarket class]];
    [mapping addAttributeMappingsFromArray:@[@"identifier", @"miniLogoURL", @"logoURL", @"name"]];
    
    NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful); // Anything in 2xx
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:@"/markets/list/" keyPath:nil statusCodes:statusCodes];

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://192.168.0.16:8090/markets/list/"]];
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[responseDescriptor]];
    [operation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *result) {
        completionHandler([result array], nil);
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        completionHandler(nil, error);
    }];
    [operation start];
}
@end
