//
//  AAAJsObjCBridge.m
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 11/11/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import "AAAJsObjCBridge.h"

#define SuppressPerformSelectorLeakWarning(Stuff) \
    do { \
        _Pragma("clang diagnostic push") \
        _Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
        Stuff; \
        _Pragma("clang diagnostic pop") \
    } while (0)

@interface AAAJsObjCBridge()
{
    NSMutableArray* delegates;
    UIWebView* _webView;
}

@end

@implementation AAAJsObjCBridge

static AAAJsObjCBridge* _instance;

+(AAAJsObjCBridge *)instance
{
    if (!_instance) {
        _instance = [[AAAJsObjCBridge alloc] init];
    }
    return _instance;
}

-(instancetype)init
{
    if (_instance) {
        NSLog(@"Error. Could not instantiate a singleton");
        return nil;
    }
    if (self = [super init]) {
        delegates = [NSMutableArray array];
        _webView = [[UIWebView alloc] init];
        [[[[UIApplication sharedApplication] delegate] window] addSubview:_webView];
    
        NSString* htmlPath = [[NSBundle mainBundle] pathForResource:@"app" ofType:@"html"];
        self.URL = [[NSURL alloc] initFileURLWithPath:htmlPath];
    }
    return self;
}

-(void)setURL:(NSURL *)URL
{
    _URL = URL;
    NSURLRequest* request = [NSURLRequest requestWithURL:URL];
    _webView.delegate = self;
    [_webView loadRequest:request];
    [[self contextForWebView:_webView] setExceptionHandler:^(JSContext *context, JSValue *value) {
        NSLog(@"WEB JS Exception: %@", value);
    }];
}

#pragma mark - Instance methods

#pragma mark Public

-(void)addDelegate:(id<AAAJsCallbacksDelegate>)del
{
    [delegates addObject:del];
}

-(void)removeDelegate:(id<AAAJsCallbacksDelegate>)del
{
    [delegates removeObject: del];
}

-(void) callJsFunction:(NSString *)functionName withParams:(NSArray*)params
{
    assert(functionName);
    JSContext* context = [self contextForWebView:_webView];
    JSValue* alertFunction = context[functionName];
    [alertFunction callWithArguments:params];
}

-(void)callJsFunction:(NSString *)functionName withStringParams:(NSString *)firstParam, ...
{
    assert(functionName);
    
    NSMutableArray* params = [NSMutableArray array];    
    va_list args;
    va_start(args, firstParam);
    for (NSString* arg = firstParam; arg != nil; arg = va_arg(args, NSString*)) {
        [params addObject:arg];
    }
    va_end(args);
    
    JSContext* context = [self contextForWebView:_webView];
    JSValue* alertFunction = context[functionName];
    [alertFunction callWithArguments:params];
}

-(void)registerJsCallbackObject:(id<JSExport>)obj callbackObjVariableName:(NSString *)varName
{
    JSContext* context = [self contextForWebView:_webView];
    context[varName] = obj;
}

-(void) registerForFunctionCallbackWithSelector:(SEL)selector
{
    NSString* selectorAsString = NSStringFromSelector(selector);
    NSString* functionName = [selectorAsString stringByReplacingOccurrencesOfString:@":" withString:@""];
    JSContext* context = [self contextForWebView:_webView];
    BOOL hasParam = [selectorAsString containsString:@":"];
    context[functionName] = ^(id param)
    {
        for (id<AAAJsCallbacksDelegate> delegate in delegates)
        {
            if ([delegate respondsToSelector:selector])
            {
                if (hasParam) {
                    SuppressPerformSelectorLeakWarning([delegate performSelector:selector withObject:param]);
                }
                else
                {
                    SuppressPerformSelectorLeakWarning([delegate performSelector:NSSelectorFromString(selectorAsString)]);
                }
            }
        }
    };
}

-(void) registerForFunctionCallback:(NSString*)functionName
{
    JSContext* context = [self contextForWebView:_webView];
    context[functionName] = ^(NSArray* params)
    {
        for (id<AAAJsCallbacksDelegate> delegate in delegates)
        {
            if ([delegate respondsToSelector:NSSelectorFromString(functionName)])
            {
                SuppressPerformSelectorLeakWarning([delegate performSelector:NSSelectorFromString(functionName)]);
            }
            else if ([delegate respondsToSelector:NSSelectorFromString([NSString stringWithFormat:@"%@:", functionName])])
            {
                SuppressPerformSelectorLeakWarning([delegate performSelector:NSSelectorFromString([NSString stringWithFormat:@"%@:", functionName]) withObject:params]);
            }
        }
    };
}

#pragma mark Private

-(JSContext*) contextForWebView:(UIWebView*) webv
{
    return [webv valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
}

@end
