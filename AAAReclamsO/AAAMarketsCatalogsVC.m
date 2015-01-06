//
//  AAAMarketsCatalogsVC.m
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 15/11/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import "AAAMarketsCatalogsVC.h"
#import "AAACatalog.h"
#import "AAAMarket.h"
#import "AAAwww.h"
#import "JMImageCache.h"
#import "Reachability.h"
#import <QuartzCore/QuartzCore.h>
#import "AAAGlobals.h"
#import "Flurry.h"
#import "AAATutorialManager.h"
//#import "AAATutorialViewController.h"

@interface AAAMarketsCatalogsVC()
{
    NSMutableArray* markets;
    IBOutlet UIScrollView* marketsScrollView;
    
    AAAMarket* currentShowingMarket;
    NSMutableArray* currentShowingCatalogs;
    UIView* containerViewOfShownCatalog;
    
    AAAwww* www;
    UIView* currentShownMarketView;
    NSMutableArray* marketViews;
    
    CGRect catalogViewMaxFrame;
    
    IBOutlet iCarousel* carousel;
    UIImageView* bg;
    
    //Error view
    IBOutlet UIView* errorView;
    IBOutlet UIActivityIndicatorView* errorViewSpinner;
    IBOutlet UILabel* errorViewMessageLabel;
    IBOutlet UIButton* errorViewRetryButton;
    
    NSMutableDictionary* catalogsVCs;
    BOOL isDownloadingCatalogs;
    
    IBOutlet UIView* loadingView;
    
    ScrollDirection marketsScrollViewDirection;
    CGPoint marketsScrollViewLastContentOffset;
    
    NSDate* lastTimeRefreshButtonWasPressed;
    __weak IBOutlet UIView *topBar;
}
- (IBAction)privacyButtonPressed:(UIButton *)sender;
- (IBAction)refreshButtonPressed:(UIButton *)sender;

-(IBAction) errorViewRetryPressed:(UIButton*)sender;
@end

@implementation AAAMarketsCatalogsVC
const static int MIN_SECONDS_TO_RELOAD_DATA = 10;

static Reachability* internetReach;
static Reachability* ownServerReach;

const static float DisabledMarketViewTransparency = 0.65f;

-(void)viewDidLoad
{
    [super viewDidLoad];
    marketViews = [NSMutableArray array];
    catalogsVCs = [NSMutableDictionary dictionary];
    www = [AAAwww instance];
    [JMImageCache sharedCache].countLimit = 200;
    carousel.type = iCarouselTypeRotary;
    carousel.scrollSpeed = .4f;
    carousel.decelerationRate = 0.5f;
    carousel.perspective = -0.7/500;
    
    loadingView.hidden = YES;
    
    marketsScrollView.delegate = self;
    
    errorView.layer.cornerRadius = 5.0f;
    errorViewRetryButton.layer.cornerRadius = 5.0f;
    [JMImageCache sharedCache].numberOfRetries = 2;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wwwErrorOccured) name:kWWWErrorOccured object:nil];
    [self checkForInternetConnectionOnSuccess:^{
        if (!isDownloadingCatalogs) {
            [self resetCatalogs];
            [self downloadCatalogs];
        }
    } onFailure:^{
        [self resetCatalogs];
    }];

    [[AAATutorialManager instance] setupWithStoryboard:self.storyboard];
    UIView* dragMarketsTutorial = [[AAATutorialManager instance] addTutorialView:TutorialViewDiscoverMarkets withDependecies:@[] atCenter:marketsScrollView.center];
    [self.view addSubview:dragMarketsTutorial];
    UIView* tapMarketTutorial = [[AAATutorialManager instance] addTutorialView:TutorialViewTapOnMarket withDependecies:@[@(TutorialViewDiscoverMarkets)] atCenter:marketsScrollView.center];
    [self.view addSubview:tapMarketTutorial];
    UIView* dragCatalogsTutorial = [[AAATutorialManager instance] addTutorialView:TutorialViewDiscoverCatalogs withDependecies:@[@(TutorialViewDiscoverMarkets), @(TutorialViewTapOnMarket)] atCenter:carousel.center];
    [self.view addSubview:dragCatalogsTutorial];
    UIView* tapCatalogTutorial = [[AAATutorialManager instance] addTutorialView:TutorialViewTapOnCatalog withDependecies:@[@(TutorialViewDiscoverMarkets), @(TutorialViewTapOnMarket)] atCenter:carousel.center];
    [self.view addSubview:tapCatalogTutorial];

    [[AAATutorialManager instance] showTutorialView:TutorialViewDiscoverMarkets];
    [[AAATutorialManager instance] showTutorialView:TutorialViewTapOnMarket];
    [[AAATutorialManager instance] showTutorialView:TutorialViewDiscoverCatalogs];
    [[AAATutorialManager instance] showTutorialView:TutorialViewTapOnCatalog];
    
//    [AAATutorialViewController initWithStoryboard:self.storyboard andSuperView:self.view];
//
//    [self.view addSubview:[AAATutorialViewController instance].view];
//    [[AAATutorialController instance] setSuperview:self.view];
//    [[AAATutorialController instance] show:YES];
////
//    [[AAATutorialController instance] showArrow];
}

-(void) resetCatalogs
{
    dispatch_async(dispatch_get_main_queue(), ^{
        markets = [NSMutableArray array];
        for (NSString* key in [catalogsVCs allKeys]) {
            NSArray* catalogVcsForMarket = catalogsVCs[key];
            for (AAACatalogVC* catalogVC in catalogVcsForMarket) {
                [catalogVC.view removeFromSuperview];
            }
        }
        catalogsVCs = [NSMutableDictionary dictionary];
        for (UIView* marketView in marketViews) {
            [marketView removeFromSuperview];
        }
        marketViews = [NSMutableArray array];
    });
}

-(void) wwwErrorOccured
{
    [self resetCatalogs];
    errorView.hidden = NO;
    errorViewMessageLabel.text = @"Momentan lucrăm pentru a îmbunătăți experiența dumneavoastră în aplicație.\nVă rugăm să reveniți mai târziu!";
    errorViewRetryButton.hidden =  NO;
    errorViewMessageLabel.hidden = NO;
    [errorViewSpinner stopAnimating];
}

- (void)downloadCatalogs
{
    errorView.hidden = NO;
    [errorViewSpinner startAnimating];
    errorViewRetryButton.hidden = YES;
    errorViewMessageLabel.hidden = YES;
    isDownloadingCatalogs = YES;
    loadingView.hidden = NO;
    [www downloadCatalogInformationsWithCompletionHandler:^(NSArray *catalogs, NSError *error) {
        if (error) {
            [self wwwErrorOccured];
            isDownloadingCatalogs = NO;
            loadingView.hidden = YES;
            return;
        }
        errorView.hidden = YES;
        for (AAACatalog* catalog in catalogs)
        {
            if (!catalog.isActive) {
                break;
            }
            if (![markets containsObject:catalog.market]) {
                [markets addObject:catalog.market];
            }
            [markets enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                AAAMarket* mark = (AAAMarket*)obj;
                if (mark.identifier == catalog.market.identifier) {
                    [mark.catalogs addObject:catalog];//auuuu retain circle
                }
            }];
        }
        markets  = [NSMutableArray arrayWithArray:[markets sortedArrayUsingComparator:^NSComparisonResult(AAAMarket* obj1, AAAMarket* obj2) {
            return [[NSNumber numberWithDouble:obj1.priority] compare:[NSNumber numberWithDouble:obj2.priority]];
        }]];
        [self addTheMarkets];
        if (markets.count>0) {
            currentShowingMarket = markets[0];
            [self setTheCatalogsForMarket:currentShowingMarket];
            [self setMarketViewAsSelected:marketViews[0]];
        }
        loadingView.hidden = YES;
        isDownloadingCatalogs = NO;
//        [[AAATutorialViewController instance] show:YES tutorialView:iTutorialViewTypeMarketsBar];
//        [[AAATutorialViewController instance] animateStepNumber:iTutorialViewStepNumberFirst inTutorialView:iTutorialViewTypeMarketsBar];
    }];
}


-(void) checkForInternetConnectionOnSuccess:(void(^)(void)) success onFailure:(void(^)(void)) failure
{
    if (internetReach) {
        [internetReach stopNotifier];
        internetReach = nil;
    }
    if (ownServerReach) {
        [ownServerReach stopNotifier];
        ownServerReach = nil;
    }
    
    errorView.hidden = NO;
    void(^errorViewLoadingBlock)(BOOL loading) = ^(BOOL loading)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            errorViewRetryButton.hidden = loading;
            errorViewMessageLabel.hidden = loading;
            if (loading) {
                [errorViewSpinner startAnimating];
            }
            else
            {
                [errorViewSpinner stopAnimating];
            }
            [self.view layoutSubviews];
        });
    };
    
    errorViewLoadingBlock(YES);
    internetReach = [Reachability reachabilityWithHostName:@"www.google.com"];
    internetReach.unreachableBlock = ^(Reachability* reach)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            errorViewMessageLabel.text = @"Aplicația necesită o conexiune stabilă la internet.\nVă rugăm să reîncercați după ce ați facut setările necesare!";
            errorView.hidden = NO;
            errorViewLoadingBlock(NO);
        });
        failure();
    };
    
    internetReach.reachableBlock = ^(Reachability* reach)
    {
        ownServerReach = [Reachability reachabilityWithHostName:[www host]];
        ownServerReach.unreachableBlock = ^(Reachability* reachability)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                errorViewMessageLabel.text = @"Momentan lucrăm pentru a îmbunătăți experiența dumneavoastră în aplicație.\nVă rugăm să reveniți mai târziu!";
                errorView.hidden = NO;
                errorViewLoadingBlock(NO);
            });
            [reachability stopNotifier];
            failure();
        };
        ownServerReach.reachableBlock = ^(Reachability* reachability)
        {
            errorViewLoadingBlock(NO);
            dispatch_async(dispatch_get_main_queue(), ^{
                errorView.hidden = YES;
            });
            success();
            [reachability stopNotifier];
        };
        [ownServerReach startNotifier];
    };
    [internetReach startNotifier];
}

-(void) reachabilityChanged:(NSNotification*) reachNotification
{
    Reachability* reachability = reachNotification.object;
    if (!reachability) {
        return;
    }
    if (markets && reachability.currentReachabilityStatus == NotReachable)
    {
        [self resetCatalogs];
    }
    if (!isDownloadingCatalogs && !markets && reachability.currentReachabilityStatus != NotReachable)
    {
        [self resetCatalogs];
        [self downloadCatalogs];
    }
}

- (IBAction)privacyButtonPressed:(UIButton *)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[[AAAGlobals sharedInstance] privacyPolicyURL]]];
}

- (IBAction)refreshButtonPressed:(UIButton *)sender
{
    if (!lastTimeRefreshButtonWasPressed || [[NSDate date] timeIntervalSinceDate:lastTimeRefreshButtonWasPressed] > MIN_SECONDS_TO_RELOAD_DATA)
    {
        lastTimeRefreshButtonWasPressed = [NSDate date];
        [self checkForInternetConnectionOnSuccess:^{
            if (!isDownloadingCatalogs) {
                [self resetCatalogs];
                [self downloadCatalogs];
            }
        } onFailure:^{
            [self resetCatalogs];
        }];
    }
}

-(void)errorViewRetryPressed:(UIButton *)sender
{
    [self checkForInternetConnectionOnSuccess:^{
        [self resetCatalogs];
        [self downloadCatalogs];
    }onFailure:^{
        [self resetCatalogs];
    }];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [bg removeFromSuperview];
    bg = [[UIImageView alloc] init];
    bg.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:.4f];
    bg.frame = self.view.bounds;
    bg.alpha = 0.0f;
    [[UIApplication sharedApplication].keyWindow addSubview:bg];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [bg removeFromSuperview];
}

+(UIImage*)imageWithShadowForImage:(UIImage *)initialImage {
    
    CGColorSpaceRef colourSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef shadowContext = CGBitmapContextCreate(NULL, initialImage.size.width, initialImage.size.height + 4, CGImageGetBitsPerComponent(initialImage.CGImage), 0, colourSpace, kCGImageAlphaPremultipliedLast);// kCGImageAlphaPremultipliedLast
    CGColorSpaceRelease(colourSpace);
    
    CGContextSetShadowWithColor(shadowContext, CGSizeMake(0,4), 70, [UIColor blackColor].CGColor);
    CGContextDrawImage(shadowContext, CGRectMake(0, 4, initialImage.size.width, initialImage.size.height), initialImage.CGImage);
    
    CGImageRef shadowedCGImage = CGBitmapContextCreateImage(shadowContext);
    CGContextRelease(shadowContext);
    
    UIImage * shadowedImage = [UIImage imageWithCGImage:shadowedCGImage];
    CGImageRelease(shadowedCGImage);
    
    return shadowedImage;
}

-(void) addTheMarkets
{
    int border = 5;
    int side = marketsScrollView.bounds.size.height;
    CGSize viewSize = CGSizeMake(side, side);
    for (int i =0; i < markets.count; i++)
    {
        AAAMarket* market = markets[i];
        float viewFinalWidth = viewSize.width - (border*2);
        float viewFinalHeight = viewFinalWidth;
        float viewX = i * viewSize.width + border + marketsScrollView.bounds.size.width/2 - viewSize.width/2;

        UIView* marketView = [[UIView alloc] initWithFrame:CGRectMake(viewX, border, viewFinalWidth, viewFinalHeight)];
        UIButton* btn = [[UIButton alloc] initWithFrame:marketView.bounds];
        [btn setBackgroundColor:[UIColor grayColor]];
        
        NSURL* imagURL = [NSURL URLWithString:market.miniLogoURL];

        [[JMImageCache sharedCache] imageForURL:imagURL completionBlock:^(UIImage *image) {
            UIImage* newImage = [AAAMarketsCatalogsVC imageWithShadowForImage:image];
            [btn setBackgroundImage:newImage forState:UIControlStateNormal];
        } failureBlock:^(NSURLRequest *request, NSURLResponse *response, NSError *error) {
            NSLog(@"JMIMageCache failed: %@", error);
        }];
        
        btn.tag = i;
        [btn addTarget:self action:@selector(marketButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        marketView.alpha = DisabledMarketViewTransparency;
        [marketView addSubview:btn];
        [marketsScrollView addSubview:marketView];
        marketsScrollView.contentSize = CGSizeMake(marketView.frame.origin.x + marketView.frame.size.width + border + marketsScrollView.bounds.size.width/2 - viewSize.width/2, viewSize.height);
        [marketViews addObject:marketView];
    }
}

-(void) marketButtonClicked:(UIButton*) btn
{
    if ([currentShownMarketView isEqual:marketViews[btn.tag]]) {
        return;
    }
    currentShowingMarket = markets[btn.tag];
    [self setTheCatalogsForMarket:currentShowingMarket];
    [self setMarketViewAsSelected:marketViews[btn.tag]];
    
    [[AAATutorialManager instance] invalidateTutorialView:TutorialViewTapOnMarket];
    [[AAATutorialManager instance] showTutorialView:currentShowingMarket.catalogs.count > 1 ? TutorialViewDiscoverCatalogs : TutorialViewTapOnCatalog];
}

-(void) setMarketViewAsSelected:(UIView*) btn
{
    int scaleDiff = 2;
    CGRect currentShowingMarketBtnNewFrame = currentShownMarketView ? currentShownMarketView.frame : CGRectZero;
    currentShowingMarketBtnNewFrame.origin.x += scaleDiff;
    currentShowingMarketBtnNewFrame.origin.y += scaleDiff;
    currentShowingMarketBtnNewFrame.size.width -= scaleDiff*2;
    currentShowingMarketBtnNewFrame.size.height -= scaleDiff*2;
    
    CGRect newMarketBtnFrame = btn.frame;
    newMarketBtnFrame.origin.x -= scaleDiff;
    newMarketBtnFrame.origin.y -= scaleDiff;
    newMarketBtnFrame.size.height += scaleDiff*2;
    newMarketBtnFrame.size.width += scaleDiff*2;
    
    
    [UIView animateWithDuration:.1f animations:^{
        if (currentShownMarketView) {
            currentShownMarketView.frame = currentShowingMarketBtnNewFrame;
            currentShownMarketView.alpha = DisabledMarketViewTransparency;
        }
        btn.frame = newMarketBtnFrame;
        btn.alpha = 1.0f;
    } completion:^(BOOL finished) {
        currentShownMarketView = btn;
    }];
}

const static int catalogSubviewTag = 21341;

-(void) setTheCatalogsForMarket:(AAAMarket*) market
{
    [Flurry logEvent:FlurryEventMarketOpened withParameters:@{FlurryParameterMarketName:market.name, FlurryParameterMarketPriority : @(market.priority)}];
    [carousel reloadData];
    [carousel setCurrentItemIndex:0];
}

#pragma mark - AAAEvents

-(void)closeCatalogVC:(AAACatalogVC *)catalogVC
{
    CGRect toFrame = [self.view convertRect:containerViewOfShownCatalog.frame fromView:containerViewOfShownCatalog.superview];
    UIViewAnimationOptions options = UIViewAnimationOptionLayoutSubviews;
    [UIView animateWithDuration:.4f delay:.0f options:options animations:^{
        [catalogVC.view layoutIfNeeded];
        catalogVC.view.frame = toFrame;
        bg.alpha = 0.0f;
        topBar.alpha = 1.0f;
    } completion:^(BOOL finished) {
        catalogVC.view.frame = containerViewOfShownCatalog.bounds;
        [containerViewOfShownCatalog addSubview:catalogVC.view];
        [catalogVC finishedMinimized];
        [[AAATutorialManager instance] showTutorialView:TutorialViewDiscoverMarkets];
        [[AAATutorialManager instance] showTutorialView:TutorialViewTapOnMarket];
        [[AAATutorialManager instance] showTutorialView:currentShowingMarket.catalogs.count > 1 ? TutorialViewDiscoverCatalogs : TutorialViewTapOnCatalog];
    }];
}

#pragma mark - iCarousel Datasource

-(NSInteger)numberOfItemsInCarousel:(iCarousel *)carousel
{
    currentShowingCatalogs = [NSMutableArray array];
    return currentShowingMarket ? currentShowingMarket.catalogs.count : 0;
}

-(UIView *)carousel:(iCarousel *)_carousel viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view
{
    if (currentShowingMarket.catalogs.count <= index) {
        return nil;
    }
    int border = 20;
    CGSize viewSize = CGSizeMake(carousel.bounds.size.width - (2*border), carousel.bounds.size.height - border);
    
    NSMutableArray* catalogVCForShowingMarket = [catalogsVCs objectForKey:[NSNumber numberWithInt:currentShowingMarket.identifier]];
    if (!catalogVCForShowingMarket)
    {
        catalogVCForShowingMarket = [NSMutableArray array];
        catalogsVCs[[NSNumber numberWithInt:currentShowingMarket.identifier]] = catalogVCForShowingMarket;
    }
    AAACatalogVC* catalogVC = nil;
    if (catalogVCForShowingMarket.count <= index) {
        AAACatalog* catalog = currentShowingMarket.catalogs[index];
        catalogVC = [self.storyboard instantiateViewControllerWithIdentifier:@"catalogVC"];
        [catalogVC view];//to call viewdidload in AAACatalogVC
        catalogVC.catalog = catalog;
        [catalogVC setDelegate:self];
        [catalogVCForShowingMarket addObject:catalogVC];
        [self addChildViewController:catalogVC];
    }
    else
    {
        catalogVC = catalogVCForShowingMarket[index];
    }
    
    UIView* containerView = [[UIView alloc] initWithFrame:CGRectMake(border, border/2, viewSize.width, viewSize.height)];
    catalogViewMaxFrame = containerView.frame;
    catalogVC.view.frame = containerView.bounds;
    [containerView addSubview:catalogVC.view];
    containerView.tag = catalogSubviewTag;
    currentShowingCatalogs[index] = catalogVC;
    return containerView;
}

-(CGFloat)carousel:(iCarousel *)carousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value
{
    switch (option) {
        case iCarouselOptionVisibleItems:
            return 3;
        case iCarouselOptionWrap:
            return NO;
        case iCarouselOptionArc:
            return M_PI * 1.0f;
        case iCarouselOptionSpacing:
            return value * 1.2;
        case iCarouselOptionShowBackfaces:
            return NO;
        case iCarouselOptionFadeMinAlpha:
        case iCarouselOptionFadeMin:
        case iCarouselOptionFadeMax:
        case iCarouselOptionCount:
        case iCarouselOptionFadeRange:
        case iCarouselOptionAngle:
        case iCarouselOptionOffsetMultiplier:
        case iCarouselOptionRadius:
        case iCarouselOptionTilt:
        default:
            return value;
    }
}

#pragma mark - iCarousel Delegate

-(void)carousel:(iCarousel *)_carousel didSelectItemAtIndex:(NSInteger)index
{
    AAACatalogVC* catalogVC = currentShowingCatalogs[index];
    containerViewOfShownCatalog = catalogVC.view.superview;
    [catalogVC maximize];
    CGRect initialFrame = [self.view convertRect:catalogVC.view.frame fromView:catalogVC.view.superview];
    catalogVC.view.frame = initialFrame;
    
    [[UIApplication sharedApplication].keyWindow addSubview:catalogVC.view];
    UIViewAnimationOptions options = UIViewAnimationOptionLayoutSubviews;
    [catalogVC.view layoutSubviews];
    
    [UIView animateWithDuration:.4f delay:.0f options:options animations:^{
        bg.alpha = 1.0f;
        [catalogVC.view layoutIfNeeded];
        catalogVC.view.frame = [UIApplication sharedApplication].keyWindow.bounds;
        topBar.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [catalogVC finishedMaximized];
    }];
    AAACatalog* catalog = catalogVC.catalog;
    [Flurry logEvent:FlurryEventAdOpened withParameters:@{FlurryParameterCatalogId : [NSString stringWithFormat:@"%i",catalog.identifier],
                                                          FlurryParameterCatalogIndex : [NSString stringWithFormat:@"%li", (long)index],
                                                          FlurryParameterCatalogPriority : [NSString stringWithFormat:@"%f", catalog.priority],
                                                        FlurryParameterMarketName : currentShowingMarket.name}];
    [[AAATutorialManager instance] invalidateTutorialView:TutorialViewTapOnCatalog];
}

-(void)carouselDidScroll:(iCarousel *)_carousel
{
    if (!_carousel.isDragging) {
        return;
    }
    if (currentShowingMarket && currentShowingMarket.catalogs.count > 1) {
        [[AAATutorialManager instance] invalidateTutorialView:TutorialViewDiscoverCatalogs];
        [[AAATutorialManager instance] showTutorialView:TutorialViewTapOnCatalog];
    }
}

#pragma mark - Scroll View delegate

//-(void) showFullMarketViewsAfterScrollViewStopped
//{
//    float leftX = marketsScrollView.contentOffset.x;
//    float rightX = leftX + marketsScrollView.bounds.size.width;
//    if (rightX > marketsScrollView.contentSize.width) {
//        rightX = marketsScrollView.contentSize.width;
//        leftX = rightX - marketsScrollView.bounds.size.width;
//    }
//    for (UIView* marketView in marketViews) {
//        float marketViewX = marketView.frame.origin.x;
//        float marketViewWidth = marketView.frame.size.width;
//        if (marketsScrollViewDirection == ScrollDirectionLeft)
//        {
//            if () {
//                <#statements#>
//            }
//        }
//    }
//}
//
//-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
//{
//    NSLog(@"scrollViewDidEndDecelerating");
//}
//
//-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
//{
//    if (!decelerate) {
//        NSLog(@"scrollViewDidEndDragging");
//    }
//}
//
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ([scrollView isEqual:marketsScrollView]) {
        [[AAATutorialManager instance] invalidateTutorialView:TutorialViewDiscoverMarkets];
        [[AAATutorialManager instance] showTutorialView:TutorialViewTapOnMarket];
        
        
//        [[AAATutorialViewController instance] animateStepNumber:iTutorialViewStepNumberSecond inTutorialView:iTutorialViewTypeMarketsBar];
//        [[AAATutorialViewController instance] updateProgress:iTutorialViewTypeMarketsBar progress:iTutorialViewStepNumberFirst];
    }
    
//    if (marketsScrollViewLastContentOffset.x > scrollView.contentOffset.x)
//        marketsScrollViewDirection = ScrollDirectionRight;
//    else if (marketsScrollViewLastContentOffset.x < scrollView.contentOffset.x)
//        marketsScrollViewDirection = ScrollDirectionLeft;
//    
//    marketsScrollViewLastContentOffset = scrollView.contentOffset;
}

@end
