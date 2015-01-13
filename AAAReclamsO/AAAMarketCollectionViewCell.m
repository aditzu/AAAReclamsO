//
//  AAAMarketCollectionViewCell.m
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 09/01/15.
//  Copyright (c) 2015 Adrian Ancuta. All rights reserved.
//

#import "AAAMarketCollectionViewCell.h"
#import <QuartzCore/QuartzCore.h>
#import "UIImageView+JMImageCache.h"
#import "JMImageCache.h"
#import "AAAGlobals.h"

@interface AAAMarketCollectionViewCell()
{
    onSelectedBlock _onSelected;
    onActiveChangeBlock _onActiveChange;
}

@property(nonatomic) BOOL isInEditMode;

@property (weak, nonatomic) IBOutlet UIButton *selectBtn;
@property (weak, nonatomic) IBOutlet UIButton *addRemoveBtn;
@property (weak, nonatomic) IBOutlet UIImageView *logoImgView;

- (IBAction)selectPressed:(UIButton *)sender;
- (IBAction)addRemovePressed:(UIButton *)sender;
@end

@implementation AAAMarketCollectionViewCell
const static float DisabledMarketViewTransparency = 0.65f;

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setSelected:NO];
    }
    return self;
}

-(void)setupEditModeOn:(BOOL)on
{
    self.isInEditMode = on;
    [self.addRemoveBtn setImage:[UIImage imageNamed:self.isActive ? @"remove" : @"add"] forState:UIControlStateNormal];

    [UIView animateWithDuration:.3f animations:^{
//        self.selectBtn.alpha = on ? 1.0f : 0.0f;
//        self.addRemoveBtn.alpha = on ? 1.0f : 0.0f;;
        self.selectBtn.hidden = !on;
        self.addRemoveBtn.hidden = !on;
        self.logoImgView.layer.transform = on ? CATransform3DMakeScale(.9f, .9f, 1): CATransform3DIdentity;
        [self updateEnabledView];
    }];
}

-(void)onSelected:(onSelectedBlock)onSelectedBlock
{
    _onSelected = onSelectedBlock;
}

-(void)onActiveChanged:(onActiveChangeBlock)onActiveChangeBlock
{
    _onActiveChange = onActiveChangeBlock;
}

-(void)setMarket:(AAAMarket *)market
{
    if (_market != market) {
        [self.logoImgView setImage:nil];
    }
    _market = market;
    if (!market) {
        return;
    }
    NSURL* imagURL = [NSURL URLWithString:market.miniLogoURL];
    [[JMImageCache sharedCache] imageForURL:imagURL completionBlock:^(UIImage *image) {
//        UIImage* newImage = [AAAGlobals imageWithShadowForImage:image];
        [self.logoImgView setImage:image];
    } failureBlock:^(NSURLRequest *request, NSURLResponse *response, NSError *error) {
        NSLog(@"JMIMageCache failed: %@", error);
    }];
}

-(void) setSelected:(BOOL)selected
{
    [super setSelected:selected];
    [self updateEnabledView];
}

-(void) updateEnabledView
{
    self.logoImgView.alpha = (self.isInEditMode && self.isActive) || (!self.isInEditMode && self.isSelected) ? 1.0f:DisabledMarketViewTransparency;
    self.selectBtn.alpha =  self.isInEditMode ? (self.isActive ? 1.0f : 0.0f) : 0.0f;
}

- (IBAction)selectPressed:(UIButton *)sender
{
    if (_onSelected) {
        _onSelected(self.market);
    }
}

- (IBAction)addRemovePressed:(UIButton *)sender
{
    self.isActive = !self.isActive;
    if (_onActiveChange && !_onActiveChange(self)) {
        return;
    }
    
    UIImage* img = [UIImage imageNamed: self.isActive ? @"remove" : @"add"];
    [sender setImage:img forState:UIControlStateNormal];
    [sender setImage:img forState:UIControlStateSelected];

    CATransition *transition = [CATransition animation];
    transition.duration = .4f;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionFade;
    transition.removedOnCompletion = YES;
    [sender.layer addAnimation:transition forKey:@"fade"];
    
    CABasicAnimation *spin;
    spin = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
//    spin.fromValue = [NSNumber numberWithFloat:M_PI/4];
//    spin.toValue = [NSNumber numberWithFloat:(M_PI/2)];
    spin.fromValue = [NSNumber numberWithFloat:self.isActive? 0 : M_PI/4];
    spin.toValue = [NSNumber numberWithFloat:self.isActive?-M_PI/2 : M_PI/2];
    spin.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    spin.duration = .4f; // How fast should the image spin
    spin.repeatCount = 1; // HUGE_VALF means infinite repeatCount;
    spin.removedOnCompletion = YES;
    [sender.layer addAnimation:spin forKey:@"Spin"];

    [UIView animateWithDuration:.3f animations:^{
        [self updateEnabledView];
    }];
    
    
//    CATransition *animation = [CATransition animation];
//    [animation setDelegate:self];
//    [animation setDuration:.6f];
//    //    [animation setTimingFunction: UIViewAnimationCurveEaseInOut];
//    //    [animation setTimingFunction: [CAMediaTimingFunction UIViewAnimationCurveEaseInOut]];
//    [animation setType:@"rippleEffect" ];
//    [sender.layer addAnimation:animation forKey:NULL];
}
@end
