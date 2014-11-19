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
        _webView = [[UIWebView alloc] initWithFrame:CGRectMake(10, 10, 200, 200)];
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
    JSContext* context = [self contextForWebView:_webView];
    [context setExceptionHandler:^(JSContext *context, JSValue *value) {
        NSLog(@"WEB JS Exception: %@", value);
    }];
    NSString* jquery = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"jquery-2.1.1.min" ofType:@"js"] encoding:NSUTF8StringEncoding error:nil];
    [_webView performSelectorOnMainThread:@selector(stringByEvaluatingJavaScriptFromString:) withObject:jquery waitUntilDone:YES];
    NSString *javaScript=[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"markets" ofType:@"js"] encoding:NSUTF8StringEncoding error:nil];
    [_webView performSelectorOnMainThread:@selector(stringByEvaluatingJavaScriptFromString:) withObject:javaScript waitUntilDone:YES];
    context[@"Log"] = ^(NSString* message)
    {
        NSLog(@"AAAJsObjCBridge: %@",
              message);
    };
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

-(void) callJsFunction:(NSString*) functionName withArguments:(NSArray*) args onGlobalObject:(NSString*) objectName
{
    assert(functionName);
    assert(objectName);
    JSContext* context = [self contextForWebView:_webView];
    JSValue* obj = context[objectName];
    [obj invokeMethod:functionName withArguments:args];
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
    BOOL hasParam = [selectorAsString hasSuffix:@":"];
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

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"didFailLoadWithError");
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    
    NSLog(@"shouldStartLoadWithRequest:%@", request);
    return YES;
}

-(void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSLog(@"webViewDidFinishLoad");
}

-(void)webViewDidStartLoad:(UIWebView *)webView
{
    NSLog(@"webViewDidStartLoad");
}
@end
