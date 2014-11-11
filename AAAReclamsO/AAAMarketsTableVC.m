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
#import "AAAMarketTableViewCell.h"

@interface AAAMarketsTableVC ()
{
    NSMutableArray* markets;
}
@end

@implementation AAAMarketsTableVC

- (void)viewDidLoad {
    [super viewDidLoad];
    markets = [[NSMutableArray alloc] init];
    
    AAACatalog* justACatalog = [AAACatalog catalogWithCover:[UIImage imageNamed:@"catalog_cover.png"]];
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


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AAAMarketTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"marketCell" forIndexPath:indexPath];
    [cell setMarket:markets[indexPath.row]];
    return cell;
}

@end
