//
//  AAACatalogVC.h
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 12/11/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AAACatalog.h"

@class AAACatalogVC;

@protocol AAACatalogVCEvents <NSObject>

-(void) closeCatalogVC:(AAACatalogVC*) catalogVCs;

@end

@interface AAACatalogVC : UIViewController <UIPageViewControllerDataSource, UIPageViewControllerDelegate>{
    IBOutlet UIButton* closeBtn;
}

@property(nonatomic, strong) AAACatalog* catalog;

-(void) setDelegate:(id<AAACatalogVCEvents>) _delegate;
-(void) setCatalog:(AAACatalog*) catalog;
-(void) minimize;
-(void) maximize;
@end