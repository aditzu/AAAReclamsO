//
//  AAAJsObjCWrapper.m
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 19/11/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import "AAAJsObjCWrapper.h"
#import "UNIRest.h"

@interface AAAJsObjCWrapper(){
    BOOL webViewisLoaded;
    NSMutableArray* methodsQueue;
}

@end

@implementation AAAJsObjCWrapper

static AAAJsObjCWrapper* _instance;

+(AAAJsObjCWrapper *)instance
{
    if (!_instance) {
        _instance = [[AAAJsObjCWrapper alloc] init];
    }
    return _instance;
}

-(instancetype)init
{
    if (self = [super init]) {
//        delegates = [NSMutableArray array];
        jsBridge = [AAAJsObjCBridge instance];
        methodsQueue = [NSMutableArray array];
        [jsBridge addDelegate:self];
        [jsBridge loadJavascriptFile:@"jquery-2.1.1.min"];
        [jsBridge loadJavascriptFile:@"markets"];
    }
    return self;
}

//-(void)registerDelegate:(id<AAAJsObjCWrapperDelegate>)del
//{
//    [self unregisterDelegate:del];
//    [delegates addObject:del];
//}

//-(void)unregisterDelegate:(id<AAAJsObjCWrapperDelegate>)del
//{
//    if ([delegates containsObject:del]) {
//        [delegates removeObject:del];
//    }
//}

-(void)downloadMarketsWithCompletionHandler:(DownloadMarketsBlock)completionHandler
{
//    if (!webViewisLoaded)
//    {
//        [self addMethodToQueue:@selector(downloadMarketsWithCompletionHandler:) withParameters:[completionHandler copy], nil];
//        return;
//    }
//    [jsBridge callJsFunction:@"getMarkets" withArguments:@[] onGlobalObject:@"marks"];
//    completionHandler([NSArray array]);
    
    UNIUrlConnection* response = [[UNIRest get:^(UNISimpleRequest *simpleRequest) {
        [simpleRequest setUrl:@"http://192.168.0.16:8090/markets/list/"];
    }] asJsonAsync:^(UNIHTTPJsonResponse *jsonResponse, NSError *error) {
        NSString* body = [[NSString alloc] initWithData:jsonResponse.rawBody encoding:NSUTF8StringEncoding];
        NSLog(@"jsonResponse:%@ error:%@", body, error);
    }];
}

-(void) addMethodToQueue:(SEL)selectorToAdd withParameters:(NSObject*) param,...
{
    NSMethodSignature* signature = [[AAAJsObjCWrapper class] instanceMethodSignatureForSelector:selectorToAdd];
    NSInvocation* inv = [NSInvocation invocationWithMethodSignature:signature];
    [inv setTarget:self];
    [inv setSelector:selectorToAdd];
    
    NSMutableArray* params = [NSMutableArray array];
    va_list args;
    va_start(args, param);
    for (NSObject* arg = param; arg != nil; arg = va_arg(args, NSObject*)) {
        [params addObject:[arg copy]];
    }
    va_end(args);
    
    [params enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [inv setArgument:&obj atIndex:idx];
    }];
    
    [methodsQueue addObject:inv];
}

#pragma mark - JSBridgeCallbacks

-(void)aaaJsObjCBridgeWebViewFinishLoading
{
    webViewisLoaded = YES;
    for (NSInvocation* invocation in methodsQueue)
    {
        [invocation invoke];
    }
}

-(void)aaaJsObjCBridgeWebViewFinishLoadingWithError:(NSError *)error
{
    NSLog(@"aaaJsObjCBridgeWebViewFinishLoadingWithError: %@", error);
}

@end
