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

+(AAACatalog*) catalogWithCover:(UIImage*) coverImg;

@end
