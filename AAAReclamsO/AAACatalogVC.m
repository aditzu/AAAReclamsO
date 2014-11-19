//
//  AAACatalogVC.m
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 12/11/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import "AAACatalogVC.h"
#import "AAACatalog.h"
#import "AAACatalogPageVC.h"

@interface AAACatalogVC(){
    id<AAACatalogVCEvents> delegate;
    UIPageViewController* pageViewController;
    NSMutableArray* pages;
    BOOL isMinimized;
}

-(IBAction) closePressed:(id)sender;

@end

@implementation AAACatalogVC

-(void)viewDidLoad
{
    [super viewDidLoad];
    [self updateSettingsFromCatalog:self.catalog];
    [self minimize];
}

-(void)setCatalog:(AAACatalog *)catalog
{
    _catalog = catalog;
    [self updateSettingsFromCatalog:catalog];
}

-(void) updateSettingsFromCatalog:(AAACatalog*) catalog
{
    if (!self.isViewLoaded)
    {
        return;
    }
    if (pageViewController) {
        pageViewController.delegate = nil;
        pageViewController.dataSource = nil;
        [pageViewController.view removeFromSuperview];
    }
    pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStylePageCurl navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    pageViewController.view.frame = self.view.bounds;
    [self.view addSubview:pageViewController.view];
    [self.view bringSubviewToFront:closeBtn];
    pages = [NSMutableArray array];
    for (int i =0; i< catalog.imagesURLs.count; i++)
    {
        AAACatalogPageVC* catalogPage = [self.storyboard instantiateViewControllerWithIdentifier:@"catalogPageVC"];
        catalogPage.imageUrl = catalog.imagesURLs[i];
        catalogPage.indexInPageViewCtrl = i;
        [pages addObject:catalogPage];
    }
    [pageViewController setViewControllers:@[pages[0]] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:^(BOOL finished) {
       
    }];
    pageViewController.delegate = self;
    pageViewController.dataSource = self;
}

-(void) setDelegate:(id<AAACatalogVCEvents>) _delegate
{
    delegate = _delegate;
}

-(void)closePressed:(id)sender
{
    if ([delegate respondsToSelector:@selector(closeCatalogVC:)]) {
        [delegate closeCatalogVC:self];
    }
    [self minimize];
}

-(void)minimize
{
    isMinimized = YES;
    closeBtn.hidden=isMinimized;
}

-(void)maximize
{
    isMinimized = NO;
    closeBtn.hidden=isMinimized;
}

#pragma UIPageViewCtrl

-(UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    long currentIndex = [pages indexOfObject:viewController];
    if (currentIndex == pages.count -1 || isMinimized) return nil;
    return pages[currentIndex+1];
}

-(UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    long currentIndex = [pages indexOfObject:viewController];
    if (currentIndex == 0 || isMinimized)return nil;
    return pages[currentIndex -1];
}

@end