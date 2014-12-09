//
//  AAACatalogVC.m
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 12/11/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import "AAACatalogVC.h"
#import "AAACatalog.h"
#import "AAAwww.h"
#import <QuartzCore/QuartzCore.h>
#import "AAAFavoriteItem.h"
#import "AAAFavoritesManager.h"
#import <iAd/iAd.h>
#import "AAAGlobals.h"
#import "Flurry.h"

@interface AAACatalogVC(){
    id<AAACatalogVCEvents> delegate;
    UIPageViewController* pageViewController;
    NSMutableArray* pages;
    BOOL isMinimized;
    
    BOOL pageIsAnimating;
    UITapGestureRecognizer* tapGesture;
    IBOutlet UIView* spinnerView;
    IBOutlet UIView* topBarView;
    IBOutlet NSLayoutConstraint* topBarTopConstraint;
    
    IBOutlet UILabel* progressLabel;
    IBOutlet UIView* progressView;
    IBOutlet UIButton* closeBtn;
    
    IBOutlet UIView* bannerViewContainer;
    ADBannerView* bannerView;
    BOOL bannerIsShown;
}

-(IBAction) closePressed:(id)sender;

@end

@implementation AAACatalogVC

const static int PicturesToPreload = 3;

-(void)viewDidLoad
{
    [super viewDidLoad];
    [self updateSettingsFromCatalog:self.catalog];
    [self minimize];
    tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
    tapGesture.delegate = self;
    [self.view addGestureRecognizer:tapGesture];
    tapGesture.enabled = NO;
    spinnerView.hidden = NO;
    bannerViewContainer.hidden = YES;
    bannerIsShown = YES;
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
        [self close];
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
        if (error) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kWWWErrorOccured object:nil];
            return ;
        }
        
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
            [self addChildViewController:catalogPage];
        }
        if (pages.count > 0) {
            __block UIView* v = spinnerView;
            __block AAACatalogVC* selfVC = self;
//            __block UIView* pageView = pageViewController.view;
            [pageViewController setViewControllers:@[pages[0]] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:^(BOOL finished) {
                v.hidden = YES;
                AAACatalogPageVC* pg = [selfVC currentPage];
                pg.delegate = selfVC;
            }];
            pageViewController.delegate = self;
            pageViewController.dataSource = self;
            [self setProgress:1 outOf:(int)pages.count];
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

-(void) close
{
    if ([delegate respondsToSelector:@selector(closeCatalogVC:)]) {
        [delegate closeCatalogVC:self];
    }
    [self minimize];
}

-(void)closePressed:(id)sender
{
    [self close];
}

//-(void) updateFavoriteButton
//{
//    AAACatalogPageVC* currentPage = [self currentPage];
//    if (!currentPage) {
//        return;
//    }
//    favoriteButton.selected = ([[AAAFavoritesManager sharedInstance] itemForImageURL:currentPage.imageUrl] != nil);
//}

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
    [self layoutBanner:NO animated:NO];
    for (AAACatalogPageVC* page in pages) {
        [page show:NO];
    }
    tapGesture.enabled = NO;
    [self showTopBar:[NSNumber numberWithBool:NO]];
    pageViewController.view.frame= self.view.bounds;
    if (pageViewController && pageViewController.viewControllers && pageViewController.viewControllers.count > 0) {
        float percentageSeen = [pages indexOfObject:pageViewController.viewControllers[0]] * 100 / pages.count;
        [Flurry logEvent:FlurryEventCatalogPercentageSeen withParameters:@{FlurryParameterPercentage : [NSString stringWithFormat:@"%f", percentageSeen]}];
    }
}

-(void)maximize
{
    isMinimized = NO;
    for (AAACatalogPageVC* page in pages) {
        [page show:YES];
    }
    tapGesture.enabled = YES;
    [closeBtn layoutIfNeeded];
    bannerView = [[AAAGlobals sharedInstance] sharedBannerView];
    bannerView.delegate = self;
    bannerViewContainer.hidden = YES;
    [bannerViewContainer addSubview:bannerView];
    [self layoutBanner:NO animated:NO];
}

-(void)updatePageViewControllerForCurrentPage
{
    AAACatalogPageVC* currentPage=  [self currentPage];
    CGRect frame = [currentPage scrollViewFrame];
    pageViewController.view.frame = frame;
    topBarTopConstraint.constant = frame.origin.y > topBarView.frame.size.height ? frame.origin.y - topBarView.frame.size.height : frame.origin.y;
    bannerViewContainer.hidden = NO;
    [self layoutBanner:bannerView.bannerLoaded animated:bannerView.bannerLoaded];
}


-(void)finishedMaximized
{
    [self showTopBar:[NSNumber numberWithBool:YES]];
    [self updatePageViewControllerForCurrentPage];
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

- (void)layoutBanner:(BOOL) layout animated:(BOOL)animated
{
    if (bannerIsShown == layout) {
        return;
    }
    CGRect contentFrame = bannerViewContainer.bounds;
    CGRect bannerFrame = bannerView.frame;
    
    CGRect pageVCFrame = pageViewController.view.frame;
    if (bannerView.bannerLoaded && layout)
    {
        contentFrame.size.height -= bannerView.frame.size.height;
        bannerFrame.origin.y = contentFrame.size.height;
        if (pageVCFrame.size.height + pageVCFrame.origin.y > self.view.bounds.size.height - bannerView.frame.size.height) {
            pageVCFrame.origin.y = self.view.bounds.size.height - bannerView.frame.size.height - pageVCFrame.size.height + 4;
        }
        bannerIsShown = YES;
    } else {
        bannerFrame.origin.y = contentFrame.size.height;
        bannerIsShown = NO;
    }
    
    [UIView animateWithDuration:animated ? 0.25 : 0.0 animations:^{
        bannerView.frame = contentFrame;
        [bannerViewContainer layoutIfNeeded];
        bannerView.frame = bannerFrame;
        pageViewController.view.frame = pageVCFrame;
    }];
}

-(void) showPageViewController:(BOOL) show animated:(BOOL) animated
{
    CGRect currentFrame = pageViewController.view.frame;
    if (show) {
        if (currentFrame.origin.y < 0) {
            currentFrame.origin.y += self.view.bounds.size.height;
        }
    }
    else if (currentFrame.origin.y > 0)
    {
        currentFrame.origin.y -= self.view.bounds.size.height;
    }
    [UIView animateWithDuration:.25f delay: show ? 0.0f : 0.40f options:UIViewAnimationOptionCurveEaseIn animations:^{
        pageViewController.view.frame = currentFrame;
    } completion:nil];
}

#pragma mark - UIPageViewCtrl

-(void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers
{
    pageIsAnimating = YES;
}

-(void)pageViewController:(UIPageViewController *)_pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    if (completed || finished) {
//        [self updatePageViewControllerForCurrentPage];
        pageIsAnimating = NO;
        int indexOfVC = (int)[pages indexOfObject: _pageViewController.viewControllers[0]];
        [self setProgress:indexOfVC+1 outOf:(int)pages.count];
//        [self updateFavoriteButton];
        [self showTopBar:[NSNumber numberWithBool:YES]];
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
    AAACatalogPageVC* nextPagevc = pages[currentIndex+1];
    nextPagevc.delegate = self;
    return nextPagevc;
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

#pragma mark - AAACatalogPageDelegate

-(void)catalogPage:(AAACatalogPageVC *)catalogPage contentSizeDidChange:(CGSize)newSize
{
//    CGRect frame = pageViewController.view.frame;
//    
//    float width = MIN(newSize.width, self.view.window.bounds.size.width);
//    float height = MIN(newSize.height, self.view.window.bounds.size.height);
//    frame.size.width = width;
//    frame.size.height = height;
//    pageViewController.view.frame = frame;
//    pageViewController.view.center = self.view.center;
    [pageViewController.view layoutSubviews];
//    NSLog(@"pageVCSize: %@", NSStringFromCGRect(pageViewController.view.frame));
//    NSLog(@"ContentSize: %@", NSStringFromCGSize(newSize));
}

#pragma mark - ADBannerViewDelegate methods

-(void)bannerViewWillLoadAd:(ADBannerView *)banner
{
//    NSLog(@"bannerViewWillLoadAd");
}

-(void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    if (!isMinimized) {
        [self layoutBanner:YES animated:YES];
    }
    [Flurry logEvent:FlurryEventAdServed];
//    NSLog(@"bannerViewDidLoadAd");
}

-(BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
{
    [Flurry logEvent:FlurryEventAdOpened];
    if (!willLeave) {
        [self showTopBar:[NSNumber numberWithBool:NO]];
        [self showPageViewController:NO animated:YES];
    }
//    NSLog(@"bannerViewActionShouldBegin");
    return YES;
}

-(void)bannerViewActionDidFinish:(ADBannerView *)banner
{
    [self showPageViewController:YES animated:YES];
//    NSLog(@"bannerViewActionDidFinish");
}

-(void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    [self layoutBanner:NO animated:YES];
//    NSLog(@"didFailToReceiveAdWithError: %@", error);
}


@end
