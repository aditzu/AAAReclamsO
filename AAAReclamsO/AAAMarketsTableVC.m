//
//  FirstViewController.m
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 10/11/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import "AAAMarketsTableVC.h"
#import "AAACatalog.h"
#import "AAAMarket.h"

@interface AAAMarketsTableVC ()
{
    NSMutableArray* markets;
    IBOutlet UIView* containerView;
    
    CGRect catalogThumbnailFrame;
    AAAMarketTableViewCell* lastSelectedCell;
}
@end

@implementation AAAMarketsTableVC

- (void)viewDidLoad {
    [super viewDidLoad];
    markets = [[NSMutableArray alloc] init];
    
    NSArray* coraImgs = @[@"cora-01 11:17:2014.jpeg",@"cora 2-02 11:17:2014.jpeg",@"cora 3-03 11:17:2014.jpeg",@"cora 4-04 11:17:2014.jpeg", @"cora 5-05 11:17:2014.jpeg", @"cora 6-06 11:17:2014.jpeg", @"cora 7-07 11:17:2014.jpeg"];
    AAACatalog* justACatalog = [AAACatalog catalogWithCover:[UIImage imageNamed:@"catalog_cover.png"] andImageUrls:coraImgs];
    AAAMarket* coraMarket = [AAAMarket marketWithName:@"Cora" andLogoImage:[UIImage imageNamed:@"cora_logo_squared.jpeg"]];
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
    
    AAAMarket* carrefourMarket = [AAAMarket marketWithName:@"Carrefour" andLogoImage:[UIImage imageNamed:@"carrefour_logo_squared.jpeg"]];
    [carrefourMarket.catalogs addObject:justACatalog];
    [carrefourMarket.catalogs addObject:justACatalog];
    [markets addObject:carrefourMarket];
    
    AAAMarket* kauflandMarket = [AAAMarket marketWithName:@"Kaufland" andLogoImage:[UIImage imageNamed:@"kaufland_logo_squared.jpg"]];
    [kauflandMarket.catalogs addObject:justACatalog];
    [markets addObject:kauflandMarket];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return markets.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 20;
}

-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section
{
    return 20;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AAAMarketTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"marketCell" forIndexPath:indexPath];
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

-(void)needToShowCatalogVC:(AAACatalogVC*) catalogVC forMarketCell:(AAAMarketTableViewCell *)marketCell
{
    lastSelectedCell = marketCell;
    CGRect frameInSuperview = [self.view convertRect:catalogVC.view.superview.frame fromView:catalogVC.view.superview.superview];
    [catalogVC.view removeFromSuperview];
    catalogVC.view.frame = frameInSuperview;
    catalogThumbnailFrame = frameInSuperview;
    [containerView addSubview:catalogVC.view];
    [UIView animateWithDuration:.4f animations:^{
        catalogVC.view.transform = CGAffineTransformIdentity;
        catalogVC.view.frame = containerView.bounds;
    }];
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
}

@end
