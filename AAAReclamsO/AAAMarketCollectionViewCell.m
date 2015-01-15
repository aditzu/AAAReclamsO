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
    
    BOOL _addRemoveEnabled;
    int _lastUnseenCatalogsCount;
}

@property(nonatomic) BOOL isInEditMode;

@property (weak, nonatomic) IBOutlet UIButton *selectBtn;
@property (weak, nonatomic) IBOutlet UIButton *addRemoveBtn;
@property (weak, nonatomic) IBOutlet UIImageView *logoImgView;
@property (weak, nonatomic) IBOutlet UIView *badgeView;
@property (weak, nonatomic) IBOutlet UIImageView *badgeViewBg;
@property (weak, nonatomic) IBOutlet UILabel *badgeViewLabel;

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
        _addRemoveEnabled = YES;
    }
    return self;
}

-(void)enableAddRemoveFeature:(BOOL)enable
{
    _addRemoveEnabled = enable;
    self.addRemoveBtn.hidden = !enable;
}

-(void)setupEditModeOn:(BOOL)on
{
    self.isInEditMode = on;
    [self.addRemoveBtn setImage:[UIImage imageNamed:self.isActive ? @"remove" : @"add"] forState:UIControlStateNormal];

    [UIView animateWithDuration:.3f animations:^{
//        self.selectBtn.alpha = on ? 1.0f : 0.0f;
//        self.addRemoveBtn.alpha = on ? 1.0f : 0.0f;
//        self.selectBtn.hidden = !on;
        self.selectBtn.hidden = YES;
        self.addRemoveBtn.hidden = _addRemoveEnabled ? !on : YES;
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

-(void) tryDecrementUnseenCatalogs:(int)newUnseenCatalogs
{
    if (newUnseenCatalogs == _lastUnseenCatalogsCount) {
        return;
    }
    _lastUnseenCatalogsCount  = newUnseenCatalogs;
    if (_lastUnseenCatalogsCount <= 0) {
        [UIView animateWithDuration:.3f animations:^{
            self.badgeView.layer.transform = CATransform3DMakeScale(0.0f, 0.0f, 1.0f);
        } completion:^(BOOL finished) {
            if (finished) {
                self.badgeView.layer.transform = CATransform3DIdentity;
                self.badgeView.alpha = 0.0f;
            }
        }];
    }
}

-(void)setUnseenCatalogs:(int)unseenCatalogs
{
    if (_lastUnseenCatalogsCount == unseenCatalogs) {
        if (_lastUnseenCatalogsCount == 0) {
            self.badgeView.alpha = 0.0f;
        }
        return;
    }
    
    if (unseenCatalogs <= 0) {
        self.badgeView.layer.transform = CATransform3DIdentity;
        self.badgeView.alpha = 0.0f;
//        [UIView animateWithDuration:.3f animations:^{
//            self.badgeView.layer.transform = CATransform3DMakeScale(0.0f, 0.0f, 1.0f);
//        } completion:^(BOOL finished) {
//            if (finished) {
//                self.badgeView.layer.transform = CATransform3DIdentity;
//                self.badgeView.alpha = 0.0f;
//            }
//        }];
    }
    else
    {
        self.badgeView.layer.transform = CATransform3DIdentity;
        [UIView animateWithDuration:.3f animations:^{
            self.badgeView.alpha = 1.0f;
            self.badgeViewLabel.alpha = 0.0f;
            self.badgeViewLabel.text = [NSString stringWithFormat:@"%i", unseenCatalogs];
            self.badgeViewLabel.alpha = 1.0f;
        }];
        
        UIViewAnimationOptions animOptions = UIViewAnimationOptionRepeat|UIViewAnimationOptionAutoreverse|UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction;
        
        [UIView animateWithDuration:.4f delay:.3f options:animOptions animations:^{
            self.badgeView.layer.transform = CATransform3DMakeScale(.95f, .95f, 1.0f);
        } completion:^(BOOL finished) {
            
        }];
    }
    _lastUnseenCatalogsCount = unseenCatalogs;
}

-(void) setSelected:(BOOL)selected
{
    [super setSelected:selected];
    [self updateEnabledView];
}

-(void) updateEnabledView
{
    self.logoImgView.alpha = self.isSelected ? 1.0f : DisabledMarketViewTransparency;
//    self.logoImgView.alpha = (self.isInEditMode && self.isActive) || (!self.isInEditMode && self.isSelected) ? 1.0f:DisabledMarketViewTransparency;
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
