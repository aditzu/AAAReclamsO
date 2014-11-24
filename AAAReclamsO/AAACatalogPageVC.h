//
//  AAACatalogPageVC.h
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 17/11/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AAACatalogPageVC : UIViewController

@property(nonatomic, strong) NSString* imageUrl;
@property(nonatomic) int indexInPageViewCtrl;

-(void) downloadImage;
@end
