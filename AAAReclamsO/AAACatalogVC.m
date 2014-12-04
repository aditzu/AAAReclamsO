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
#import "AAAwww.h"
#import <QuartzCore/QuartzCore.h>
#import "AAAFavoriteItem.h"
#import "AAAFavoritesManager.h"

@interface AAACatalogVC(){
    id<AAACatalogVCEvents> delegate;
    UIPageViewController* pageViewController;
    NSMutableArray* pages;
    BOOL isMinimized;
    
    BOOL pageIsAnimating;
    UITapGestureRecognizer* tapGesture;
    IBOutlet UIView* spinnerView;
    IBOutlet UIView* topBarView;
//    IBOutlet NSLayoutConstraint* closeBtnTopConstraint;
    
    IBOutlet UILabel* progressLabel;
    IBOutlet UIView* progressView;
    IBOutlet UIButton* closeBtn;
    IBOutlet UIButton* favoriteButton;
}

-(IBAction) closePressed:(id)sender;
-(IBAction) favoritePressed:(id)sender;

@end

@implementation AAACatalogVC

const static int PicturesToPreload = 3;

-(void)viewDidLoad
{
    [super viewDidLoad];
    [self updateSettingsFromCatalog:self.catalog];
    [self minimize];
    
    pageViewController = NO;
    
    tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
    tapGesture.delegate = self;
    [self.view addGestureRecognizer:tapGesture];
    tapGesture.enabled = NO;
    spinnerView.hidden = NO;
    
//    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0f) {
////        closeBtnTopConstraint.constant = 0.0f;
//    }
//    else
//    {
////        closeBtnTopConstraint.constant = 20.0f;
//    }
}

-(void) didTap:(UITapGestureRecognizer*) tapGestureRecognizer
{
    if (tapGesture.state == UIGestureRecognizerStateRecognized) {
        [self showTopBar:[NSNumber numberWithBool:YES]];
    }
}

-(void)setCatalog:(AAACatalog *)catalog
{
    _catalog = catalog;
    [self updateSettingsFromCatalog:catalog];
}

-(void) updateSettingsFromCatalog:(AAACatalog*) catalog
{
    if (!self.isViewLoaded || !catalog)
    {
        return;
    }
    
    pages = [NSMutableArray array];
    [[AAAwww instance] downloadPagesUrlsForCatalog:catalog.identifier withCompletionHandler:^(NSArray *_pages, NSError *error) {
        if (!error) {
            catalog.imagesURLs = _pages;
        }
        
        if (pageViewController) {
            pageViewController.delegate = nil;
            pageViewController.dataSource = nil;
            [pageViewController.view removeFromSuperview];
        }
        pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStylePageCurl navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
        pageViewController.view.frame = self.view.bounds;
        
        [self.view addSubview:pageViewController.view];
        [self.view bringSubviewToFront:topBarView];
        for (int i =0; i< catalog.imagesURLs.count; i++)
        {
            AAACatalogPageVC* catalogPage = [self.storyboard instantiateViewControllerWithIdentifier:@"catalogPageVC"];
            catalogPage.imageUrl = catalog.imagesURLs[i];
            catalogPage.indexInPageViewCtrl = i;
            if (i < PicturesToPreload) {
                [catalogPage downloadImage];
            }
            
            [pages addObject:catalogPage];
        }
        if (pages.count > 0) {
            __block UIView* v = spinnerView;
//            __block AAACatalogPageVC* pg = (AAACatalogPageVC*)pages[0];
            __block AAACatalogVC* selfVC = self;
            [pageViewController setViewControllers:@[pages[0]] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:^(BOOL finished) {
                v.hidden = YES;
                [selfVC updateFavoriteButton];
//                [pg.view layoutIfNeeded];
//                CGRect frame = [pg scrollViewFrame];
//                CGRect newFrame = [myView convertRect:frame fromView:pg.scrollView];
                
            }];
            pageViewController.delegate = self;
            pageViewController.dataSource = self;
            [self setProgress:1 outOf:pages.count];
        }
    }];
}

-(void) setProgress:(int) progress outOf:(int) total
{
    progressLabel.text = [NSString stringWithFormat:@"%i/%i",progress, total];
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

-(void) updateFavoriteButton
{
    AAACatalogPageVC* currentPage = [self currentPage];
    if (!currentPage) {
        return;
    }
    favoriteButton.selected = ([[AAAFavoritesManager sharedInstance] itemForImageURL:currentPage.imageUrl] != nil);
}

-(AAACatalogPageVC*) currentPage
{
    AAACatalogPageVC* currentPage;;
    if (pageViewController.viewControllers.count > 0) {
        currentPage = pageViewController.viewControllers[0];
    }
    return currentPage;
}

-(void)favoritePressed:(UIButton*)sender
{
    [sender setSelected:!sender.selected];
    AAACatalogPageVC* currentPage = [self currentPage];
    if (!currentPage) {
        return;
    }
    if (sender.selected) {
        AAAFavoriteItem* favoriteItem = [AAAFavoriteItem new];
        favoriteItem.imageUrl = currentPage.imageUrl;
        [[AAAFavoritesManager sharedInstance] addFavoriteItem:favoriteItem];
    }
    else
    {
        [[AAAFavoritesManager sharedInstance] removeFavoriteItemWithImageURL:currentPage.imageUrl];
    }
}

-(void)minimize
{
    isMinimized = YES;
    for (AAACatalogPageVC* page in pages) {
        [page show:NO];
    }
    tapGesture.enabled = NO;
    [self showTopBar:[NSNumber numberWithBool:NO]];
}

-(void)maximize
{
    isMinimized = NO;
    for (AAACatalogPageVC* page in pages) {
        [page show:YES];
    }
    tapGesture.enabled = YES;
    [closeBtn layoutIfNeeded];
}

-(void)finishedMaximized
{
    [self showTopBar:[NSNumber numberWithBool:YES]];
}

-(void) showTopBar:(NSNumber*) show
{
    BOOL showVal = [show boolValue];
    float delay = 3.0f;
    if (showVal == topBarView.hidden) {
        [self showView:topBarView show:showVal];
        if (showVal) {
            [self performSelector:@selector(showTopBar:) withObject:[NSNumber numberWithBool:NO]
                       afterDelay:delay];
        }
    }
    else if (showVal)
    {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showTopBar:) object:[NSNumber numberWithBool:NO]];
        [self performSelector:@selector(showTopBar:) withObject:[NSNumber numberWithBool:NO] afterDelay:delay];
    }
}

-(void)showCloseButton:(BOOL)show
{
    [self showView:closeBtn show:show];
}

-(void) showView:(UIView*) viewToShow show:(BOOL) show
{
    float alpha = show ? 1.0f : 0.0f;
    if (show) {
        viewToShow.alpha = 0.0f;
        viewToShow.hidden = NO;
    }
    [UIView animateWithDuration:.1f animations:^{
        viewToShow.alpha = alpha;
    } completion:^(BOOL finished) {
        if (finished) {
            viewToShow.hidden = !show;
        }
    }];
}

#pragma mark - UIPageViewCtrl

-(void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers
{
    pageIsAnimating = YES;
}

-(void)pageViewController:(UIPageViewController *)_pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    if (completed || finished) {
        pageIsAnimating = NO;
        int indexOfVC = [pages indexOfObject: _pageViewController.viewControllers[0]];
        [self setProgress:indexOfVC+1 outOf:pages.count];
        [self updateFavoriteButton];
        [self showTopBar:[NSNumber numberWithBool:YES]];
//        [self showProgressView:[NSNumber numberWithBool:YES]];
    }
}

-(UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    if (pageIsAnimating) {
        return nil;
    }
    long currentIndex = [pages indexOfObject:viewController];
    if (currentIndex == pages.count -1 || isMinimized) return nil;
    [pages[MIN(pages.count-1, currentIndex+1+PicturesToPreload)] downloadImage];
    return pages[currentIndex+1];
}

-(UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    if (pageIsAnimating) {
        return nil;
    }
    long currentIndex = [pages indexOfObject:viewController];
    if (currentIndex == 0 || isMinimized)return nil;
    return pages[currentIndex -1];
}

#pragma mark - UIGestureRecognizerDelegate

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if ([gestureRecognizer isEqual:tapGesture]) {
        
        if ([otherGestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] && ((UITapGestureRecognizer*)otherGestureRecognizer).numberOfTapsRequired == 2)
        {
            return YES;
        }
        return NO;
    }
    return NO;
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return NO;
}

@end
