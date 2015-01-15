//
//  AAAMarketCollectionViewCell.h
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 09/01/15.
//  Copyright (c) 2015 Adrian Ancuta. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AAAMarket.h"
@interface AAAMarketCollectionViewCell : UICollectionViewCell

typedef void(^onSelectedBlock)(AAAMarket* market);
typedef BOOL(^onActiveChangeBlock)(AAAMarketCollectionViewCell* cell);

@property(nonatomic) BOOL isActive;
@property(nonatomic, strong) AAAMarket* market;
-(void) setupEditModeOn:(BOOL)on;
-(void) onSelected:(onSelectedBlock) onSelectedBlock;
-(void) onActiveChanged:(onActiveChangeBlock) onActiveChangeBlock;
-(void) enableAddRemoveFeature:(BOOL) enable;
-(void) setUnseenCatalogs:(int) unseenCatalogs;
-(void) tryDecrementUnseenCatalogs: (int) newUnseenCatalogs;
@end
