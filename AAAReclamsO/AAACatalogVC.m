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
#import "AAAGlobals.h"
#import "Flurry.h"
#import "AAATutorialManager.h"

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
    
//    IBOutlet UIView* bannerViewContainer;
//    ADBannerView* bannerView;
    BOOL bannerIsShown;
    AAASharedBanner *sharedBannerView;
    __weak IBOutlet UIView *gadBannerViewContainer;
    BOOL adBannerLoaded;
    __weak IBOutlet UIImageView *progressViewBgImage;
    
    UIView* discoverCatalogTutorial;
    UIView* zoomCatalogTutorial;
    UIView* closeCatalogTutorial;
    __weak IBOutlet UILabel *newViewLabel;
    __weak IBOutlet UIView *fromToBottomBar;
    __weak IBOutlet UILabel *fromToLabel;
    __weak IBOutlet NSLayoutConstraint *fromToDistanceToBottomConstraint;
    __weak IBOutlet UIView *newView;
    __weak IBOutlet UIImageView *newViewImage;
}

@property(nonatomic) BOOL catalogIsSeen;

-(IBAction) closePressed:(id)sender;

@end

@implementation AAACatalogVC

const static int PicturesToPreload = 3;

-(void)viewDidLoad
{
    [super viewDidLoad];
    [self updateSettingsFromCatalog:self.catalog seen:self.catalogIsSeen];
    [self minimize];
    tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
    tapGesture.delegate = self;
    [self.view addGestureRecognizer:tapGesture];
    tapGesture.enabled = NO;
    spinnerView.hidden = NO;
    bannerIsShown = YES;
    
    progressViewBgImage.layer.cornerRadius = 5.0f;
    
    discoverCatalogTutorial = [[AAATutorialManager instance] addTutorialView:TutorialViewExploreCatalog
                                                             withDependecies:@[]
                                                                    atCenter:self.view.center];
    zoomCatalogTutorial = [[AAATutorialManager instance] addTutorialView:TutorialViewZoomOnCatalog
                                                         withDependecies:@[@(TutorialViewExploreCatalog)]
                                                                atCenter:self.view.center];
    
//    self.view.layer.shadowColor = [UIColor blackColor].CGColor;
//    self.view.layer.shadowOffset = CGSizeMake(2, 2);
//    self.view.layer.shadowRadius = 3;
//    self.view.layer.shadowPath = CGPathCreateWithRect(self.view.bounds, nil);
//    self.view.layer.shadowOpacity = .3f;
//    self.view.layer.masksToBounds = YES;
}

-(void)dealloc
{
    for (AAACatalogPageVC* page in pages) {
        page.onScrollViewHeightConstraintChange = nil;
    }
}

-(void) didTap:(UITapGestureRecognizer*) tapGestureRecognizer
{
    if (tapGesture.state == UIGestureRecognizerStateRecognized) {
//        [self close];
        [self showTopBar:[NSNumber numberWithBool:YES]];
    }
}

-(void)setCatalog:(AAACatalog *)catalog seen:(BOOL) seen
{
    _catalog = catalog;
    self.catalogIsSeen = seen;
    [self updateSettingsFromCatalog:catalog seen:seen];
}

//-(CGRect) pageControllerFullFrame
//{
//    CGRect myBounds = self.view.bounds;
//    if (isMinimized)
//    {
//        myBounds.size.height = fromToBottomBar.frame.origin.y;
//    }
//    else if(adBannerLoaded)
//    {
//        myBounds.size.height = gadBannerViewContainer.frame.origin.y;
//    }
//    return myBounds;
//}

-(CGRect) pageViewControllerFrameForPage:(AAACatalogPageVC*) page
{
    CGRect pageVCFrame = self.view.bounds;
    if (isMinimized)
    {
        pageVCFrame.size.height -= fromToBottomBar.frame.size.height;
    }
//    else if(adBannerLoaded)
//    {
//        pageVCFrame.size.height -= gadBannerViewContainer.frame.size.height;
//    }
    pageVCFrame = [page croppedPageCalculatedFrameInParentFrame:pageVCFrame];
    if (!isMinimized && adBannerLoaded && pageVCFrame.size.height > self.view.bounds.size.height - gadBannerViewContainer.frame.size.height)
    {
        pageVCFrame.size.height -= gadBannerViewContainer.frame.size.height;
        pageVCFrame = [page croppedPageCalculatedFrameInParentFrame:pageVCFrame];
    }
    return pageVCFrame;
}

-(CGRect) pageViewControllerFrame
{
    AAACatalogPageVC* currentPage = [self currentPage];
    if (currentPage)
    {
        return [self pageViewControllerFrameForPage:currentPage];
    }
    return self.view.bounds;
}

-(void) setBottomBarYPosition
{
    AAACatalogPageVC* currentPage = [self currentPage];
    if (currentPage) {
        if(currentPage.isPageLoaded)
        {
//            CGRect scrollViewFrame = [currentPage croppedPageCalculatedFrame];
            CGRect pageVCFrame = pageViewController.view.frame;
            CGRect myBounds = self.view.frame;
            float constant = myBounds.size.height - (pageVCFrame.origin.y + pageVCFrame.size.height) - fromToBottomBar.frame.size.height;
            fromToDistanceToBottomConstraint.constant = constant;
            return;
        }
    }
    fromToDistanceToBottomConstraint.constant = fromToBottomBar.frame.size.height;
}

- (void)setNewViewEffect
{
    if (!self.catalogIsSeen) {        
        CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        rotationAnimation.toValue = @(M_PI * 2.0);
        rotationAnimation.duration = 5;
        rotationAnimation.autoreverses = NO;
        rotationAnimation.repeatCount = HUGE_VALF;
        [newViewImage.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
    }
}

- (void)setFromToDatesForCatalog:(AAACatalog *)catalog
{
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd-MM-yyyy"];
    NSDate* from = [NSDate dateWithTimeIntervalSince1970:catalog.activeFrom/1000.0f];
    NSDate* to = [NSDate dateWithTimeIntervalSince1970:catalog.activeTo/1000.0f];
    
    NSString* labelText = fromToLabel.text;
    if ([labelText rangeOfString:@"X"].length == 0) {
        NSLog(@"ERROR. Make sure that the \"fromToLabel\" contains an X string in Interface Builder!");
    }
    NSRange rangeOfX = [labelText rangeOfString:@"X"];
    NSDictionary* normalTextAttributes = [fromToLabel.attributedText attributesAtIndex:0 effectiveRange:NULL];
    NSDictionary* dateTextAttributes = [fromToLabel.attributedText attributesAtIndex:rangeOfX.location effectiveRange:NULL];
    
    NSMutableAttributedString* allString = [[NSMutableAttributedString alloc] init];
    [allString appendAttributedString:[[NSAttributedString alloc] initWithString:@"De la " attributes:normalTextAttributes]];
    [allString appendAttributedString:[[NSAttributedString alloc] initWithString:[dateFormatter stringFromDate:from] attributes:dateTextAttributes]];
    [allString appendAttributedString:[[NSAttributedString alloc] initWithString:@" până la " attributes:normalTextAttributes]];
    [allString appendAttributedString:[[NSAttributedString alloc] initWithString:[dateFormatter stringFromDate:to] attributes:dateTextAttributes]];
    
    fromToLabel.attributedText = allString;
}

-(void) updateSettingsFromCatalog:(AAACatalog*) catalog seen:(BOOL) seen
{
    if (!self.isViewLoaded || !catalog)
    {
        return;
    }
    [self setFromToDatesForCatalog:catalog];
    
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
        pageViewController.delegate = self;
        pageViewController.dataSource = self;
        pageViewController.view.frame = [self pageViewControllerFrame];
        [self.view addSubview:pageViewController.view];
        [self.view bringSubviewToFront:topBarView];
        [self.view bringSubviewToFront:fromToBottomBar];
        [self.view bringSubviewToFront:newView];
        pageViewController.view.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.1f];
        for (int i =0; i< catalog.imagesURLs.count; i++)
        {
            AAACatalogPageVC* catalogPage = [self.storyboard instantiateViewControllerWithIdentifier:@"catalogPageVC"];
            if (i == 0) {
                catalogPage.onScrollViewHeightConstraintChange = ^(AAACatalogPageVC* page)
                {
                    if (page.isPageLoaded) {
                        pageViewController.view.frame = [self pageViewControllerFrame];
                        [self setBottomBarYPosition];
                        page.onScrollViewHeightConstraintChange = nil;
                    }
                };
                catalogPage.delegate = self;
            }
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
            [pageViewController setViewControllers:@[pages[0]] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:^(BOOL finished) {
                if (finished) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        v.hidden = YES;
                    });
                }
            }];
            [self setProgress:1 outOf:(int)pages.count];
        }
    }];
    
    [UIView animateWithDuration:.3f animations:^{
        newView.alpha = self.catalogIsSeen ? 0.0f : 1.0f;
    }];
    
    [self setNewViewEffect];
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
    [discoverCatalogTutorial removeFromSuperview];
    [closeCatalogTutorial removeFromSuperview];
    [zoomCatalogTutorial removeFromSuperview];
    if ([delegate respondsToSelector:@selector(closeCatalogVC:)]) {
        [delegate closeCatalogVC:self];
    }
    [self minimize];
}

-(void)closePressed:(id)sender
{
//    [[AAATutorialManager instance] invalidateTutorialView:TutorialViewCloseCatalog];
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
    AAACatalogPageVC* currentPage;
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
    [sharedBannerView stop];
    [sharedBannerView.bannerView removeFromSuperview];
    [self layoutBanner:NO animated:NO];
    for (AAACatalogPageVC* page in pages) {
        [page show:NO];
    }
    tapGesture.enabled = NO;
    [self showTopBar:[NSNumber numberWithBool:NO]];
    if (pageViewController) {
//        [UIView animateWithDuration:.1f animations:^{
            pageViewController.view.frame= [self pageViewControllerFrame];
//        }];
//        [self setBottomBarYPosition];
    }
    
    [self showView:fromToBottomBar show:YES];
    if (pageViewController && pageViewController.viewControllers && pageViewController.viewControllers.count > 0) {
        float percentageSeen = [pages indexOfObject:pageViewController.viewControllers[0]] * 100 / pages.count;
        [Flurry logEvent:FlurryEventCatalogPercentageSeen withParameters:@{FlurryParameterPercentage : [NSString stringWithFormat:@"%f", percentageSeen]}];
    }
}

-(void) finishedMinimized
{
    [self setBottomBarYPosition];
}

-(void)maximize
{
    isMinimized = NO;
    [UIView animateWithDuration:.3f animations:^{
        newView.alpha = 0.0f;
    }];
    for (AAACatalogPageVC* page in pages) {
        [page show:YES];
    }
    tapGesture.enabled = YES;
    [closeBtn layoutIfNeeded];
    [self showView:fromToBottomBar show:NO];
}

-(void)finishedMaximized
{
    sharedBannerView = [[AAAGlobals sharedInstance] sharedBannerViewWithRootViewController:self];
    sharedBannerView.delegate = self;
    [gadBannerViewContainer addSubview:sharedBannerView.bannerView];
    sharedBannerView.bannerView.hidden = NO;
    [sharedBannerView start];
    [self updatePageViewControllerForCurrentPage];
    [self layoutBanner:adBannerLoaded animated:adBannerLoaded];
    [self updateTopBarPosition];
    [self showTopBar:[NSNumber numberWithBool:YES]];
    
    [self.view addSubview:discoverCatalogTutorial];
    [self.view addSubview:zoomCatalogTutorial];
    [self.view bringSubviewToFront:topBarView];
    
    [[AAATutorialManager instance] showTutorialView:TutorialViewExploreCatalog];
    [[AAATutorialManager instance] showTutorialView:TutorialViewZoomOnCatalog];
}

-(void) updateTopBarPosition
{
    topBarTopConstraint.constant = 20.0f;
    
//    AAACatalogPageVC* currentPage=  [self currentPage];
//    if (!currentPage) {
//        return;
//    }
//    CGRect frame = pageViewController.view.frame;
//    float constant = frame.origin.y > topBarView.frame.size.height + 20 ? frame.origin.y - topBarView.frame.size.height : frame.origin.y;
//    if (constant < 20) {
//        constant = 20;
//        
//    }
//    [UIView animateWithDuration:.2f animations:^{
//        topBarTopConstraint.constant = constant;
//    }];
}


-(void)updatePageViewControllerForCurrentPage
{
    AAACatalogPageVC* currentPage=  [self currentPage];
    if (currentPage.isPageLoaded)
    {
        pageViewController.view.frame = [self pageViewControllerFrameForPage:currentPage];
    }
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
    CGRect contentFrame = gadBannerViewContainer.bounds;
    CGRect bannerFrame = sharedBannerView.bannerView.frame;
    
    CGRect pageVCFrame = pageViewController.view.frame;
    if (adBannerLoaded && layout)
    {
        contentFrame.size.height -= sharedBannerView.bannerView.frame.size.height;
        bannerFrame.origin.y = contentFrame.size.height;
        if (pageVCFrame.size.height + pageVCFrame.origin.y > self.view.bounds.size.height - sharedBannerView.bannerView.frame.size.height) {
            float pageVCFrameY = self.view.bounds.size.height - sharedBannerView.bannerView.frame.size.height - pageVCFrame.size.height + 4;
            if (pageVCFrameY < 0) {
                pageVCFrame.size.height += pageVCFrameY;
                pageVCFrameY = 0;
            }
            pageVCFrame.origin.y = pageVCFrameY;
        }
        bannerIsShown = YES;
    } else {
        bannerFrame.origin.y = contentFrame.size.height;
        bannerIsShown = NO;
    }
    
    [UIView animateWithDuration:animated ? 0.25 : 0.0 animations:^{
        [gadBannerViewContainer layoutIfNeeded];
        sharedBannerView.bannerView.frame = bannerFrame;
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
        pageIsAnimating = NO;
        int indexOfVC = (int)[pages indexOfObject: _pageViewController.viewControllers[0]];
        [self setProgress:indexOfVC+1 outOf:(int)pages.count];
        //        [self updateFavoriteButton];
        AAACatalogPageVC* page = [self currentPage];
        if (page.isPageLoaded) {
            _pageViewController.view.frame = [self pageViewControllerFrame];
            [self updateTopBarPosition];
        }
        [self showTopBar:[NSNumber numberWithBool:YES]];
        [[AAATutorialManager instance] invalidateTutorialView:TutorialViewExploreCatalog];
        [[AAATutorialManager instance] showTutorialView:TutorialViewZoomOnCatalog];
    }
}

-(UIViewController *)pageViewController:(UIPageViewController *)_pageViewController viewControllerAfterViewController:(UIViewController *)viewController
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

-(void)catalogPage:(AAACatalogPageVC *)catalogPage pageLoaded:(BOOL)pageLoaded
{
//    [UIView animateWithDuration:.3f animations:^{
        pageViewController.view.frame = [self pageViewControllerFrame];
//    }];
}

-(void)catalogPage:(AAACatalogPageVC *)catalogPage contentSizeDidChange:(CGSize)newSize
{
    [[AAATutorialManager instance] invalidateTutorialView:TutorialViewZoomOnCatalog];
//    [[AAATutorialManager instance] showTutorialView:TutorialViewCloseCatalog];
    
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

#pragma mark - AAASharedBannerDelegate

-(void)adRequestFailedWithError:(NSError *)error
{
    adBannerLoaded = NO;
    [self layoutBanner:NO animated:YES];
    [Flurry logError:FlurryEventAdFailedToLoad message:@"Ad Request Failed" error:error];
}

-(void)adRequestSuccesful
{
    adBannerLoaded = YES;
    if (!isMinimized) {
        [self layoutBanner:YES animated:YES];
        [self updateTopBarPosition];
    }
    [Flurry logEvent:FlurryEventAdServed];
}

-(void)adModalDidDismiss:(NSString *)adType apId:(NSString *)apId
{
    [self showPageViewController:YES animated:YES];
}

-(void)adModalWillAppear:(NSString *)adType apId:(NSString *)apId
{
    [self showTopBar:[NSNumber numberWithBool:NO]];
    [self showPageViewController:NO animated:YES];
    [Flurry logEvent:FlurryEventAdOpened];
}

-(void)applicationWillTerminateFromAd
{
    [self showTopBar:[NSNumber numberWithBool:NO]];
    [self showPageViewController:NO animated:YES];
    [Flurry logEvent:FlurryEventAdOpened];
}

-(void)adWasTapped:(NSString *)adType apId:(NSString *)apId
{
    [Flurry logEvent:FlurryEventAdOpened];
}

@end
