//
//  AAAMarketCollectionVC.m
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 15/11/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import "AAAMarketCollectionVC.h"
#import "AAAMarket.h"
#import "AAACatalog.h"

@interface AAAMarketCollectionVC()
{
    NSMutableArray* markets;
    IBOutlet UIView* containerView;
    
    CGRect catalogThumbnailFrame;
    AAAMarketCollectionViewCell* lastSelectedCell;
}

@end

@implementation AAAMarketCollectionVC

-(void)viewDidLoad
{
    [super viewDidLoad];
    markets = [[NSMutableArray alloc] init];
    
    NSArray* coraImgs = @[@"cora-01 11:17:2014.jpeg",@"cora 2-02 11:17:2014.jpeg",@"cora 3-03 11:17:2014.jpeg",@"cora 4-04 11:17:2014.jpeg", @"cora 5-05 11:17:2014.jpeg", @"cora 6-06 11:17:2014.jpeg", @"cora 7-07 11:17:2014.jpeg"];
    AAACatalog* justACatalog = [AAACatalog catalogWithCover:[UIImage imageNamed:@"catalog_cover.png"] andImageUrls:coraImgs];
    AAAMarket* coraMarket = [AAAMarket marketWithName:@"Cora" andLogoImage:[UIImage imageNamed:@"cora_logo_horizontal.png"]];
    [coraMarket.catalogs addObject:justACatalog];
    [coraMarket.catalogs addObject:justACatalog];
    [coraMarket.catalogs addObject:justACatalog];
    [coraMarket.catalogs addObject:justACatalog];
    [coraMarket.catalogs addObject:justACatalog];
    [coraMarket.catalogs addObject:justACatalog];
    [coraMarket.catalogs addObject:justACatalog];
    [coraMarket.catalogs addObject:justACatalog];
    [coraMarket.catalogs addObject:justACatalog];
    [markets addObject:coraMarket];
    
    AAAMarket* carrefourMarket = [AAAMarket marketWithName:@"Carrefour" andLogoImage:[UIImage imageNamed:@"carrefour_logo_horizontal.png"]];
    [carrefourMarket.catalogs addObject:justACatalog];
    [carrefourMarket.catalogs addObject:justACatalog];
    [markets addObject:carrefourMarket];
    
    AAAMarket* kauflandMarket = [AAAMarket marketWithName:@"Kaufland" andLogoImage:[UIImage imageNamed:@"kaufland_logo_horizontal.png"]];
    [kauflandMarket.catalogs addObject:justACatalog];
    [markets addObject:kauflandMarket];
        [markets addObject:kauflandMarket];
        [markets addObject:kauflandMarket];
    
    containerView.userInteractionEnabled = NO;
}

#pragma mark - COllectionViewDataSource

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return markets.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    AAAMarketCollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"collectionMarketCell"  forIndexPath:indexPath];
    NSMutableArray* catalogsVC = [NSMutableArray array];
    NSArray* catalogs = ((AAAMarket*)(markets[indexPath.row])).catalogs;
    for (int i =0; i < catalogs.count; i++) {
        AAACatalog* catalog = catalogs[i];
        AAACatalogVC* catalogVC = [self.storyboard instantiateViewControllerWithIdentifier:@"catalogVC"];
        [catalogVC setDelegate:self];
        [catalogVC setCatalog:catalog];
        catalogVC.view.tag = i;
        [catalogsVC addObject:catalogVC];
    }
    [cell setDelegate:self];
    [cell setMarket:markets[indexPath.row] withViewControllers:catalogsVC];
    return cell;
}

#pragma mark - AAAMarketTableViewCellEvents

-(void)needToShowCatalogVC:(AAACatalogVC*) catalogVC forMarketCell:(AAAMarketCollectionViewCell *)marketCell
{
    lastSelectedCell = marketCell;
    CGRect frameInSuperview = [containerView convertRect:[marketCell visibleCatalogFrameInCell] fromView:marketCell];
    catalogThumbnailFrame = frameInSuperview;
    catalogVC.view.frame = frameInSuperview;
    [containerView addSubview:catalogVC.view];
    [UIView animateWithDuration:.4f animations:^{
        catalogVC.view.transform = CGAffineTransformIdentity;
        catalogVC.view.frame = containerView.bounds;
    }];
    containerView.userInteractionEnabled = YES;
}

#pragma mark - AAACatalogVCEvents

-(void)closeCatalogVC:(AAACatalogVC *)catalogVC
{
    [UIView animateWithDuration:.4f animations:^{
        [lastSelectedCell scaleDownCatalog:catalogVC atIndex:catalogVC.view.tag];
        catalogVC.view.frame = catalogThumbnailFrame;
    } completion:^(BOOL finished) {
        [lastSelectedCell addCatalogVC:catalogVC atIndex:catalogVC.view.tag];
    }];
    containerView.userInteractionEnabled = NO;
}

@end
