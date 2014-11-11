//
//  AAACatalog.m
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 11/11/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import "AAACatalog.h"

@implementation AAACatalog

+(AAACatalog *)catalogWithCover:(UIImage *)coverImg
{
    AAACatalog* catalog = [AAACatalog new];
    catalog.cover = coverImg;
    return catalog;
}

@end
