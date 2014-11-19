//
//  AAAJsObjCBridge.h
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 11/11/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <UIKit/UIKit.h>

@protocol AAAJsCallbacksDelegate <NSObject>
@optional
-(void) aaaJsObjCBridgeWebViewFinishLoading;
-(void) aaaJsObjCBridgeWebViewFinishLoadingWithError:(NSError*) error;
@end

@interface AAAJsObjCBridge : NSObject<UIWebViewDelegate>

@property(nonatomic, strong) NSURL* URL;

+(AAAJsObjCBridge*) instance;
-(void) addDelegate:(id<AAAJsCallbacksDelegate>) del;
-(void) removeDelegate:(id<AAAJsCallbacksDelegate>) del;

-(void) loadJavascriptFile:(NSString*) filename;
-(void) registerJsCallbackObject:(id<JSExport>) obj callbackObjVariableName:(NSString*)varName;
-(void) callJsFunction:(NSString*) functionName withParams:(NSArray*) params;
-(void) callJsFunction:(NSString *)functionName withStringParams:(NSString *)firstParam, ...;
-(void) callJsFunction:(NSString*) functionName withArguments:(NSArray*) args onGlobalObject:(NSString*) objectName;
-(void) registerForFunctionCallback:(NSString*) functionName;
-(void) registerForFunctionCallbackWithSelector:(SEL)selector;
@end
