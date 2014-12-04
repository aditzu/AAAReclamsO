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

-(void)setImagesURLs:(NSArray *)imagesURLs
{
    NSArray* sortedImages = [imagesURLs sortedArrayUsingComparator:^NSComparisonResult(NSString* obj1, NSString* obj2) {
        NSString* firstName = [[obj1 lastPathComponent] stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@".%@",[obj1 pathExtension]] withString:@""];
        NSString* secondName = [[obj2 lastPathComponent] stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@".%@", [obj2 pathExtension]] withString:@""];
        
        return [[NSNumber numberWithInt:[firstName intValue]] compare:[NSNumber numberWithInt:[secondName intValue]]];
    }];
    _imagesURLs = sortedImages;
}

-(BOOL)isEqual:(id)object
{
    return self.identifier == ((AAACatalog*)object).identifier;
}

-(NSUInteger)hash
{
    return self.identifier;
}

@end
