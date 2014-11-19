//
//  AAAMarketCollectionViewCell.h
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 13/11/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import <UIKit/UIKit.h>
@class AAAMarket, AAACatalogVC, AAAMarketCollectionViewCell;

@protocol AAAMarketCollectionCellEvents <NSObject>

-(void) needToShowCatalogVC:(AAACatalogVC*) catalogVC forMarketCell:(AAAMarketCollectionViewCell*) marketCell;

@end

@interface AAAMarketCollectionViewCell : UICollectionViewCell{
    
    IBOutlet UIImageView* marketRibon;
    id<AAAMarketCollectionCellEvents> delegate;
    NSArray* catalogViewControllers;
}

@property(nonatomic, strong) AAAMarket* market;
@property(nonatomic, readonly) int lastCatalogIndexShown;
@property(nonatomic, strong) IBOutlet UIScrollView* catalogsScrollView;

-(CGRect) visibleCatalogFrameInCell;
-(void) setDelegate:(id<AAAMarketCollectionCellEvents>) delegate;
-(void)setMarket:(AAAMarket *)market withViewControllers:(NSArray*) viewControllers;

-(void) addCatalogVC:(UIViewController*) catalogVC atIndex:(int) index;
-(void) scaleDownCatalog:(UIViewController*) catalogVC atIndex:(int) index;

@end
