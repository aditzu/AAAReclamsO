//
//  AAAFavorites.h
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 03/12/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AAAfavoriteItem.h"

@interface AAAFavoritesManager : NSObject
+(AAAFavoritesManager*) sharedInstance;

-(void) addFavoriteItem:(AAAFavoriteItem*) item;
-(void) removeFavoriteItem:(AAAFavoriteItem*) item;
-(void) removeFavoriteItemWithImageURL:(NSString*) imageUrl;
-(AAAFavoriteItem*) itemForImageURL:(NSString*) imageUrl;
@end
