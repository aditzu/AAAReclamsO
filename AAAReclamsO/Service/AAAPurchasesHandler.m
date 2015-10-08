//
//  AAAPurchasesHandler.m
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 06/10/15.
//  Copyright © 2015 Adrian Ancuta. All rights reserved.
//

#import "AAAPurchasesHandler.h"
#import <Parse/Parse.h>

@implementation AAAPurchasesHandler
{
    NSMutableArray* _delegates;
}

BOOL _adsEnabled;

static AAAPurchasesHandler* _instance;
NSString* const NO_ADS_PRODUCT_ID = @"com.alphaappers.ofertamea.noads";
NSString* const kNoAdsBought = @"noadsbought";

+(AAAPurchasesHandler *)instance
{
    if (!_instance) {
        _instance = [[AAAPurchasesHandler alloc] init];
    }
    return _instance;
}

-(instancetype)init
{
    if(self = [super init])
    {
        _delegates = [NSMutableArray array];
        
        [PFPurchase addObserverForProduct:NO_ADS_PRODUCT_ID block:^(SKPaymentTransaction * _Nonnull transaction) {
            if (transaction.transactionState == SKPaymentTransactionStatePurchased || transaction.transactionState == SKPaymentTransactionStateRestored) {
                NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
                [standardUserDefaults setBool:YES forKey:kNoAdsBought];
                [standardUserDefaults synchronize];
            }
            if (transaction.transactionState == SKPaymentTransactionStateRestored) {
                for (id<AAAPurchaseHandlerDelegate> del in _delegates) {
                    if ([del respondsToSelector:@selector(restoreFinishedForProductWithId:withError:)]) {
                        [del restoreFinishedForProductWithId:NO_ADS_PRODUCT_ID withError:transaction.error];
                    }
                }
            }
        }];
    }
    return  self;
}

+(BOOL)hasAdsEnabled
{
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    id item = [standardUserDefaults objectForKey:kNoAdsBought];
    if (item) {
        return ![item boolValue];
    }
    return YES;
}

-(void)purchaseNoads
{
    [self buyProduct:NO_ADS_PRODUCT_ID];
}

-(void)restorePurchases
{
    [PFPurchase restore];
}

-(void) buyProduct:(NSString*) product
{
    [PFPurchase buyProduct:product block:^(NSError * _Nullable error) {
        if (error) {
            for (id<AAAPurchaseHandlerDelegate> del in _delegates) {
                if ([del respondsToSelector:@selector(purchaseFailed:withError:)]) {
                    [del purchaseFailed:product withError:error];
                }
            }
        }
        else{
            NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
            [standardUserDefaults setBool:YES forKey:kNoAdsBought];
            [standardUserDefaults synchronize];
            for (id<AAAPurchaseHandlerDelegate> del in _delegates) {
                if ([del respondsToSelector:@selector(purchaseSuccesfully:)]) {
                    [del purchaseSuccesfully:product];
                }
            }
        }
    }];
}

-(void)addDelegate:(id<AAAPurchaseHandlerDelegate>)delegate
{
    if (![_delegates containsObject:delegate]) {
        [_delegates addObject:delegate];
    }
}

-(void)removeDelegate:(id<AAAPurchaseHandlerDelegate>)delegate
{
    if ([_delegates containsObject:delegate]) {
        [_delegates removeObject:delegate];
    }
}

@end