//
//  AAAJsObjCWrapper.m
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 19/11/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import "AAAwww.h"
#import "AAACatalog.h"
#import "AAAMarket.h"
#import <RestKit/RestKit.h>

static NSString* baseURL = @"https://marklogj-andreioprea.rhcloud.com";
//static NSString* baseURL = @"http://marklogjtest-andreioprea.rhcloud.com";
static NSString* downloadMarketsURL = @"/markets/list";
static NSString* downloadCatalogsURL = @"/catalogs/list/active";
static NSString* downloadCatalogPagesUrl = @"/pages";

@interface AAAwww(){
}

@end

@implementation AAAwww

static AAAwww* _instance;

+(AAAwww *)instance
{
    if (!_instance) {
        _instance = [[AAAwww alloc] init];
        RKLogConfigureByName("RestKit/Network", RKLogLevelError);
    }
    return _instance;
}

-(void)downloadMarketsWithCompletionHandler:(DownloadMarketsBlock)completionHandler
{
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[AAAMarket class]];
    [mapping addAttributeMappingsFromArray:@[@"identifier", @"miniLogoURL", @"logoURL", @"name"]];
    
    NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful); // Anything in 2xx
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:downloadMarketsURL keyPath:nil statusCodes:statusCodes];

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", baseURL, downloadMarketsURL]]];
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[responseDescriptor]];
    [operation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *result) {
        completionHandler([result array], nil);
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        completionHandler(nil, error);
    }];
    [operation start];
}

-(void) downloadCatalogInformationsWithCompletionHandler:(DownloadCatalogsBlock)completionHandler
{
    RKObjectMapping* marketMapping = [RKObjectMapping mappingForClass:[AAAMarket class]];
    [marketMapping addAttributeMappingsFromArray:@[@"identifier", @"miniLogoURL", @"logoURL", @"name", @"priority"]];
    
    RKObjectMapping* catalogMapping = [RKObjectMapping mappingForClass:[AAACatalog class]];
    [catalogMapping addAttributeMappingsFromDictionary:@{@"active":@"active", @"description":@"bkDescription", @"from":@"activeFrom", @"to" : @"activeTo", @"name":@"name", @"identifier":@"identifier", @"url":@"pagesUrl", @"priority":@"priority"}];
    [catalogMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"market" toKeyPath:@"market" withMapping:marketMapping]];
    
    NSIndexSet* statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful);
    RKResponseDescriptor* responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:catalogMapping method:RKRequestMethodAny pathPattern:downloadCatalogsURL keyPath:nil statusCodes:statusCodes];
    
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", baseURL, downloadCatalogsURL]]];
    RKObjectRequestOperation* operation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[responseDescriptor]];
    [operation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        completionHandler([mappingResult array], nil);
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        completionHandler(nil, error);
    }];
    [operation start];
}

-(void) downloadPagesUrlsForCatalog:(int) catalogId withCompletionHandler:(DownloadPagesForCatalogBlock)completionHandler
{
    RKObjectManager* manager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:baseURL]];
    AFHTTPClient * client = manager.HTTPClient;
    [client getPath:[NSString stringWithFormat:@"%@/%i", downloadCatalogPagesUrl, catalogId]
         parameters:nil
            success:^(AFHTTPRequestOperation *operation, id responseObject) {
                completionHandler([NSArray arrayWithArray:[[NSDictionary dictionaryWithDictionary:responseObject] objectForKey:@"pages"]], nil);
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"failure: %li", (long)operation.response.statusCode);
            }];
}

-(NSString *)host
{
    return  baseURL;
//    return [baseURL stringByReplacingOccurrencesOfString:@"http://" withString:@""];
}

@end
