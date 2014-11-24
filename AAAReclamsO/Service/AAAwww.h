//
//  AAAJsObjCWrapper.h
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 19/11/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^DownloadMarketsBlock)(NSArray* markets, NSError* error);
typedef void(^DownloadCatalogsBlock)(NSArray* catalogs, NSError* error);
typedef void(^DownloadPagesForCatalogBlock) (NSArray* pages, NSError* error);

@interface AAAwww : NSObject
{
}

+(AAAwww*) instance;
-(void) downloadMarketsWithCompletionHandler:(DownloadMarketsBlock) completionHandler;
-(void) downloadCatalogInformationsWithCompletionHandler:(DownloadCatalogsBlock) completionHandler;
-(void) downloadPagesUrlsForCatalog:(int) catalogId withCompletionHandler:(DownloadPagesForCatalogBlock) completionHandler;
-(void) downloadPagesUrlsForCatalogs:(NSArray*) catalogs;
@end
