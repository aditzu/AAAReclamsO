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
#import "LEColorPicker.h"


@interface AAAMarketsCatalogsVC()
{
    NSMutableArray* markets;
    IBOutlet UIScrollView* marketsScrollView;
    IBOutlet UIScrollView* catalogsScrollView;
    
    IBOutlet UIImageView* testImag;
    
    AAAMarket* currentShowingMarket;
    NSMutableArray* currentShowingCatalogs;
    UIView* containerViewOfShownCatalog;
    
    AAAwww* www;
    UIView* currentShownMarketView;
    NSMutableArray* marketViews;
    
    CGRect marketViewMaxFrame;
}
@end

@implementation AAAMarketsCatalogsVC

-(void)viewDidLoad
{
    [super viewDidLoad];
    marketViews = [NSMutableArray array];
    www = [AAAwww instance];
    [JMImageCache sharedCache].countLimit = 500;
    
//    LEColorPicker* colorPicker = [[LEColorPicker alloc] init];
//    LEColorScheme* colorScheme = [colorPicker colorSchemeFromImage:[UIImage imageNamed:@"metro_logo_squared.jpg"]];
//    NSLog(@"primaryCOlor:%@", colorScheme.primaryTextColor);
//    NSLog(@"secondaryTextColor:%@", colorScheme.secondaryTextColor);
//    NSLog(@"backgroundColor:%@", colorScheme.backgroundColor);
//    
//    CAGradientLayer* gradient = [CAGradientLayer layer];
//    gradient.frame = catalogsScrollView.bounds;
//    gradient.colors = @[ (id)colorScheme.backgroundColor.CGColor, (id)colorScheme.primaryTextColor.CGColor];
//    gradient.allowsEdgeAntialiasing = YES;
//    gradient.drawsAsynchronously=YES;
//    gradient.magnificationFilter = kCAFilterTrilinear;
//    gradient.opacity = .5f;
//    [catalogsScrollView.layer insertSublayer:gradient atIndex:0];
    
    marketsScrollView.delegate = self;
    
//    [[JMImageCache sharedCache] removeAllObjects];
    
    markets = [NSMutableArray array];
    [www downloadCatalogInformationsWithCompletionHandler:^(NSArray *catalogs, NSError *error) {
        for (AAACatalog* catalog in catalogs)
        {
            if (![markets containsObject:catalog.market]) {
                [markets addObject:catalog.market];
            }
            [catalog.market.catalogs addObject:catalog];///auuuu retain circle
        }
        [self addTheMarkets];
        [self arrangeViews:marketViews inScrollView:marketsScrollView];
        if (markets.count>0) {
            currentShowingMarket = markets[0];
            [self setTheCatalogsForMarket:currentShowingMarket];
            [self setMarketViewAsSelected:marketViews[0]];
        }
        [self addTapGestureRecognizerToScrollView];
    }];
}


-(void) addTheMarkets
{
    int border = 10;
    int side = marketsScrollView.bounds.size.height;
    CGSize viewSize = CGSizeMake(side, side);
    for (int i =0; i < markets.count; i++)
    {
        AAAMarket* market = markets[i];
        float viewFinalWidth = viewSize.width - (border*2);
        float viewFinalHeight = viewFinalWidth;
        float viewX = i * viewSize.width + border + marketsScrollView.bounds.size.width/2 - viewSize.width/2;

        UIView* marketView = [[UIView alloc] initWithFrame:CGRectMake(viewX, border, viewFinalWidth, viewFinalHeight)];
        marketViewMaxFrame = marketView.frame;//temp
        UIButton* btn = [[UIButton alloc] initWithFrame:marketView.bounds];
        [btn setBackgroundColor:[UIColor grayColor]];
        
        [[JMImageCache sharedCache] imageForURL:[NSURL URLWithString:market.miniLogoURL] completionBlock:^(UIImage *image) {
            [btn setBackgroundImage:image forState:UIControlStateNormal];
        } failureBlock:^(NSURLRequest *request, NSURLResponse *response, NSError *error) {
            NSLog(@"JMIMageCache failed: %@", error);
        }];
        
        btn.tag = i;
        [btn addTarget:self action:@selector(marketButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [marketView addSubview:btn];
        [marketsScrollView addSubview:marketView];
        marketsScrollView.contentSize = CGSizeMake(marketView.frame.origin.x + marketView.frame.size.width + border + marketsScrollView.bounds.size.width/2 - viewSize.width/2, viewSize.height);
        [marketViews addObject:marketView];
    }
}

-(void) marketButtonClicked:(UIButton*) btn
{
    if ([currentShownMarketView isEqual:btn]) {
        return;
    }
    currentShowingMarket = markets[btn.tag];
    [self setTheCatalogsForMarket:currentShowingMarket];
    [self setMarketViewAsSelected:btn];
}

-(void) setMarketViewAsSelected:(UIView*) btn
{
    int scaleDiff = 5;
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
        }
        btn.frame = newMarketBtnFrame;
    } completion:^(BOOL finished) {
        currentShownMarketView = btn;
    }];
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
        CGRect catalogVCFrame = catalogVC.view.frame;
//        catalogVCFrame.size.height = 519;//hardcoded, it is not loaded here yet. it's 568
        CGSize scaleSize = CGSizeMake(containerView.frame.size.width/catalogVCFrame.size.width, containerView.frame.size.height/catalogVCFrame.size.height);
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

#pragma mark - UIScrollViewDelegate

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self arrangeViews:marketViews inScrollView:scrollView];
}

-(void) arrangeViews:(NSArray*)views inScrollView:(UIScrollView*) scrollView
{
    int dif = 10;
    int centerOffsetNoEffect = 50;
    int angleOffset = 60;
    for (UIView* scrollViewSubview in views) {
        CGRect subviewFrameInMyView = CGRectMake(scrollViewSubview.frame.origin.x - scrollView.contentOffset.x, scrollViewSubview.frame.origin.y, scrollViewSubview.frame.size.width, scrollViewSubview.frame.size.height);
        [self.view convertRect:scrollViewSubview.frame fromView:scrollView];
        float pixelsFromCenter = scrollView.bounds.size.width / 2 - (subviewFrameInMyView.origin.x + subviewFrameInMyView.size.width/2);
        BOOL isInLeft = pixelsFromCenter < 0;
        float distanceFromCenter = fabs(pixelsFromCenter);
        distanceFromCenter -= centerOffsetNoEffect;
        if (distanceFromCenter>0) {
            float percentage = (100* (distanceFromCenter))/(scrollView.bounds.size.width/2 - centerOffsetNoEffect);
            float pixels = dif/100.0f*percentage;
            CGRect toBeFrame = CGRectMake(scrollViewSubview.center.x - marketViewMaxFrame.size.width/2, scrollViewSubview.center.y - marketViewMaxFrame.size.height/2, marketViewMaxFrame.size.width, marketViewMaxFrame.size.height);
            toBeFrame.origin.x += pixels;
            toBeFrame.origin.y += pixels;
            toBeFrame.size.width -= pixels*2;
            toBeFrame.size.height -= pixels*2;
            scrollViewSubview.frame = toBeFrame;
//            scrollViewSubview.clipsToBounds = YES;
            
            float angle = angleOffset/100.0f*percentage;
            angle = isInLeft ? angle : -angle;
            CATransform3D rotationAndPerspectiveTransform = CATransform3DIdentity;
            rotationAndPerspectiveTransform.m34 = 1.0 / -500;
            rotationAndPerspectiveTransform = CATransform3DRotate(rotationAndPerspectiveTransform, angle * M_PI / 180.0f, 0.0f, 1.0f, 0.0f);
            scrollViewSubview.layer.transform = rotationAndPerspectiveTransform;
        }
    }
}

@end
