//
//  FirstViewController.h
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 10/11/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AAAMarketTableViewCell.h"
#import "AAACatalogVC.h"

@interface AAAMarketsTableVC : UIViewController<UITableViewDataSource, UITableViewDelegate, AAAMarketTableViewCellEvents, AAACatalogVCEvents>//UITableViewController<AAAMarketTableViewCellEvents>//

@end

