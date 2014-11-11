//
//  AAAMarketTableViewCell.m
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 11/11/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import "AAAMarketTableViewCell.h"
#import "AAAMarket.h"
#import "AAACatalog.h"
@interface AAAMarketTableViewCell()
{
    
}

-(IBAction)scrollToLeftPressed:(UIButton*)sender;
-(IBAction)scrollToRightPressed:(UIButton*)sender;

@end


@implementation AAAMarketTableViewCell

-(void)setMarket:(AAAMarket *)market
{
    [marketLogoImg setImage:market.imgLogo];
    for (int i =0; i<market.catalogs.count; i++)
    {
        AAACatalog* catalog = market.catalogs[i];
        CGSize scrollViewSize = catalogsScrollView.bounds.size;
        UIImageView* catalogCover = [[UIImageView alloc] initWithFrame:CGRectMake(scrollViewSize.width *i + 5, 5, scrollViewSize.width - 10, scrollViewSize.height - 10)];
        catalogsScrollView.contentSize = CGSizeMake( (i+ 1) * scrollViewSize.width, scrollViewSize.height);
        [catalogCover setImage:catalog.cover];
        [catalogsScrollView addSubview:catalogCover];
    }
}

-(void)scrollToLeftPressed:(UIButton *)sender
{
    CGPoint pointToBe = catalogsScrollView.contentOffset;
    if (pointToBe.x - catalogsScrollView.bounds.size.width >= 0) {
        pointToBe.x -= catalogsScrollView.bounds.size.width;
        [UIView animateWithDuration:.3f animations:^{
            catalogsScrollView.contentOffset = pointToBe;
        }];
    }
}

-(void)scrollToRightPressed:(UIButton *)sender
{
    CGPoint pointToBe = catalogsScrollView.contentOffset;
    if (pointToBe.x + catalogsScrollView.bounds.size.width < catalogsScrollView.contentSize.width) {
        pointToBe.x += catalogsScrollView.bounds.size.width;
        [UIView animateWithDuration:.3f animations:^{
            catalogsScrollView.contentOffset = pointToBe;
        }];
    }
}

@end
