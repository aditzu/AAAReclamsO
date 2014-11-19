//
//  AAAMarketCollectionVC.h
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 15/11/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AAAMarketCollectionViewCell.h"
#import "AAACatalogVC.h"

@interface AAAMarketCollectionVC : UIViewController<UICollectionViewDataSource, UICollectionViewDelegate, AAAMarketCollectionCellEvents, AAACatalogVCEvents>

@end
