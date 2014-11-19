//
//  AAAMarketTableViewCell.h
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 11/11/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AAAMarket, AAACatalogVC, AAAMarketTableViewCell;

@protocol AAAMarketTableViewCellEvents <NSObject>

-(void) needToShowCatalogVC:(AAACatalogVC*) catalogVC forMarketCell:(AAAMarketTableViewCell*) marketCell;

@end

@interface AAAMarketTableViewCell : UITableViewCell
{
    IBOutlet UIImageView* marketLogoImg;
    IBOutlet UIScrollView* catalogsScrollView;
    id<AAAMarketTableViewCellEvents> delegate;
    NSArray* catalogViewControllers;
}

@property(nonatomic, strong) AAAMarket* market;
@property(nonatomic, readonly) int lastCatalogIndexShown;

-(void) setDelegate:(id<AAAMarketTableViewCellEvents>) delegate;
-(void)setMarket:(AAAMarket *)market withViewControllers:(NSArray*) viewControllers;

-(void) addCatalogVC:(UIViewController*) catalogVC atIndex:(int) index;
-(void) scaleDownCatalog:(UIViewController*) catalogVC atIndex:(int) index;
@end
