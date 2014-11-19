//
//  AAACatalog.h
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 11/11/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface AAACatalog : NSObject

@property(nonatomic, strong) UIImage* cover;
@property(nonatomic, strong) NSArray* imagesURLs;

+(AAACatalog*) catalogWithCover:(UIImage*) coverImg andImageUrls:(NSArray*) imageUrls;
@end
