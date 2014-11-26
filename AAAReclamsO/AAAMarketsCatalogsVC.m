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
#import <QuartzCore/QuartzCore.h>

@interface AAAMarketsCatalogsVC()
{
    NSMutableArray* markets;
    IBOutlet UIScrollView* marketsScrollView;
    IBOutlet UIScrollView* catalogsScrollView;
    
    AAAMarket* currentShowingMarket;
    NSMutableArray* currentShowingCatalogs;
    UIView* containerViewOfShownCatalog;
    
    AAAwww* www;
    UIView* currentShownMarketView;
    NSMutableArray* marketViews;
    
    CGRect catalogViewMaxFrame;
}
@end

@implementation AAAMarketsCatalogsVC

const static float DisabledMarketViewTransparency = 0.65f;

-(void)viewDidLoad
{
    [super viewDidLoad];
    marketViews = [NSMutableArray array];
    www = [AAAwww instance];
    [JMImageCache sharedCache].countLimit = 500;
//    marketsScrollView.delegate = self;
    catalogsScrollView.delegate = self;
//    [[JMImageCache sharedCache] removeAllObjects];
    
    markets = [NSMutableArray array];
    [www downloadCatalogInformationsWithCompletionHandler:^(NSArray *catalogs, NSError *error) {
        for (AAACatalog* catalog in catalogs)
        {
            if (![markets containsObject:catalog.market]) {
                [markets addObject:catalog.market];
            }
            [markets enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                AAAMarket* mark = (AAAMarket*)obj;
                if (mark.identifier == catalog.market.identifier) {
                    [mark.catalogs addObject:catalog];
                }
            }];
//            [catalog.market.catalogs addObject:catalog];///auuuu retain circle
        }
        [self addTheMarkets];
        if (markets.count>0) {
            currentShowingMarket = markets[0];
            [self setTheCatalogsForMarket:currentShowingMarket];
            [self setMarketViewAsSelected:marketViews[0]];
            [self arrangeViews:currentShowingCatalogs inScrollView:catalogsScrollView];
        }
        [self addTapGestureRecognizerToScrollView];
    }];
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
//        marketViewMaxFrame = marketView.frame;//temp
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
        UIView* containerView = [[UIView alloc] initWithFrame:CGRectMake(i * viewSize.width + (border * (.5 * i + 1)), border/2, viewSize.width, viewSize.height)];
        catalogViewMaxFrame = containerView.frame;
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
    [self arrangeViews:currentShowingCatalogs inScrollView:scrollView];
}

-(void) arrangeViews:(NSArray*)views inScrollView:(UIScrollView*) scrollView
{
    int sizeScaleDif = 100;
    int centerOffsetNoEffect = 20;
    int angleOffset = 20;
    for (AAACatalogVC* scrollViewCatalog in views) {
        int i = [views indexOfObject:scrollViewCatalog];
        
        UIView* scrollViewSubview = scrollViewCatalog.view.superview;
        CGRect subviewFrameInMyView = CGRectMake(scrollViewSubview.frame.origin.x - scrollView.contentOffset.x, scrollViewSubview.frame.origin.y, scrollViewSubview.frame.size.width, scrollViewSubview.frame.size.height);
        float pixelsFromCenter = scrollView.bounds.size.width / 2 - (subviewFrameInMyView.origin.x + subviewFrameInMyView.size.width/2);
        BOOL isInLeft = pixelsFromCenter < 0;
        float distanceFromCenter = fabs(pixelsFromCenter);
        distanceFromCenter -= centerOffsetNoEffect;
        if (distanceFromCenter>0.001f) {
            float percentage = (100* (distanceFromCenter))/(scrollView.bounds.size.width/2 - centerOffsetNoEffect);
//            NSLog(@"PERCENTAGE: %f ----- %i + %@", percentage, i, NSStringFromCGRect(subviewFrameInMyView));
            float pixels = sizeScaleDif/100.0f*percentage;
//            CGRect toBeFrame = CGRectMake(scrollViewSubview.center.x - catalogViewMaxFrame.size.width/2, scrollViewSubview.center.y - catalogViewMaxFrame.size.height/2, catalogViewMaxFrame.size.width, catalogViewMaxFrame.size.height);
            CGRect toBeFrame = scrollViewSubview.frame;
//            toBeFrame.origin.x += pixels;
//            toBeFrame.origin.y += pixels;
            toBeFrame.size.width -= pixels*2;
            toBeFrame.size.height -= pixels*2;
            scrollViewSubview.frame = toBeFrame;
//            scrollViewSubview.clipsToBounds = YES;
            
            float angle = angleOffset/100.0f*percentage;
            angle = isInLeft ? angle : -angle;
            CATransform3D rotationAndPerspectiveTransform = CATransform3DIdentity;
            rotationAndPerspectiveTransform.m34 = 1.0 / -500;
            rotationAndPerspectiveTransform = CATransform3DRotate(rotationAndPerspectiveTransform, angle * M_PI / 180.0f, 0.0f, 1.0f, 0.0f);
            
            float initialX = scrollViewSubview.frame.origin.x;
            scrollViewSubview.layer.transform = rotationAndPerspectiveTransform;
            CGRect newFrame = scrollViewSubview.frame;
            newFrame.origin.x = initialX;
//            scrollViewSubview.frame = newFrame;
        }
    }
}

@end
