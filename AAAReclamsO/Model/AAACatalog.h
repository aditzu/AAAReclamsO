//
//  AAACatalog.h
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 11/11/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AAAMarket.h"



@interface AAACatalog : NSObject

@property(nonatomic, strong) UIImage* cover;
@property(nonatomic, strong) NSArray* imagesURLs;
@property(nonatomic, getter=isActive) BOOL active;
@property(nonatomic, strong) NSString* bkDescription;
@property(nonatomic) double activeFrom;
@property(nonatomic) double activeTo;
@property(nonatomic, strong) NSString* name;
@property(nonatomic) int identifier;
@property(nonatomic, strong) NSString* pagesUrl;
@property(nonatomic, strong) AAAMarket* market;
@property(nonatomic) double priority;
@end
