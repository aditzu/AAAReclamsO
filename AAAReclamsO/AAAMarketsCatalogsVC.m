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
#import <QuartzCore/QuartzCore.h>

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
}
@end

@implementation AAAMarketsCatalogsVC

const static float DisabledMarketViewTransparency = 0.65f;

-(void)viewDidLoad
{
    [super viewDidLoad];
    marketViews = [NSMutableArray array];
    www = [AAAwww instance];
    [JMImageCache sharedCache].countLimit = 200;
    carousel.type = iCarouselTypeRotary;
    carousel.scrollSpeed = .4f;
    carousel.decelerationRate = 0.5f;
    carousel.perspective = -0.7/500;
    
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
                    [mark.catalogs addObject:catalog];//auuuu retain circle
                }
            }];
        }
        [self addTheMarkets];
        if (markets.count>0) {
            currentShowingMarket = markets[0];
            [self setTheCatalogsForMarket:currentShowingMarket];
            [self setMarketViewAsSelected:marketViews[0]];
        }
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
    } completion:^(BOOL finished) {
        catalogVC.view.frame = containerViewOfShownCatalog.bounds;
        [containerViewOfShownCatalog addSubview:catalogVC.view];
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
    AAACatalog* catalog = currentShowingMarket.catalogs[index];
    AAACatalogVC* catalogVC = [self.storyboard instantiateViewControllerWithIdentifier:@"catalogVC"];
    [catalogVC view];
    catalogVC.catalog = catalog;
    UIView* containerView = [[UIView alloc] initWithFrame:CGRectMake(border, border/2, viewSize.width, viewSize.height)];
    catalogViewMaxFrame = containerView.frame;
    catalogVC.view.frame = containerView.bounds;
    [containerView addSubview:catalogVC.view];
    
    containerView.tag = catalogSubviewTag;
    [catalogVC setDelegate:self];
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
    } completion:^(BOOL finished) {
        [catalogVC finishedMaximized];
    }];
}

@end
