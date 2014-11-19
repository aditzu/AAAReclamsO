//
//  AAAJsObjCWrapper.h
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 19/11/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^DownloadMarketsBlock)(NSArray* markets, NSError* error);

@interface AAAwww : NSObject
{
}

+(AAAwww*) instance;
-(void) downloadMarketsWithCompletionHandler:(DownloadMarketsBlock) completionHandler;

@end
