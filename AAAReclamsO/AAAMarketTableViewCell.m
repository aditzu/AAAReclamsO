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
#import "AAACatalogVC.h"

@interface AAAMarketTableViewCell()
{
    
}

-(IBAction)scrollToLeftPressed:(UIButton*)sender;
-(IBAction)scrollToRightPressed:(UIButton*)sender;

@end


@implementation AAAMarketTableViewCell

-(void)setMarket:(AAAMarket *)market withViewControllers:(NSArray*) viewControllers
{
    self.market = market;
    catalogViewControllers = viewControllers;
    [marketLogoImg setImage:market.imgLogo];
    for (int i =0; i<viewControllers.count; i++)
    {
        UIViewController* catalogVC = viewControllers[i];
        CGSize scrollViewSize = catalogsScrollView.bounds.size;
        [self scaleDownCatalog:catalogVC atIndex:i];
        [self addCatalogVC:catalogVC atIndex:i];
        catalogsScrollView.contentSize = CGSizeMake( (i +1) * scrollViewSize.width, scrollViewSize.height);
    }
}

-(CGRect) catalogVCFrameAtIndex:(int) index
{
    CGSize scrollViewSize = catalogsScrollView.bounds.size;
    CGRect vcFrame  = CGRectMake(scrollViewSize.width *index + 5, 5, scrollViewSize.width - 10, scrollViewSize.height - 10);
    return vcFrame;
}

-(void) scaleDownCatalog:(UIViewController*) catalogVC atIndex:(int) index
{
    CGRect vcRect = [self catalogVCFrameAtIndex:index];
    CGRect catalogInitialFrame = catalogVC.view.frame;
    CGSize scale = CGSizeMake(vcRect.size.width / catalogInitialFrame.size.width, vcRect.size.height / catalogInitialFrame.size.height);
    catalogVC.view.transform = CGAffineTransformScale(CGAffineTransformIdentity, scale.width, scale.height);
}

-(void) addCatalogVC:(UIViewController*) catalogVC atIndex:(int) index
{
    CGRect vcRect = [self catalogVCFrameAtIndex:index];
    CGRect catalogInitialFrame = catalogVC.view.frame;
    catalogInitialFrame.origin.x = vcRect.origin.x;
    catalogInitialFrame.origin.y = vcRect.origin.y;
    catalogVC.view.frame = catalogInitialFrame;
    
    [catalogsScrollView addSubview:catalogVC.view];
    UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(catalogHasBeenClicked:)];
    [catalogVC.view addGestureRecognizer:tapGesture];
}

-(void)setDelegate:(id<AAAMarketTableViewCellEvents>)_delegate
{
    delegate = _delegate;
}

-(void) catalogHasBeenClicked:(UITapGestureRecognizer*) gesture
{
    if([delegate respondsToSelector:@selector(needToShowCatalogVC:forMarketCell:)])
    {
        _lastCatalogIndexShown = gesture.view.tag;
        AAACatalogVC* catalogVC = catalogViewControllers[gesture.view.tag];
        for (UITapGestureRecognizer* tapgesture in catalogVC.view.gestureRecognizers) {
            [catalogVC.view removeGestureRecognizer:tapgesture];
        }
        [delegate needToShowCatalogVC:catalogVC  forMarketCell:self];
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
