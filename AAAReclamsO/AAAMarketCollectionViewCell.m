//
//  AAAMarketCollectionViewCell.m
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 13/11/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import "AAAMarketCollectionViewCell.h"
#import "AAAMarket.h"
#import "AAACatalog.h"
#import "AAACatalogVC.h"
#import "AAAMarketTableViewCell.h"

@interface AAAMarketCollectionViewCell()

-(IBAction)scrollToLeftPressed:(UIButton*)sender;
-(IBAction)scrollToRightPressed:(UIButton*)sender;
@end

@implementation AAAMarketCollectionViewCell

-(void)setMarket:(AAAMarket *)market withViewControllers:(NSArray*) viewControllers
{
    self.market = market;
    catalogViewControllers = viewControllers;
    [marketRibon setImage:market.imgLogo];
    for (int i =0; i<viewControllers.count; i++)
    {
        UIViewController* catalogVC = viewControllers[i];
        CGSize scrollViewSize = self.catalogsScrollView.bounds.size;
        [self scaleDownCatalog:catalogVC atIndex:i];
        [self addCatalogVC:catalogVC atIndex:i];
        self.catalogsScrollView.contentSize = CGSizeMake( (i +1) * scrollViewSize.width, scrollViewSize.height);
    }
}

-(CGRect) catalogVCFrameAtIndex:(int) index
{
    CGSize scrollViewSize = self.catalogsScrollView.bounds.size;
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
    [self.catalogsScrollView addSubview:catalogVC.view];
    UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(catalogHasBeenClicked:)];
    [catalogVC.view addGestureRecognizer:tapGesture];
}

-(void)setDelegate:(id<AAAMarketCollectionCellEvents>)_delegate
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
    CGPoint pointToBe = self.catalogsScrollView.contentOffset;
    if (pointToBe.x - self.catalogsScrollView.bounds.size.width >= 0) {
        pointToBe.x -= self.catalogsScrollView.bounds.size.width;
        [UIView animateWithDuration:.3f animations:^{
            self.catalogsScrollView.contentOffset = pointToBe;
        }];
    }
}

-(void)scrollToRightPressed:(UIButton *)sender
{
    CGPoint pointToBe = self.catalogsScrollView.contentOffset;
    if (pointToBe.x + self.catalogsScrollView.bounds.size.width < self.catalogsScrollView.contentSize.width) {
        pointToBe.x += self.catalogsScrollView.bounds.size.width;
        [UIView animateWithDuration:.3f animations:^{
            self.catalogsScrollView.contentOffset = pointToBe;
        }];
    }
}

-(CGRect)visibleCatalogFrameInCell
{
    int page = self.catalogsScrollView.contentOffset.x / self.catalogsScrollView.bounds.size.width;
    return [self convertRect:[self catalogVCFrameAtIndex:page] fromView:self.catalogsScrollView];
}

@end
