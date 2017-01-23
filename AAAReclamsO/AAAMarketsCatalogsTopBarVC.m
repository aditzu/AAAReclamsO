//
//  AAAMarketsCatalogsTopBarVC.m
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 15/10/15.
//  Copyright © 2015 Adrian Ancuta. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AAAMarketsCatalogsTopBarVC.h"
#import "Flurry.h"
#import "AAAGlobals.h"
#import "AAAAds.h"

@interface AAAMarketsCatalogsTopBarVC()
{
    __weak IBOutlet UIView *topBarBusyView;
    __weak IBOutlet UIButton *likeFbButton;
    __weak IBOutlet UIButton *buyNoAdsButton;
    __weak IBOutlet UIButton *restorePurchasesButton;
    __weak IBOutlet NSLayoutConstraint *topBarPurchasablesFBWidthConstraint;
    __weak IBOutlet UIView *topBar;
}
- (IBAction)buyAdsBtnPressed:(UIButton*)sender;
- (IBAction)restorePurchases:(UIButton*)sender;
- (IBAction)likeFb :(UIButton*)sender;
@end


@implementation AAAMarketsCatalogsTopBarVC

int const kTopBarButtonWidth=30;
int const kTopBarButtonMargin=15;
int const kTopBarButtonSpacing=10;
NSString* const kHasLikedFacebookKey = @"hasLikedFb";

-(void)viewDidLoad
{
    [super viewDidLoad];
    topBarBusyView.layer.cornerRadius = 5.0f;
    [[AAAPurchasesHandler instance] addDelegate:self];
    
    if (![AAAPurchasesHandler hasAdsEnabled]) {
        [[AAAGlobals sharedInstance].ads disable];
    }
    [self resetTopbar];
}


-(void) resetTopbar
{
    int numberOfButtons=3;
    if (![AAAPurchasesHandler hasAdsEnabled]) {
        numberOfButtons-=2;
        restorePurchasesButton.hidden = YES;
        buyNoAdsButton.hidden = YES;
    }
    BOOL hasLikedFB = [[NSUserDefaults standardUserDefaults] boolForKey:kHasLikedFacebookKey];
    if (hasLikedFB) {
        likeFbButton.hidden = YES;
        numberOfButtons--;
    }
    if(numberOfButtons > 0)
    {
        int width = kTopBarButtonMargin*2 + (numberOfButtons - 1) * kTopBarButtonSpacing + numberOfButtons*kTopBarButtonWidth;
        topBarPurchasablesFBWidthConstraint.constant = width;
        [topBar layoutIfNeeded];
    }
    else
    {
        [topBar removeFromSuperview];
    }
}

#pragma mark - Actions

-(void)buyAdsBtnPressed:(UIButton *)sender
{
    [Flurry logEvent:FlurryEventDidTryToBuyNoAds];
    topBarBusyView.hidden = NO;
    [[AAAPurchasesHandler instance] purchaseNoads];
}

-(void) restorePurchases:(UIButton *)sender
{
    [Flurry logEvent:FlurryEventDidTryToRestore];
    topBarBusyView.hidden = NO;
    [[AAAPurchasesHandler instance] restorePurchases];
}

-(void)likeFb:(UIButton *)sender
{
    NSUserDefaults *userdef = [NSUserDefaults standardUserDefaults];
    [userdef setBool:YES forKey:kHasLikedFacebookKey];
    [userdef synchronize];
    
    UIApplication *app = [UIApplication sharedApplication];
    NSURL *fbAppUrl = [NSURL URLWithString:[[AAAGlobals sharedInstance] fbPageURLOpenApp]];
    if ([app canOpenURL:fbAppUrl]) {
        [app openURL:fbAppUrl];
    }
    else
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[AAAGlobals sharedInstance].fbPageURLOpenSafari]];
    }
    [self resetTopbar];
    [Flurry logEvent:FlurryEventDidPressLikePage];
}

#pragma mark - AAAPurchasesDelegate

-(void) showAlertWithTitle:(NSString *) alertTitle message: (NSString *) alertMessage cancelButtonText: (NSString *) cancelBtnText
{
    UIAlertController *alertCtrl = [UIAlertController alertControllerWithTitle:alertTitle message:alertMessage preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okButton = [UIAlertAction actionWithTitle:cancelBtnText style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [alertCtrl dismissViewControllerAnimated:YES completion:nil];
    }];
    [alertCtrl addAction:okButton];
    [self presentViewController:alertCtrl animated:YES completion:nil];
}

-(void)purchaseSuccesfully:(NSString *)productId
{
    topBarBusyView.hidden =YES;
    [[AAAGlobals sharedInstance].ads disable];
    [self showAlertWithTitle:@"Felicitări" message:@"Felicitări! Reclamele au fost dezactivate pentru telefonul tău." cancelButtonText:@"Ok"];
    [Flurry logEvent:FlurryEventDidBuyNoAds];
    [self resetTopbar];
}

-(void)purchaseFailed:(NSString *)productId withError:(NSError *)error
{
    topBarBusyView.hidden =YES;
    [self showAlertWithTitle:@"Eroare!" message:@"Aplicația nu se poate conecta la iTunes Store. Încearcă mai târziu!" cancelButtonText:@"Ok"];
}

-(void)restoreFinishedForProductWithId:(NSString *)productId withError:(NSError *)error
{
    topBarBusyView.hidden =YES;
    if(error)
    {
        [self showAlertWithTitle:@"Eroare!" message:@"Aplicația nu se poate conecta la iTunes Store. Încearcă mai târziu!" cancelButtonText:@"Ok"];
    }
    else if([AAAPurchasesHandler hasAdsEnabled])
    {
        [self showAlertWithTitle:@"iTunes Store" message:@"Nu a fost nimic de restituit." cancelButtonText:@"Ok"];
    }
    else
    {
        [[AAAGlobals sharedInstance].ads disable];
        [self showAlertWithTitle:@"Felicitări!" message:@"Reclamele au fost dezactivate pentru telefonul tău." cancelButtonText:@"Ok"];
        [Flurry logEvent:FlurryEventDidRestore];
        [self resetTopbar];
    }
}

@end
