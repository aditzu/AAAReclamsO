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

@interface AAAMarketsCatalogsVC()
{
    NSMutableArray* markets;
    IBOutlet UIScrollView* marketsScrollView;
    IBOutlet UIScrollView* catalogsScrollView;
    
    AAAMarket* currentShowingMarket;
    NSMutableArray* currentShowingCatalogs;
    UIView* containerViewOfShownCatalog;
}
@end

@implementation AAAMarketsCatalogsVC

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    markets = [NSMutableArray array];
    NSArray* coraImgs = @[@"cora-01 11:17:2014.jpeg",@"cora 2-02 11:17:2014.jpeg",@"cora 3-03 11:17:2014.jpeg",@"cora 4-04 11:17:2014.jpeg", @"cora 5-05 11:17:2014.jpeg", @"cora 6-06 11:17:2014.jpeg", @"cora 7-07 11:17:2014.jpeg"];
    AAACatalog* coraCatalog = [AAACatalog catalogWithCover:[UIImage imageNamed:@"cora-01 11:17:2014.jpeg"] andImageUrls:coraImgs];
    AAAMarket* coraMarket = [AAAMarket marketWithName:@"Cora" andLogoImage:[UIImage imageNamed:@"cora_logo_squared.jpeg"]];
    coraMarket.imgLogoLandscape = [UIImage imageNamed:@"cora_logo_horizontal.png"];
    [coraMarket.catalogs addObject:coraCatalog];
    [coraMarket.catalogs addObject:coraCatalog];
    [coraMarket.catalogs addObject:coraCatalog];
    [coraMarket.catalogs addObject:coraCatalog];
    [coraMarket.catalogs addObject:coraCatalog];
    [coraMarket.catalogs addObject:coraCatalog];
    [coraMarket.catalogs addObject:coraCatalog];
    [coraMarket.catalogs addObject:coraCatalog];
    [coraMarket.catalogs addObject:coraCatalog];
    [markets addObject:coraMarket];
    
    NSArray* carrefourImgs = @[@"carrefour-01 11:17:2014.jpeg", @"carrefour 2-02 11:17:2014.jpeg", @"carrefour 3-03 11:17:2014.jpeg", @"carrefour 4-04 11:17:2014.jpeg", @"carrefour 5-05 11:17:2014.jpeg", @"carrefour 6-06 11:17:2014.jpeg", @"carrefour 7-07 11:17:2014.jpeg"];
    
    AAAMarket* carrefourMarket = [AAAMarket marketWithName:@"Carrefour" andLogoImage:[UIImage imageNamed:@"carrefour_logo_squared.jpeg"]];
    carrefourMarket.imgLogoLandscape = [UIImage imageNamed:@"carrefour_logo_horizontal.png"];
    AAACatalog* carrefourCatalog = [AAACatalog catalogWithCover:[UIImage imageNamed:@"carrefour-01 11:17:2014.jpeg"] andImageUrls:carrefourImgs];
    [carrefourMarket.catalogs addObject:carrefourCatalog];
    [carrefourMarket.catalogs addObject:carrefourCatalog];
    [markets addObject:carrefourMarket];
    
    NSArray* kauflandImags = @[@"kaufland 225-01 11:17:2014.jpeg", @"kaufland 226-02 11:17:2014.jpeg", @"kaufland 227-03 11:17:2014.jpeg", @"kaufland 228-04 11:17:2014.jpeg", @"kaufland 229-05 11:17:2014.jpeg", @"kaufland 230-06 11:17:2014.jpeg", @"kaufland 231-07 11:17:2014.jpeg"];
    
    AAAMarket* kauflandMarket = [AAAMarket marketWithName:@"Kaufland" andLogoImage:[UIImage imageNamed:@"kaufland_logo_squared.jpg"]];
    kauflandMarket.imgLogoLandscape = [UIImage imageNamed:@"kaufland_logo_horizontal.png"];
    AAACatalog* kauflandCatalog = [AAACatalog catalogWithCover:[UIImage imageNamed:@"kaufland 225-01 11:17:2014.jpeg"] andImageUrls:kauflandImags];
    [kauflandMarket.catalogs addObject:kauflandCatalog];
    [markets addObject:kauflandMarket];
    [markets addObject:kauflandMarket];
    [markets addObject:kauflandMarket];
    
    [self addTheMarkets];
    currentShowingMarket = markets[0];
    [self setTheCatalogsForMarket:currentShowingMarket];
    [self addTapGestureRecognizerToScrollView];
    
    [[AAAJsObjCBridge instance] addDelegate:self];
    [[AAAJsObjCBridge instance] registerForFunctionCallbackWithSelector:@selector(callbackFromJS:)];
//    [[AAAJsObjCBridge instance] callJsFunction:@"getMarkets" withArguments:@[] onGlobalObject:@"marks"];
//    [[AAAJsObjCBridge instance] callJsFunction:@"getMarkets" withParams:@[]];
}

-(void) callbackFromJS:(NSString*) data
{
    
}

-(void) addTheMarkets
{
    int border = 5;
    int side = marketsScrollView.bounds.size.height;
    CGSize viewSize = CGSizeMake(side, side);
    for (int i =0; i < markets.count; i++)
    {
        AAAMarket* market = markets[i];
        UIView* marketView = [[UIView alloc] initWithFrame:CGRectMake(i * viewSize.width + border, border, viewSize.width - (border*2), viewSize.height - (border*2))];
        UIButton* btn = [[UIButton alloc] initWithFrame:marketView.bounds];
        [btn setBackgroundColor:[UIColor grayColor]];
        [btn setBackgroundImage:market.imgLogo forState:UIControlStateNormal];
        btn.tag = i;
        [btn addTarget:self action:@selector(marketButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [marketView addSubview:btn];
        [marketsScrollView addSubview:marketView];
        marketsScrollView.contentSize = CGSizeMake(marketView.frame.origin.x + marketView.frame.size.width + border, viewSize.height);
    }
}

-(void) marketButtonClicked:(UIButton*) btn
{
    currentShowingMarket = markets[btn.tag];
    [self setTheCatalogsForMarket:currentShowingMarket];
}

-(void) setTheCatalogsForMarket:(AAAMarket*) market
{
    int catalogSubviewTag = 21341;
    int border = 20;
    CGSize viewSize = CGSizeMake(catalogsScrollView.bounds.size.width - (2*border), catalogsScrollView.bounds.size.height - border);
    for (UIView* subview in catalogsScrollView.subviews) {
        if (subview.tag == catalogSubviewTag)
        {
            [subview removeFromSuperview];
        }
    }
    currentShowingCatalogs = [NSMutableArray array];
    for (int i=0; i < market.catalogs.count; i++)
    {
        AAACatalog* catalog = market.catalogs[i];
        AAACatalogVC* catalogVC = [self.storyboard instantiateViewControllerWithIdentifier:@"catalogVC"];
        catalogVC.catalog = catalog;
        UIView* containerView = [[UIView alloc] initWithFrame:CGRectMake(i * viewSize.width + (border * (2 * i + 1)), border/2, viewSize.width, viewSize.height)];
        CGSize scaleSize = CGSizeMake(containerView.frame.size.width/catalogVC.view.frame.size.width, containerView.frame.size.height/catalogVC.view.frame.size.height);
        catalogVC.view.transform = CGAffineTransformScale(CGAffineTransformIdentity, scaleSize.width, scaleSize.height);
        catalogVC.view.frame = containerView.bounds;
        [containerView addSubview:catalogVC.view];
        containerView.tag = catalogSubviewTag;
        [catalogVC setDelegate:self];
        [currentShowingCatalogs addObject:catalogVC];
        [catalogsScrollView addSubview:containerView];
        catalogsScrollView.contentSize = CGSizeMake(containerView.frame.origin.x + containerView.frame.size.width + border, containerView.frame.size.height);
    }
}

-(void) addTapGestureRecognizerToScrollView
{
    UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(scrollViewTapped:)];
    [catalogsScrollView addGestureRecognizer:tapGesture];
}

-(void)scrollViewTapped:(UITapGestureRecognizer*) tapGesture
{
    int catalogIndex = (int)catalogsScrollView.contentOffset.x/catalogsScrollView.bounds.size.width;
    AAACatalogVC* catalogVC = currentShowingCatalogs[catalogIndex];
    containerViewOfShownCatalog = catalogVC.view.superview;
    [catalogVC maximize];
    CGRect initialFrame = [self.view convertRect:catalogVC.view.frame fromView:catalogVC.view.superview];
    catalogVC.view.frame = initialFrame;
    [self.view addSubview:catalogVC.view];
    
    CGRect myBounds = self.view.bounds;
//    myBounds.size.height -= self.tabBarController.tabBar.frame.size.height;
    [UIView animateWithDuration:.4f animations:^{
        catalogVC.view.transform = CGAffineTransformIdentity;
        catalogVC.view.frame = myBounds;
    }];
    tapGesture.enabled = NO;
}

#pragma mark - AAAEvents

-(void)closeCatalogVC:(AAACatalogVC *)catalogVC
{
    
        [[AAAJsObjCBridge instance] callJsFunction:@"getMarkets" withParams:@[]];
    for (UITapGestureRecognizer* tapGesture in catalogsScrollView.gestureRecognizers) {
        tapGesture.enabled = YES;
    }
    CGRect toFrame = [self.view convertRect:containerViewOfShownCatalog.frame fromView:catalogsScrollView];
    CGSize scaleSize = CGSizeMake(containerViewOfShownCatalog.frame.size.width/catalogVC.view.frame.size.width, containerViewOfShownCatalog.frame.size.height/catalogVC.view.frame.size.height);
    [UIView animateWithDuration:.4f animations:^{
        catalogVC.view.transform = CGAffineTransformScale(CGAffineTransformIdentity, scaleSize.width, scaleSize.height);
            catalogVC.view.frame = toFrame;
    } completion:^(BOOL finished) {
        catalogVC.view.frame = containerViewOfShownCatalog.bounds;
        [containerViewOfShownCatalog addSubview:catalogVC.view];
    }];
}

@end