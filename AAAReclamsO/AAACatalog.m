//
//  AAACatalog.m
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 11/11/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import "AAACatalog.h"

@interface AAACatalog()
{
}

@end

@implementation AAACatalog

+(AAACatalog *)catalogWithCover:(UIImage *)coverImg andImageUrls:(NSArray *)imageUrls
{
    AAACatalog* catalog = [AAACatalog new];
    catalog.cover = coverImg;
    catalog.imagesURLs = imageUrls;
    return catalog;
}

@end
