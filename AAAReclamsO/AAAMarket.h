//
//  AAAMarket.h
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 11/11/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
//@protocol AAAMarketJS <JSExport>
//@property(nonatomic, copy) NSString* address;
//+(instancetype) marketWithTitle:(NSString*) title;
//@end

@interface AAAMarket : NSObject

@property(nonatomic, strong) NSString* name;
@property(nonatomic, strong) UIImage* imgLogo;
@property(nonatomic, strong) NSMutableArray* catalogs;

+(instancetype)marketWithName:(NSString *)title andLogoImage:(UIImage*) img;

@end
