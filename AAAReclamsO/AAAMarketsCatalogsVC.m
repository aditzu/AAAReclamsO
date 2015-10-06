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
#import "FXBlurView.h"

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
    __weak IBOutlet FXBlurView *blurView;
    
    BOOL _isInEditMode;
    NSMutableDictionary* enabledMarketsUserDefaults;
    
    UITapGestureRecognizer* blurViewTapGesture;
    IBOutlet UIPanGestureRecognizer *editMenuPanGesture;
    IBOutlet UIPanGestureRecognizer *editMenuPanGestureBlurView;
    __weak IBOutlet UIView *selectView;
    __weak IBOutlet UIImageView *burgerImageView;
    __weak IBOutlet UIView *marketsScrollSuperView;
    
    ScrollDirection _marketsViewDragDirection;
    
    NSMutableDictionary* seenCatalogs;
    BOOL _seenCatalogsDirty;
    BOOL _loadedTutorialViews;
}

- (IBAction)privacyButtonPressed:(UIButton *)sender;
- (IBAction)refreshButtonPressed:(UIButton *)sender;
-(IBAction) errorViewRetryPressed:(UIButton*)sender;
@end

@implementation AAAMarketsCatalogsVC
const static int MIN_SECONDS_TO_RELOAD_DATA = 10;
const static BOOL ENABLE_ADD_REMOVE_MARKET = NO;

NSString* const kMarketCellReuseIdentifier = @"marketViewCellReuseIdentifier";
NSString* const kEnabledMarketsUserDefaultsKey = @"EnabledMarkets";
NSString* const kSeenDictionaryUserDefaultsKey = @"SeenCatalogs";
NSString* const kFirstLaunchAppUserDefaultsKey = @"FirstLaunch";

static Reachability* internetReach;
static Reachability* ownServerReach;

-(void)viewDidLoad
{
    [super viewDidLoad];
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
    
    bottomLimitYMarketsViewHeightConstraint = marketsViewHeightConstraint.constant;
    topLimitYMarketsViewHeightConstraint = [UIScreen mainScreen].bounds.size.height - bottomLimitYMarketsViewHeightConstraint;

    [self loadUserDefaults];

    UICollectionViewFlowLayout* flowLayout = (UICollectionViewFlowLayout*)marketViewsCollectionView.collectionViewLayout;
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    marketViewsCollectionView.allowsMultipleSelection = NO;
    blurView.blurRadius = 40;
    [self updateBlurView];
    blurView.dynamic = NO;
    [blurView setUserInteractionEnabled:YES];
    
    blurViewTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(blurViewTapped:)];
    [[AAAGlobals sharedInstance].ads setBannerRootViewController:self];
    errorViewMessageLabel.numberOfLines = 0;
}

- (void)loadTutorialViews
{
    [[AAATutorialManager instance] setupWithStoryboard:self.storyboard];
    UIView* dragMarketsTutorial = [[AAATutorialManager instance] addTutorialView:TutorialViewDiscoverMarkets withDependecies:@[] atCenter:marketsScrollView.superview.center];
    [self.view addSubview:dragMarketsTutorial];
    UIView* tapMarketTutorial = [[AAATutorialManager instance] addTutorialView:TutorialViewTapOnMarket withDependecies:@[@(TutorialViewDiscoverMarkets)] atCenter:marketsScrollView.superview.center];
    [self.view addSubview:tapMarketTutorial];
    UIView* dragCatalogsTutorial = [[AAATutorialManager instance] addTutorialView:TutorialViewDiscoverCatalogs withDependecies:@[@(TutorialViewDiscoverMarkets), @(TutorialViewTapOnMarket)] atCenter:carousel.center];
    [self.view addSubview:dragCatalogsTutorial];
    UIView* tapCatalogTutorial = [[AAATutorialManager instance] addTutorialView:TutorialViewTapOnCatalog withDependecies:@[@(TutorialViewDiscoverMarkets), @(TutorialViewTapOnMarket)] atCenter:carousel.center];
    [self.view addSubview:tapCatalogTutorial];
    
    [self showNextTutorialView];
    _loadedTutorialViews = YES;
}

-(void)viewDidLayoutSubviews
{
    if (!_loadedTutorialViews) {
        [self loadTutorialViews];
        [self.view layoutSubviews];
    }
}

- (void)loadUserDefaults
{
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kEnabledMarketsUserDefaultsKey])
    {
        NSData* marketsDisabledData = [[NSUserDefaults standardUserDefaults] objectForKey:kEnabledMarketsUserDefaultsKey];
        enabledMarketsUserDefaults = [NSKeyedUnarchiver unarchiveObjectWithData:marketsDisabledData];
    }
    else
    {
        enabledMarketsUserDefaults = [NSMutableDictionary dictionary];
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kSeenDictionaryUserDefaultsKey])
    {
        NSData* marketsDisabledData = [[NSUserDefaults standardUserDefaults] objectForKey:kSeenDictionaryUserDefaultsKey];
        seenCatalogs = [NSKeyedUnarchiver unarchiveObjectWithData:marketsDisabledData];
    }
    else
    {
        seenCatalogs = [NSMutableDictionary dictionary];
    }
}

-(void) resetCatalogs
{
    dispatch_async(dispatch_get_main_queue(), ^{
        markets = [NSMutableArray array];
        enabledMarkets = [NSMutableArray array];
        for (NSString* key in [catalogsVCs allKeys]) {
            NSArray* catalogVcsForMarket = catalogsVCs[key];
            for (AAACatalogVC* catalogVC in catalogVcsForMarket) {
                [catalogVC.view removeFromSuperview];
            }
        }
        catalogsVCs = [NSMutableDictionary dictionary];
        [marketViewsCollectionView reloadData];
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
            [Flurry logError:FlurryEventErrorFromServer message:@"DownloadCatalogs" error:error];
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
        [self updateSeenMarkets];
        [marketViewsCollectionView reloadData];
        if (markets.count>0) {
            currentShowingMarket = enabledMarkets[0];
            [self setTheCatalogsForMarket:currentShowingMarket];

            for (NSIndexPath* path in [marketViewsCollectionView indexPathsForVisibleItems]) {
                [marketViewsCollectionView deselectItemAtIndexPath:path animated:NO];
            }
            NSIndexPath* lastSelectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
            [marketViewsCollectionView selectItemAtIndexPath:lastSelectedIndexPath animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
        }
        loadingView.hidden = YES;
        isDownloadingCatalogs = NO;
    }];
}

-(void) updateSeenMarkets
{
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    if (![userDefaults boolForKey:kFirstLaunchAppUserDefaultsKey])
    {
        for (AAAMarket* market in markets) {
            for (AAACatalog* catalog in market.catalogs) {
                [self setCatalogIdAsSeen:catalog.identifier forMarket:market.identifier];
            }
        }
        [userDefaults setBool:YES forKey:kFirstLaunchAppUserDefaultsKey];
        [self trySaveSeenCatalogs];
    }
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
            [Flurry logError:FlurryEventErrorNoInternet message:@"CheckForInternetConnection" error:nil];
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
                [Flurry logError:FlurryEventErrorFromServer message:@"CheckForInternetConnection" error:nil];
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
    [Flurry logEvent:FlurryEventPrivacyPolicyOpened];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[[AAAGlobals sharedInstance] privacyPolicyURL]]];
}

- (IBAction)refreshButtonPressed:(UIButton *)sender
{
    if (!lastTimeRefreshButtonWasPressed || [[NSDate date] timeIntervalSinceDate:lastTimeRefreshButtonWasPressed] > MIN_SECONDS_TO_RELOAD_DATA)
    {
        [Flurry logEvent:FlurryEventMarketsReloadedManually];
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

-(void) setMarketViewAsSelected:(UIView*) btn
{
//    int scaleDiff = 2;
//    int indexOfCurrentMarket = _isInEditMode ? [markets indexOfObject:currentShowingMarket] : [enabledMarkets indexOfObject: currentShowingMarket];
//    UIView* currentShownMarketView = [marketViewsCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:indexOfCurrentMarket inSection:0]];
//    CGRect currentShowingMarketBtnNewFrame = currentShownMarketView ? currentShownMarketView.frame : CGRectZero;
//    currentShowingMarketBtnNewFrame.origin.x += scaleDiff;
//    currentShowingMarketBtnNewFrame.origin.y += scaleDiff;
//    currentShowingMarketBtnNewFrame.size.width -= scaleDiff*2;
//    currentShowingMarketBtnNewFrame.size.height -= scaleDiff*2;
//    
//    CGRect newMarketBtnFrame = btn.frame;
//    newMarketBtnFrame.origin.x -= scaleDiff;
//    newMarketBtnFrame.origin.y -= scaleDiff;
//    newMarketBtnFrame.size.height += scaleDiff*2;
//    newMarketBtnFrame.size.width += scaleDiff*2;
//    
//    
//    [UIView animateWithDuration:.1f animations:^{
//        if (currentShownMarketView) {
//            currentShownMarketView.frame = currentShowingMarketBtnNewFrame;
//        }
//        btn.frame = newMarketBtnFrame;
//        btn.alpha = 1.0f;
//    } completion:^(BOOL finished)
//     {
////        currentShownMarketView = btn;
//    }];
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
    [self updateBlurView];
    float y = [UIScreen mainScreen].bounds.size.height - [sender locationInView:self.view].y;
    y = CLAMP(y, bottomLimitYMarketsViewHeightConstraint, topLimitYMarketsViewHeightConstraint);
    if (sender.state == UIGestureRecognizerStateBegan && marketsViewHeightConstraint.constant == bottomLimitYMarketsViewHeightConstraint)
    {
        //open edit view
        [self goToEditMode:YES];
        
        [marketViewsCollectionView reloadData];
//        [UIView animateWithDuration:.3f delay:.0f options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationCurveLinear animations:^{
//            [marketViewsCollectionView reloadData];
//            [marketViewsCollectionView layoutIfNeeded];
//        } completion:^(BOOL finished) {
        
//        }];
    }
    
    if (sender.state == UIGestureRecognizerStateEnded || sender.state == UIGestureRecognizerStateFailed || sender.state == UIGestureRecognizerStateCancelled)
    {
        if (marketsViewHeightConstraint.constant == bottomLimitYMarketsViewHeightConstraint) {
            //close the edit view
            [self changeEditMenuStateToClosed:YES onCompletion:^{
                [self selectMarketInCollectionView:currentShowingMarket];
            }];
            return;
        }
        if (_marketsViewDragDirection == ScrollDirectionUp)
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
    
    if (sender.state == UIGestureRecognizerStateChanged && previousMarketsViewHeight != y) {
        if (previousMarketsViewHeight < y) {
            _marketsViewDragDirection = ScrollDirectionUp;
        }
        else
        {
            _marketsViewDragDirection = ScrollDirectionDown;
        }
        previousMarketsViewHeight = y;
    }
}

const float minPercentageForAlpha = 100;
const float maxBlurRadius = 20;

-(void) updateBlurView
{
    float pointForMinPercentage = minPercentageForAlpha * (topLimitYMarketsViewHeightConstraint - bottomLimitYMarketsViewHeightConstraint) / 100 + bottomLimitYMarketsViewHeightConstraint;
    float y = marketsViewHeightConstraint.constant;
    float blurPercent = (y - pointForMinPercentage) / (topLimitYMarketsViewHeightConstraint - pointForMinPercentage) * 100;
    blurPercent = CLAMP(blurPercent, 0, 100);

    float alphaPercent = (y - bottomLimitYMarketsViewHeightConstraint) / (pointForMinPercentage - bottomLimitYMarketsViewHeightConstraint) * 100;
    alphaPercent = CLAMP(alphaPercent, 0, 100);
    
    [UIView animateWithDuration:.5f animations:^{
//        float blur = maxBlurRadius / 100.0f * blurPercent;
//        if (blurView.blurRadius != blur || blurView.alpha == 0)
//        {
//            blurView.blurRadius = blur;
//            [blurView updateAsynchronously:NO completion:nil];
//        }
        float alpha = alphaPercent / 100.0f;
        if (blurView.alpha != alpha)
        {
            blurView.alpha = alpha;
        }
    }];
}

-(void) goToEditMode:(BOOL) editMode
{
    _isInEditMode = editMode;
//    marketViewsCollectionView.allowsSelection = !editMode;
    UICollectionViewFlowLayout* layout = (UICollectionViewFlowLayout*)marketViewsCollectionView.collectionViewLayout;
    [UIView animateWithDuration:.3f animations:^{
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
        }
        
    }];
    if (editMode)
    {
        [[AAATutorialManager instance] hideAllTutorialViews];
    }
    else
    {
        [self updateEnabledMarketsDatasource];
        [self showNextTutorialView];
        //save the settings
        NSData* disabledMarketsData = [NSKeyedArchiver archivedDataWithRootObject:enabledMarketsUserDefaults];
        [[NSUserDefaults standardUserDefaults] setObject:disabledMarketsData forKey:kEnabledMarketsUserDefaultsKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}
- (IBAction)openCloseMenuTapped:(UITapGestureRecognizer *)sender
{
    BOOL edit =_isInEditMode;
    [self goToEditMode:!edit];
    [self changeEditMenuStateToClosed:edit onCompletion:^{
        if (edit) {
            [self selectMarketInCollectionView:currentShowingMarket];
        }
    }];
}


-(void) blurViewTapped:(UITapGestureRecognizer*) tapGesture
{
    [self changeEditMenuStateToClosed:YES onCompletion:^{
        [self selectMarketInCollectionView:currentShowingMarket];
    }];
}

-(void) changeEditMenuStateToClosed:(BOOL)close onCompletion:(void(^)(void))completion
{
    if (close)
    {
        [blurView removeGestureRecognizer:blurViewTapGesture];
        [blurView removeGestureRecognizer:editMenuPanGestureBlurView];
        
        [marketViewsCollectionView addGestureRecognizer:editMenuPanGesture];
        [marketViewsCollectionView.panGestureRecognizer requireGestureRecognizerToFail:editMenuPanGesture];
    }
    else
    {
        [blurView addGestureRecognizer:blurViewTapGesture];
        [blurView addGestureRecognizer:editMenuPanGestureBlurView];
        [marketViewsCollectionView removeGestureRecognizer:editMenuPanGesture];
        [Flurry logEvent:FlurryEventEditMenuOpened];
    }
    
    [blurView updateAsynchronously:NO completion:nil];
    
    [UIView animateWithDuration:.5f animations:^{
        marketsViewHeightConstraint.constant = close ? bottomLimitYMarketsViewHeightConstraint : topLimitYMarketsViewHeightConstraint;
        [self.view layoutIfNeeded];
        [self updateBlurView];
    } completion:^(BOOL finished) {
        if (finished)
        {
            [self goToEditMode:!close];
            [marketViewsCollectionView reloadData];
            if (completion) {
                completion();
            }
        }
    }];
}

-(void) selectMarketInCollectionView:(AAAMarket*) market
{
    int row = [enabledMarkets containsObject:market] ? (int)[enabledMarkets indexOfObject:market] : (enabledMarkets.count > 0 ? 0 : -1);
    if (row >= 0) {
        NSIndexPath* lastSelectedIndexPath = [NSIndexPath indexPathForRow:row inSection:0];
        [marketViewsCollectionView selectItemAtIndexPath:lastSelectedIndexPath animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
        [self collectionView:marketViewsCollectionView didSelectItemAtIndexPath:lastSelectedIndexPath];
    }
}

-(CGSize) marketCellSize
{
    return CGSizeMake(88, 88);
}

-(float) minMarketCellSpacing
{
    return 10;
}

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

-(void) showNextTutorialView
{
    if (!_isInEditMode) {
        [[AAATutorialManager instance] showTutorialView:TutorialViewDiscoverMarkets];
        [[AAATutorialManager instance] showTutorialView:TutorialViewTapOnMarket];
        if (currentShowingMarket && currentShowingMarket.catalogs) {
            [[AAATutorialManager instance] showTutorialView:currentShowingMarket.catalogs.count > 1 ? TutorialViewDiscoverCatalogs : TutorialViewTapOnCatalog];
        }
    }
}

-(void) seenCatalog:(int) catalogId forMarket:(int) marketid
{
    [self setCatalogIdAsSeen:catalogId forMarket:marketid];
    [self trySaveSeenCatalogs];
    
    for (NSIndexPath* cellIndexPath in [marketViewsCollectionView indexPathsForSelectedItems])
    {
        AAAMarket* marketForIndexPath = (AAAMarket*) (_isInEditMode ? markets[cellIndexPath.row] : enabledMarkets[cellIndexPath.row]);
        if (marketForIndexPath.identifier == marketid)
        {
            int unseenCatalogs = [self unseenCatalogsForMarket:marketForIndexPath];
            AAAMarketCollectionViewCell* cell = (AAAMarketCollectionViewCell*) [marketViewsCollectionView cellForItemAtIndexPath:cellIndexPath];
            [cell tryDecrementUnseenCatalogs:unseenCatalogs];
//            [cell setUnseenCatalogs:unseenCatalogs];
            break;
        }
    }
}

-(int) unseenCatalogsForMarket:(AAAMarket*) market
{
    int unseenCatalogs = 0;
    NSArray* seenCatalogsForThisMarket = [seenCatalogs objectForKey:@(market.identifier)];
    if (!seenCatalogsForThisMarket) {
        return (int)market.catalogs.count;
    }
    for (AAACatalog* catalog in market.catalogs)
    {
        if (![seenCatalogsForThisMarket containsObject:@(catalog.identifier)]) {
            unseenCatalogs++;
        }
    }
    return unseenCatalogs;
}

-(BOOL) isCatalogSeen:(int) catalogId forMarketId:(int) marketId
{
    NSMutableArray* seenCatalogsForThisMarket = [seenCatalogs objectForKey:@(marketId)];
    return seenCatalogsForThisMarket && [seenCatalogsForThisMarket containsObject:@(catalogId)];
}

-(void) setCatalogIdAsSeen:(int) catalogId forMarket:(int) marketId
{
    NSMutableArray* seenCatalogsForThisMarket = [seenCatalogs objectForKey:@(marketId)];
    if (!seenCatalogsForThisMarket)
    {
        seenCatalogsForThisMarket = [NSMutableArray array];
    }
    if (![seenCatalogsForThisMarket containsObject:@(catalogId)])
    {
        [seenCatalogsForThisMarket addObject:@(catalogId)];
        _seenCatalogsDirty = YES;
    }
    [seenCatalogs setObject:seenCatalogsForThisMarket forKey:@(marketId)];
}

-(void)trySaveSeenCatalogs
{
    if (!_seenCatalogsDirty) {
        return;
    }
    
    //save the settings
    NSData* seenCatalogsData = [NSKeyedArchiver archivedDataWithRootObject:seenCatalogs];
    [[NSUserDefaults standardUserDefaults] setObject:seenCatalogsData forKey:kSeenDictionaryUserDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    _seenCatalogsDirty = YES;
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
    }];
    [self showNextTutorialView];
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
        [catalogVC setCatalog:catalog seen:[self isCatalogSeen:catalog.identifier forMarketId:currentShowingMarket.identifier]];
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
    [Flurry logEvent:FlurryEventCatalogOpened withParameters:@{FlurryParameterCatalogId : [NSString stringWithFormat:@"%i",catalog.identifier],
                                                          FlurryParameterCatalogIndex : [NSString stringWithFormat:@"%li", (long)index],
                                                          FlurryParameterCatalogPriority : [NSString stringWithFormat:@"%f", catalog.priority],
                                                        FlurryParameterMarketName : currentShowingMarket.name}];
    [[AAATutorialManager instance] invalidateTutorialView:TutorialViewTapOnCatalog];
    
    [self seenCatalog:catalog.identifier forMarket:currentShowingMarket.identifier];
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
    if ([scrollView isKindOfClass:[UICollectionView class]] && !_isInEditMode && scrollView.isDragging) {
        [[AAATutorialManager instance] invalidateTutorialView:TutorialViewDiscoverMarkets];
        [[AAATutorialManager instance] showTutorialView:TutorialViewTapOnMarket];
    }
}

#pragma mark - UICOllectionView Datasource & Delegate

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _isInEditMode ? (markets ? markets.count : 0) : (enabledMarkets ? enabledMarkets.count : 0);
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    AAAMarketCollectionViewCell* selectedCell = (AAAMarketCollectionViewCell*)[collectionView cellForItemAtIndexPath:indexPath];
    void(^selectCurrentCell)(void);
    selectCurrentCell = ^{
        currentShowingMarket = enabledMarkets[indexPath.row]; //it should not be possible to select cells in normal mode, only during edit
        [self setTheCatalogsForMarket:currentShowingMarket];
//        [self setMarketViewAsSelected:selectedCell];
        [collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
        
        //handle tutorial
        if (!_isInEditMode && selectedCell.isSelected) {
            [[AAATutorialManager instance] invalidateTutorialView:TutorialViewTapOnMarket];
            [self showNextTutorialView];
        }
    };
    
    if(_isInEditMode)
    {
        [self changeEditMenuStateToClosed:YES onCompletion:^{
            selectCurrentCell();
        }];
        return;
    }
    
    if (currentShowingMarket.identifier != selectedCell.market.identifier) {
        selectCurrentCell();
    }
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    AAAMarketCollectionViewCell* cell = (AAAMarketCollectionViewCell*)[collectionView dequeueReusableCellWithReuseIdentifier:kMarketCellReuseIdentifier forIndexPath:indexPath];
    AAAMarket* market = (AAAMarket*) (_isInEditMode ? markets[indexPath.row] : enabledMarkets[indexPath.row]);
    [cell enableAddRemoveFeature:ENABLE_ADD_REMOVE_MARKET];
    cell.isActive = [enabledMarketsUserDefaults objectForKey:@(market.identifier)] ? [[enabledMarketsUserDefaults objectForKey:@(market.identifier)] boolValue] : YES;
//    [cell onSelected:^(AAAMarket* _market) {
//        [self changeEditMenuStateToClosed:YES onCompletion:^{
//            [self selectMarketInCollectionView:_market];
//        }];
//    }];
//    [cell onActiveChanged:^(AAAMarketCollectionViewCell *cell) {
//        BOOL thereIsAtLeastOneOtherActiveMarket = NO;
//        for (AAAMarket* mark in markets) {
//            if (![enabledMarketsUserDefaults objectForKey:@(mark.identifier)] || [[enabledMarketsUserDefaults objectForKey:@(mark.identifier)] boolValue]) {
//                if (mark.identifier != cell.market.identifier) {
//                    thereIsAtLeastOneOtherActiveMarket = YES;
//                    break;
//                }
//            }
//        }
//        if (thereIsAtLeastOneOtherActiveMarket) {
//            [enabledMarketsUserDefaults setObject:@(cell.isActive) forKey:@(market.identifier)];
//        }
//        else
//        {
//            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Atenție" message:@"Nu este posibil sa ascunzi toate marketurile!" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
//            [alert show];
//        }
//        return thereIsAtLeastOneOtherActiveMarket;
//    }];
    
    cell.market = market;
    [cell setupEditModeOn:_isInEditMode];
    [cell setUnseenCatalogs:[self unseenCatalogsForMarket:market]];
    [cell setSelected:[market isEqual:currentShowingMarket]];
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
        float collectionViewWidth = collectionView.bounds.size.width;
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
        return CGSizeMake(0.0f, 5.0f);
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

//#pragma mark - UIGestureRecognizer
//
//-(BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
//{
//    if ([gestureRecognizer.view isEqual:marketViewsCollectionView] && [gestureRecognizer isEqual:editMenuPanGesture]) {
//        CGPoint vel = [editMenuPanGesture velocityInView:self.view];
//        return abs(vel.y) >= 300;
//    }
//    return YES;
//}

@end
