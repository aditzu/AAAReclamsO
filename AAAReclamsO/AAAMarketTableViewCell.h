//
//  AAAMarketTableViewCell.h
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 11/11/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AAAMarket;

@interface AAAMarketTableViewCell : UITableViewCell
{
    IBOutlet UIImageView* marketLogoImg;
    IBOutlet UIScrollView* catalogsScrollView;
}

-(void) setMarket:(AAAMarket*) market;

@end
