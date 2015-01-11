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
#import "AAAMarketCollectionViewCell.h"

#define CLAMP(x, low, high)  (((x) > (high)) ? (high) : (((x) < (low)) ? (low) : (x)))

@interface AAAMarketsCatalogsVC()
{
    NSMutableArray* markets;
    NSMutableArray* enabledMarkets;
    IBOutlet UIScrollView* marketsScrollView;
    
    AAAMarket* currentShowingMarket;
    NSMutableArray* currentShowingCatalogs;
    UIView* containerViewOfShownCatalog;
    
    AAAwww* www;
//    UIView* currentShownMarketView;
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
    
    __weak IBOutlet NSLayoutConstraint *marketsViewHeightConstraint;
    float bottomLimitYMarketsViewHeightConstraint;
    float topLimitYMarketsViewHeightConstraint;
    float previousMarketsViewHeight;
    __weak IBOutlet UICollectionView *marketViewsCollectionView;
    
    BOOL _isInEditMode;
//    NSIndexPath* lastSelectedMarketIndexPath;
    NSMutableDictionary* enabledMarketsUserDefaults;
    
//    NSMutableArray* marketsCollectionViewDatasource;
}
- (IBAction)privacyButtonPressed:(UIButton *)sender;
- (IBAction)refreshButtonPressed:(UIButton *)sender;

-(IBAction) errorViewRetryPressed:(UIButton*)sender;
@end

@implementation AAAMarketsCatalogsVC
const static int MIN_SECONDS_TO_RELOAD_DATA = 10;

NSString* const kMarketCellReuseIdentifier = @"marketViewCellReuseIdentifier";
NSString* const kEnabledMarketsUserDefaultsKey = @"EnabledMarkets";
static Reachability* internetReach;
static Reachability* ownServerReach;

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
    UIView* dragMarketsTutorial = [[AAATutorialManager instance] addTutorialView:TutorialViewDiscoverMarkets withDependecies:@[] atCenter:marketsScrollView.superview.center];
    [self.view addSubview:dragMarketsTutorial];
    UIView* tapMarketTutorial = [[AAATutorialManager instance] addTutorialView:TutorialViewTapOnMarket withDependecies:@[@(TutorialViewDiscoverMarkets)] atCenter:marketsScrollView.superview.center];
    [self.view addSubview:tapMarketTutorial];
    UIView* dragCatalogsTutorial = [[AAATutorialManager instance] addTutorialView:TutorialViewDiscoverCatalogs withDependecies:@[@(TutorialViewDiscoverMarkets), @(TutorialViewTapOnMarket)] atCenter:carousel.center];
    [self.view addSubview:dragCatalogsTutorial];
    UIView* tapCatalogTutorial = [[AAATutorialManager instance] addTutorialView:TutorialViewTapOnCatalog withDependecies:@[@(TutorialViewDiscoverMarkets), @(TutorialViewTapOnMarket)] atCenter:carousel.center];
    [self.view addSubview:tapCatalogTutorial];

    [[AAATutorialManager instance] showTutorialView:TutorialViewDiscoverMarkets];
    [[AAATutorialManager instance] showTutorialView:TutorialViewTapOnMarket];
    [[AAATutorialManager instance] showTutorialView:TutorialViewDiscoverCatalogs];
    [[AAATutorialManager instance] showTutorialView:TutorialViewTapOnCatalog];
    
    bottomLimitYMarketsViewHeightConstraint = marketsViewHeightConstraint.constant;
    topLimitYMarketsViewHeightConstraint = [UIScreen mainScreen].bounds.size.height - bottomLimitYMarketsViewHeightConstraint;

    if ([[NSUserDefaults standardUserDefaults] objectForKey:kEnabledMarketsUserDefaultsKey])
    {
        NSData* marketsDisabledData = [[NSUserDefaults standardUserDefaults] objectForKey:kEnabledMarketsUserDefaultsKey];
        enabledMarketsUserDefaults = [NSKeyedUnarchiver unarchiveObjectWithData:marketsDisabledData];
        
//        disabledMarkets = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:kEnabledMarketsUserDefaultsKey]];
    }
    else
    {
        enabledMarketsUserDefaults = [NSMutableDictionary dictionary];
    }
    
    
//    [marketViewsCollectionView registerClass:[AAAMarketCollectionViewCell class] forCellWithReuseIdentifier:kMarketCellReuseIdentifier];
    UICollectionViewFlowLayout* flowLayout = (UICollectionViewFlowLayout*)marketViewsCollectionView.collectionViewLayout;
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    marketViewsCollectionView.allowsMultipleSelection = NO;

//    marketsCollectionViewDatasource = [NSMutableArray array];
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

- (void)updateEnabledMarketsDatasource
{
    enabledMarkets = [NSMutableArray arrayWithArray:[markets filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(AAAMarket* evaluatedObject, NSDictionary *bindings) {
        if (![enabledMarketsUserDefaults objectForKey:@(evaluatedObject.identifier)] || [[enabledMarketsUserDefaults objectForKey:@(evaluatedObject.identifier)] boolValue]) {
            return YES;
        }
        return NO;
    }]]];
    enabledMarkets = [NSMutableArray arrayWithArray:[enabledMarkets sortedArrayUsingComparator:^NSComparisonResult(AAAMarket* obj1, AAAMarket* obj2) {
        return [[NSNumber numberWithDouble:obj1.priority] compare:[NSNumber numberWithDouble:obj2.priority]];
    }]];
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
        [self updateEnabledMarketsDatasource];
//        [self addTheMarkets];
        [marketViewsCollectionView reloadData];
        if (markets.count>0) {
            currentShowingMarket = enabledMarkets[0];
            [self setTheCatalogsForMarket:currentShowingMarket];

            for (NSIndexPath* path in [marketViewsCollectionView indexPathsForVisibleItems]) {
                [marketViewsCollectionView deselectItemAtIndexPath:path animated:NO];
            }
            NSIndexPath* lastSelectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
            [marketViewsCollectionView selectItemAtIndexPath:lastSelectedIndexPath animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
            
//            [self setMarketViewAsSelected:marketViews[0]];
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

//-(void) addTheMarkets
//{
////    int border = 8;
////    int side = marketsScrollView.bounds.size.height;
////    CGSize viewSize = CGSizeMake(side, side);
//    for (int i =0; i < markets.count; i++)
//    {
//        AAAMarket* market = markets[i];
////        float viewFinalWidth = viewSize.width - (border*2);
////        float viewFinalHeight = viewFinalWidth;
////        float viewX = i * viewSize.width + border + marketsScrollView.bounds.size.width/2 - viewSize.width/2;
//
////        UIView* marketView = [[UIView alloc] initWithFrame:CGRectMake(viewX, border, viewFinalWidth, viewFinalHeight)];
//        UIView* marketView = [[UIView alloc] initWithFrame:CGRectZero];
//
//        UIButton* btn = [[UIButton alloc] initWithFrame:marketView.bounds];
//        [btn setBackgroundColor:[UIColor grayColor]];
//        
//        NSURL* imagURL = [NSURL URLWithString:market.miniLogoURL];
//
//        [[JMImageCache sharedCache] imageForURL:imagURL completionBlock:^(UIImage *image) {
//            UIImage* newImage = [AAAMarketsCatalogsVC imageWithShadowForImage:image];
//            [btn setBackgroundImage:newImage forState:UIControlStateNormal];
//        } failureBlock:^(NSURLRequest *request, NSURLResponse *response, NSError *error) {
//            NSLog(@"JMIMageCache failed: %@", error);
//        }];
//        
//        btn.tag = i;
//        [btn addTarget:self action:@selector(marketButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
//        marketView.alpha = DisabledMarketViewTransparency;
//        [marketView addSubview:btn];
//        [marketsScrollView addSubview:marketView];
////        marketsScrollView.contentSize = CGSizeMake(marketView.frame.origin.x + marketView.frame.size.width + border + marketsScrollView.bounds.size.width/2 - viewSize.width/2, viewSize.height);
//        [marketViews addObject:marketView];
//    }
//    [self arrangeMArketViewsInNormalMode];
//}

//-(void) marketButtonClicked:(UIButton*) btn
//{
//    if ([currentShownMarketView isEqual:marketViews[btn.tag]]) {
//        return;
//    }
//    currentShowingMarket = markets[btn.tag];
//    [self setTheCatalogsForMarket:currentShowingMarket];
//    [self setMarketViewAsSelected:marketViews[btn.tag]];
//    
//    //scroll marketView to the center of the screen
//    CGPoint btnCenter = ((UIView*)marketViews[btn.tag]).center;
//    CGSize scrollViewSize = marketsScrollView.bounds.size;
//    CGRect frameWithBtnInCenter = CGRectMake(btnCenter.x - scrollViewSize.width/2, 0, scrollViewSize.width, scrollViewSize.height);
//    [marketsScrollView scrollRectToVisible:frameWithBtnInCenter animated:YES];
//    
//    //handle tutorial
//    [[AAATutorialManager instance] invalidateTutorialView:TutorialViewTapOnMarket];
//    [[AAATutorialManager instance] showTutorialView:currentShowingMarket.catalogs.count > 1 ? TutorialViewDiscoverCatalogs : TutorialViewTapOnCatalog];
//}

-(void) setMarketViewAsSelected:(UIView*) btn
{
    int scaleDiff = 2;
    int indexOfCurrentMarket = _isInEditMode ? [markets indexOfObject:currentShowingMarket] : [enabledMarkets indexOfObject: currentShowingMarket];
    UIView* currentShownMarketView = [marketViewsCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:indexOfCurrentMarket inSection:0]];
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
//            currentShownMarketView.alpha = DisabledMarketViewTransparency;
        }
        btn.frame = newMarketBtnFrame;
        btn.alpha = 1.0f;
    } completion:^(BOOL finished)
     {
//        currentShownMarketView = btn;
    }];
}

const static int catalogSubviewTag = 21341;

-(void) setTheCatalogsForMarket:(AAAMarket*) market
{
    [Flurry logEvent:FlurryEventMarketOpened withParameters:@{FlurryParameterMarketName:market.name, FlurryParameterMarketPriority : @(market.priority)}];
    [carousel reloadData];
    [carousel setCurrentItemIndex:0];
}

- (IBAction)editViewDrag:(UIPanGestureRecognizer *)sender
{
    float y = [UIScreen mainScreen].bounds.size.height - [sender locationInView:self.view].y;
    y = CLAMP(y, bottomLimitYMarketsViewHeightConstraint, topLimitYMarketsViewHeightConstraint);
    
//    [self arrangeMarketViewsInEditMode];
    
    if (sender.state == UIGestureRecognizerStateBegan && marketsViewHeightConstraint.constant == bottomLimitYMarketsViewHeightConstraint)
    {
        //open edit view
        [self goToEditMode:YES];
    }
    
    if (sender.state == UIGestureRecognizerStateEnded || sender.state == UIGestureRecognizerStateFailed || sender.state == UIGestureRecognizerStateCancelled)
    {
        if (marketsViewHeightConstraint.constant == bottomLimitYMarketsViewHeightConstraint) {
            //close the edit view
            [self changeEditMenuStateToClosed:YES onCompletion:^{
                [self selectMarketInCollectionView:currentShowingMarket];
            }];
            return;
//            [self arrangeMArketViewsInNormalMode];
        }
        if (previousMarketsViewHeight < y)
        {
            //direction up
            y = topLimitYMarketsViewHeightConstraint;
            [self changeEditMenuStateToClosed:NO onCompletion:nil];
        }
        else
        {
            //direction down
            y = bottomLimitYMarketsViewHeightConstraint;
            [self changeEditMenuStateToClosed:YES onCompletion:^{
                [self selectMarketInCollectionView:currentShowingMarket];
            }];
        }
    }
    marketsViewHeightConstraint.constant = y;
    
    if (sender.state == UIGestureRecognizerStateRecognized && previousMarketsViewHeight != y) {
        previousMarketsViewHeight = y;
    }
}

-(void) goToEditMode:(BOOL) editMode
{
    _isInEditMode = editMode;
    marketViewsCollectionView.allowsSelection = !editMode;
    UICollectionViewFlowLayout* layout = (UICollectionViewFlowLayout*)marketViewsCollectionView.collectionViewLayout;
    if (editMode)
    {
        CGSize contSize = marketViewsCollectionView.contentSize;
        contSize.width = marketViewsCollectionView.bounds.size.width;
        marketViewsCollectionView.contentSize = contSize;
        marketViewsCollectionView.contentInset = UIEdgeInsetsMake(10, 10, 10, 10);
        [layout setScrollDirection:UICollectionViewScrollDirectionVertical];
    }
    else{
        [layout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
        marketViewsCollectionView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
        
        [self updateEnabledMarketsDatasource];
        
        //save the settings
        NSData* disabledMarketsData = [NSKeyedArchiver archivedDataWithRootObject:enabledMarketsUserDefaults];
        [[NSUserDefaults standardUserDefaults] setObject:disabledMarketsData forKey:kEnabledMarketsUserDefaultsKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

-(void) changeEditMenuStateToClosed:(BOOL)close onCompletion:(void(^)(void))completion
{
    [self goToEditMode:!close];

    [UIView animateWithDuration:.4f animations:^{
//        [marketViewsCollectionView performBatchUpdates:^{
//            [marketViewsCollectionView reloadData];
//        } completion:^(BOOL finished) {
//            
//        }];
//        [marketViewsCollectionView reloadItemsAtIndexPaths:marketViewsCollectionView.indexPathsForVisibleItems];
        [marketViewsCollectionView reloadData];
    }];
    
    [UIView animateWithDuration:.5f animations:^{
        marketsViewHeightConstraint.constant = close ? bottomLimitYMarketsViewHeightConstraint : topLimitYMarketsViewHeightConstraint;
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        if (finished) {
            if (completion) {
                completion();
            }
        }
    }];
}

-(void) selectMarketInCollectionView:(AAAMarket*) market
{
    int row = [enabledMarkets containsObject:market] ? [enabledMarkets indexOfObject:market] : (enabledMarkets.count > 0 ? 0 : -1);
    if (row >= 0) {
        NSIndexPath* lastSelectedIndexPath = [NSIndexPath indexPathForRow:row inSection:0];
        [marketViewsCollectionView selectItemAtIndexPath:lastSelectedIndexPath animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
        [self collectionView:marketViewsCollectionView didSelectItemAtIndexPath:lastSelectedIndexPath];
    }
}

-(void) arrangeMArketViewsInNormalMode
{
    int border = 8;
    int side = marketsScrollView.bounds.size.height;
    CGSize viewSize = CGSizeMake(side, side);
    for (int i =0; i < marketViews.count; i++)
    {
        float viewFinalWidth = viewSize.width - (border*2);
        float viewFinalHeight = viewFinalWidth;
        float viewX = i * viewSize.width + border + marketsScrollView.bounds.size.width/2 - viewSize.width/2;
        UIView* marketView = marketViews[i];
        UIButton* btn = nil;
        for (UIView* subv in marketView.subviews) {
            if ([subv isKindOfClass:[UIButton class]] && subv.tag == i) {
                btn = (UIButton*)subv;
                break;
            }
        }
        [UIView animateWithDuration:.3f animations:^{
            marketView.frame = CGRectMake(viewX, border, viewFinalWidth, viewFinalHeight);
            btn.frame = marketView.bounds;
        } completion:^(BOOL finished) {
            [marketsScrollView bringSubviewToFront:marketView];
        }];
        marketsScrollView.contentSize = CGSizeMake(marketView.frame.origin.x + marketView.frame.size.width + border + marketsScrollView.bounds.size.width/2 - viewSize.width/2, viewSize.height);
    }
}

//-(void) arrangeMarketViewsInEditMode
//{
//    float minSpacingBetweenMarketViews = 10;
//    CGSize marketViewSize = CGSizeZero;
//    for (UIView* v in marketViews) {
//        if (![v isEqual:currentShownMarketView]) {
//            marketViewSize = v.frame.size;
//            break;
//        }
//    }
//    float scrollViewWitdth = marketsScrollView.bounds.size.width;
//    int numberOfMarketViewsFull = (int)scrollViewWitdth/marketViewSize.width;
//
//    float emptySpace = scrollViewWitdth - (marketViewSize.width * numberOfMarketViewsFull);
//    float spaceInBetweenMarketViews = emptySpace / numberOfMarketViewsFull;
//    if (spaceInBetweenMarketViews <= minSpacingBetweenMarketViews) {
//        numberOfMarketViewsFull --;
//        emptySpace = scrollViewWitdth - (marketViewSize.width * numberOfMarketViewsFull);
//        spaceInBetweenMarketViews = emptySpace / numberOfMarketViewsFull;
//    }
//    
//    int rows = (int)(marketsScrollView.bounds.size.height / (marketViewSize.height + spaceInBetweenMarketViews));
//    for (int i =0; i < marketViews.count; i++)
//    {
//        int row = i / numberOfMarketViewsFull;
//        row = row > rows - 1 ? 0 : row;
//        int column = i % numberOfMarketViewsFull;
//        column = row == 0 ? i : column;
//        column = column > numberOfMarketViewsFull ? numberOfMarketViewsFull + i%numberOfMarketViewsFull : column;
//        float x = spaceInBetweenMarketViews/2 + (column*spaceInBetweenMarketViews) + (column*marketViewSize.width);
//        UIView* marketV = marketViews[i];
//        CGRect marketViewFrame = marketV.frame;
//        marketViewFrame.origin.x = x;
//        float y = spaceInBetweenMarketViews/2 + (row * spaceInBetweenMarketViews) + (row * marketViewSize.height);
//        y = column > numberOfMarketViewsFull - 1 ? marketsScrollView.bounds.size.height - spaceInBetweenMarketViews/2 - marketViewSize.height : y;
//        marketViewFrame.origin.y = y;
//        [UIView animateWithDuration:.3f animations:^{
//            marketV.frame = marketViewFrame;
//        }];
//        marketsScrollView.contentSize = CGSizeMake(marketViewFrame.origin.x + marketViewFrame.size.width + spaceInBetweenMarketViews/2.0f, marketViewSize.width);
//    }
//}

-(CGSize) marketCellSize
{
    return CGSizeMake(88, 88);
}

-(float) minMarketCellSpacing
{
    return 10;
}

//-(int) numberOfItemsPerSpace
//{
//    CGSize markViewSize = [self marketCellSize];
//    int noOfItems = marketViewsCollectionView.bounds.size.width / markViewSize.width;
//    float space = marketViewsCollectionView.bounds.size.width - (noOfItems * markViewSize.width);
//    float spaceBetweenTwoItems = space / noOfItems;
//    if (spaceBetweenTwoItems < space) {
//        noOfItems--;
//        space = marketViewsCollectionView.bounds.size.width - (noOfItems * markViewSize.width);
//        spaceBetweenTwoItems = space / noOfItems;
//    }
//    return noOfItems;
//}

-(void) updateMarketCollectionDatasource
{
    if (_isInEditMode)
    {
        CGSize markViewSize = [self marketCellSize];
        int noOfItems = marketViewsCollectionView.bounds.size.width / markViewSize.width;
        float space = marketViewsCollectionView.bounds.size.width - (noOfItems * markViewSize.width);
        float spaceBetweenTwoItems = space / noOfItems;
        if (spaceBetweenTwoItems < space) {
            noOfItems--;
            space = marketViewsCollectionView.bounds.size.width - (noOfItems * markViewSize.width);
            spaceBetweenTwoItems = space / noOfItems;
        }
        
        
    }
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
            return M_PI * 1.3f;
        case iCarouselOptionSpacing:
            return value * 1.2;
        case iCarouselOptionShowBackfaces:
            return NO;
        case iCarouselOptionRadius:
        case iCarouselOptionOffsetMultiplier:
        case iCarouselOptionTilt:
        case iCarouselOptionFadeMinAlpha:
        case iCarouselOptionFadeMin:
        case iCarouselOptionFadeMax:
        case iCarouselOptionCount:
        case iCarouselOptionFadeRange:
        case iCarouselOptionAngle:
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

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ([scrollView isEqual:marketsScrollView]) {
        [[AAATutorialManager instance] invalidateTutorialView:TutorialViewDiscoverMarkets];
        [[AAATutorialManager instance] showTutorialView:TutorialViewTapOnMarket];
    }
}

#pragma mark - UICOllectionView Datasource & Delegate

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _isInEditMode ? (markets ? markets.count : 0) : (enabledMarkets ? enabledMarkets.count : 0);
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    AAAMarketCollectionViewCell* selectedCell = (AAAMarketCollectionViewCell*)[collectionView cellForItemAtIndexPath:indexPath];
    if (currentShowingMarket.identifier == selectedCell.market.identifier) {
        return;
    }
    
    currentShowingMarket = enabledMarkets[indexPath.row]; //it should not be possible to select cells in normal mode, only during edit
    [self setTheCatalogsForMarket:currentShowingMarket];
    [self setMarketViewAsSelected:selectedCell];
    [collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    
    //handle tutorial
    [[AAATutorialManager instance] invalidateTutorialView:TutorialViewTapOnMarket];
    [[AAATutorialManager instance] showTutorialView:currentShowingMarket.catalogs.count > 1 ? TutorialViewDiscoverCatalogs : TutorialViewTapOnCatalog];

}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    AAAMarketCollectionViewCell* cell = (AAAMarketCollectionViewCell*)[collectionView dequeueReusableCellWithReuseIdentifier:kMarketCellReuseIdentifier forIndexPath:indexPath];
    AAAMarket* market = (AAAMarket*) (_isInEditMode ? markets[indexPath.row] : enabledMarkets[indexPath.row]);
    cell.isActive = [enabledMarketsUserDefaults objectForKey:@(market.identifier)] ? [[enabledMarketsUserDefaults objectForKey:@(market.identifier)] boolValue] : YES;
    [cell setupEditModeOn:_isInEditMode];
    [cell onSelected:^(AAAMarket* _market) {
        [self changeEditMenuStateToClosed:YES onCompletion:^{
            [self selectMarketInCollectionView:_market];
        }];
        
//        [collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
//        [self collectionView:collectionView didSelectItemAtIndexPath:indexPath];
    }];
    [cell onActiveChanged:^(AAAMarketCollectionViewCell *cell) {
        BOOL thereIsAtLeastOneOtherActiveMarket = NO;
        for (AAAMarket* mark in markets) {
            if (![enabledMarketsUserDefaults objectForKey:@(mark.identifier)] || [[enabledMarketsUserDefaults objectForKey:@(mark.identifier)] boolValue]) {
                if (mark.identifier != cell.market.identifier) {
                    thereIsAtLeastOneOtherActiveMarket = YES;
                    break;
                }
            }
        }
        if (thereIsAtLeastOneOtherActiveMarket) {
            [enabledMarketsUserDefaults setObject:@(cell.isActive) forKey:@(market.identifier)];
        }
        else
        {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Atenție" message:@"Nu este posibil sa ascunzi toate marketurile!" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
        }
        return thereIsAtLeastOneOtherActiveMarket;
    }];
    
    cell.market = market;
//    UIImageView* imgView = nil;
//    for (UIView* subv in cell.contentView.subviews) {
//        if ([subv isKindOfClass:[UIImageView class]] && subv.tag == 212) {
//            imgView = (UIImageView*)subv;
//            break;
//        }
//    }
//    [imgView setImage:nil];
    
//    NSURL* imagURL = [NSURL URLWithString:market.miniLogoURL];
//    [[JMImageCache sharedCache] imageForURL:imagURL completionBlock:^(UIImage *image) {
//        UIImage* newImage = [AAAMarketsCatalogsVC imageWithShadowForImage:image];
//        [imgView setImage:newImage];
//        if (!_isInEditMode && lastSelectedMarketIndexPath && [lastSelectedMarketIndexPath isEqual: indexPath])
//        {
//            [self setMarketViewAsSelected:cell];
//        }
//    } failureBlock:^(NSURLRequest *request, NSURLResponse *response, NSError *error) {
//        NSLog(@"JMIMageCache failed: %@", error);
//    }];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self marketCellSize];
}

-(CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 10;
}

-(CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    if (_isInEditMode) {
        CGSize itemSize = [((id<UICollectionViewDelegateFlowLayout>)collectionView.delegate) collectionView:collectionView layout:collectionViewLayout sizeForItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0 ]];
        float collectionViewWidth = collectionView.contentSize.width;
        float minSpacing = 10;
        int numberOfItemsPerRow = collectionViewWidth/itemSize.width;
        float space = collectionViewWidth - (numberOfItemsPerRow * itemSize.width);
        if (space < (numberOfItemsPerRow * minSpacing)) {
            numberOfItemsPerRow --;
            space = collectionViewWidth - (numberOfItemsPerRow * itemSize.width);
        }
        float spaceBetweenTwoItems = space / numberOfItemsPerRow;
        return spaceBetweenTwoItems;
    }
    return 10;
}

-(CGSize) collectionViewPadding:(UICollectionView*) collectionView withLayout:(UICollectionViewLayout*) layout
{
    if (markets)
    {
        CGSize itemSize = [((id<UICollectionViewDelegateFlowLayout>)collectionView.delegate) collectionView:collectionView layout:layout sizeForItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        float x = collectionView.bounds.size.width/2 - itemSize.width/2;
        return CGSizeMake(x, 0);
    }
    return CGSizeZero;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section;
{
    if (_isInEditMode) {
        return CGSizeZero;
    }
    return [self collectionViewPadding:collectionView withLayout:collectionViewLayout];
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section
{
    if (_isInEditMode) {
        return CGSizeZero;
    }
    return [self collectionViewPadding:collectionView withLayout:collectionViewLayout];
}

-(void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    [[AAATutorialManager instance] invalidateTutorialView:TutorialViewDiscoverMarkets];
    [[AAATutorialManager instance] showTutorialView:TutorialViewTapOnMarket];
}

@end
