//
//  AAAFavoriteItem.m
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 03/12/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import "AAAFavoriteItem.h"

@implementation AAAFavoriteItem

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        self.imageUrl = [aDecoder decodeObjectForKey:@"imageURL"];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.imageUrl forKey:@"imageURL"];
}

-(BOOL)isEqual:(AAAFavoriteItem*)object
{
    return [self.imageUrl isEqual:object.imageUrl];
}

-(NSUInteger)hash
{
    return [self.imageUrl hash];
}

@end
