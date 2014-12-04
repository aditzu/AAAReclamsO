//
//  AAAFavorites.m
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 03/12/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import "AAAFavoritesManager.h"

@interface AAAFavoritesManager()
{
    NSMutableSet* favoriteItems;
    BOOL _dirty;
}

@end

@implementation AAAFavoritesManager

static NSString* fileName = @"favs.dat";
static AAAFavoritesManager* _instance;

+(AAAFavoritesManager *)sharedInstance
{
    if (!_instance) {
        _instance = [[AAAFavoritesManager alloc] init];
    }
    return _instance;
}

-(instancetype)init
{
    if (self = [super init]) {
        NSArray* unarchivedFile = [NSArray arrayWithArray:[NSKeyedUnarchiver unarchiveObjectWithFile:[self filePath]]];
        favoriteItems = [NSMutableSet setWithArray:unarchivedFile];
        _dirty = NO;
    }
    return self;
}

-(void)addFavoriteItem:(AAAFavoriteItem *)item
{
    [favoriteItems addObject:item];
    _dirty = YES;
    [self saveToDisk];
}

-(void) removeFavoriteItem:(AAAFavoriteItem*) item
{
    if ([favoriteItems containsObject:item]) {
        [favoriteItems removeObject:item];
        _dirty = YES;
    }
    [self saveToDisk];
}

-(void)removeFavoriteItemWithImageURL:(NSString *)imageUrl
{
    [favoriteItems enumerateObjectsUsingBlock:^(AAAFavoriteItem* obj, BOOL *stop) {
        if ([obj.imageUrl isEqual:imageUrl]) {
            [favoriteItems removeObject:obj];
            return ;
        }
    }];
}

-(AAAFavoriteItem *)itemForImageURL:(NSString *)imageUrl
{
    __block AAAFavoriteItem* item = nil;
    [favoriteItems enumerateObjectsUsingBlock:^(AAAFavoriteItem* obj, BOOL *stop) {
        if ([obj.imageUrl isEqualToString:imageUrl]) {
            item = obj;
            return ;
        }
    }];
    return item;
}

-(void) saveToDisk
{
    if (_dirty)
    {
        NSArray* items = [favoriteItems allObjects];
        [NSKeyedArchiver archiveRootObject:items toFile:[self filePath]];
        _dirty = NO;
    }
}

-(NSString*) filePath
{
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return [basePath stringByAppendingPathComponent:fileName];
}

@end
