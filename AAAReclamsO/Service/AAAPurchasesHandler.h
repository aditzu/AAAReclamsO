//
//  AAAPurchasesHandler.h
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 06/10/15.
//  Copyright © 2015 Adrian Ancuta. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AAAPurchaseHandlerDelegate<NSObject>
@optional
-(void) purchaseSuccesfully:(nonnull NSString*) productId;
-(void) purchaseFailed:(nonnull NSString*) productId withError:(nonnull NSError*) error;
-(void) restoreFinishedForProductWithId:(nonnull NSString*) productId withError:(nullable NSError*) error;
@end

@interface AAAPurchasesHandler : NSObject

+(nonnull AAAPurchasesHandler*) instance;
+(BOOL) hasAdsEnabled;
-(void) purchaseNoads;
-(void) restorePurchases;
-(void) addDelegate:(nonnull id<AAAPurchaseHandlerDelegate>) delegate;
-(void) removeDelegate:(nonnull id<AAAPurchaseHandlerDelegate>) delegate;
@end
