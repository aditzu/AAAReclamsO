//
//  AAAJsObjCWrapper.h
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 19/11/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AAAJsObjCBridge.h"

typedef void(^DownloadMarketsBlock)(NSArray* markets);

@interface AAAJsObjCWrapper : NSObject<AAAJsCallbacksDelegate>
{
//    NSMutableArray* delegates;
    AAAJsObjCBridge* jsBridge;
}

+(AAAJsObjCWrapper*) instance;

//-(void) registerDelegate:(id<AAAJsObjCWrapperDelegate>) del;
//-(void) unregisterDelegate:(id<AAAJsObjCWrapperDelegate>) del;
-(void) downloadMarketsWithCompletionHandler:(DownloadMarketsBlock) completionHandler;

@end
