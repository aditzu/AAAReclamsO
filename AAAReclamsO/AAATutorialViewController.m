//
//  AAATutorialController.m
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 12/12/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import "AAATutorialViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "TutorialView.h"

@interface AAATutorialViewController()
{
    IBOutlet TutorialView* marketsBarTutorialView;
    IBOutlet UILabel* marketsBarTutorialUpperLabel;
    IBOutlet UIImageView* marketsBarTutorialSlideLeftRightImage;
    IBOutlet UILabel* marketsBarTutorialLowerLabel;
    IBOutlet UIImageView* marketsBarTutorialTapImage;
    IBOutlet UIImageView* marketsBarTutorialBg;
    
    IBOutlet TutorialView* catalogsTutorialView;
    IBOutlet TutorialView* insideCatalogTutorialView;
    
}

@end

@implementation AAATutorialViewController

static AAATutorialViewController* _instance;

+(void) initWithStoryboard:(UIStoryboard*) storyboard andSuperView:(UIView *)superview
{
    _instance = (AAATutorialViewController*)[storyboard instantiateViewControllerWithIdentifier:@"tutorialViewController"];
    _instance.superView = superview;
}

+(AAATutorialViewController *)instance
{
//    if (!_instance) {
//        _instance = [[AAATutorialViewController alloc] init];
//    }
    return _instance;
}

-(void)setSuperView:(UIView *)superView
{
    if (self.isViewLoaded) {
        self.view.frame = superView.bounds;
        [superView addSubview:self.view];
    }
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    [self setAllHidden:YES];
    self.superView = self.superView;
    marketsBarTutorialView.autoDismiss = NO;
    catalogsTutorialView.autoDismiss = NO;
    insideCatalogTutorialView.autoDismiss = NO;
    
    [self setupInitialMarketsBarTutorialView];
//    [self addArrowsToMarketsBarTutorial];
}

-(void) setupInitialMarketsBarTutorialView
{
    //set all the subviews hidden
    marketsBarTutorialUpperLabel.hidden = YES;
    marketsBarTutorialSlideLeftRightImage.hidden = YES;
    marketsBarTutorialLowerLabel.hidden = YES;
    marketsBarTutorialTapImage.hidden = YES;
    
    //set the lower shadow
    CAGradientLayer *l = [CAGradientLayer layer];
    l.frame = marketsBarTutorialBg.bounds;
    l.colors = [NSArray arrayWithObjects:(id)[UIColor blackColor].CGColor, (id)[UIColor clearColor].CGColor, nil];
    l.startPoint = CGPointMake(0.5f, 0.98f);
    l.endPoint = CGPointMake(0.5f, 1.0f);
    marketsBarTutorialBg.layer.mask = l;
}


-(void) addArrowToMarketsBarTutorial:(iTutorialViewStepNumber) index
{
    if (index == iTutorialViewStepNumberFirst) {
        Arrow* firstArrow = [[Arrow alloc] init];
        firstArrow.tail = marketsBarTutorialSlideLeftRightImage.frame.origin;
        firstArrow.head = CGPointMake(50, 488);//todo
        firstArrow.animated = YES;
        firstArrow.curved = YES;
        firstArrow.direction = ArrowDirectionTH;
        [marketsBarTutorialView addArrow:firstArrow];
    }
    else if (index == iTutorialViewStepNumberSecond)
    {
        Arrow* secondArrow = [[Arrow alloc] init];
        secondArrow.tail = CGPointMake(marketsBarTutorialTapImage.frame.origin.x + marketsBarTutorialTapImage.frame.size.width, marketsBarTutorialTapImage.frame.origin.y);
        secondArrow.head = CGPointMake(270, 488);
        secondArrow.animated = YES;
        secondArrow.curved = YES;
        secondArrow.direction = ArrowDirectionTH;
        [marketsBarTutorialView addArrow:secondArrow];
    }
}

-(void) setAllHidden:(BOOL) hidden
{
    marketsBarTutorialView.hidden = hidden;
    catalogsTutorialView.hidden = hidden;
    insideCatalogTutorialView.hidden = hidden;
}

-(TutorialView*) tutorialViewForType:(iTutorialViewType) tutViewType
{
    switch (tutViewType) {
        case iTutorialViewTypeCatalogsCarousel:
            return catalogsTutorialView;
        case iTutorialViewTypeInsideCatalogs:
            return insideCatalogTutorialView;
        case iTutorialViewTypeMarketsBar:
            return marketsBarTutorialView;
        default:
            return nil;
    }
}

-(void) animateView:(UIView*) viewToAnimate in:(BOOL) fadeIn onComplete:(void(^)(void)) completion
{
    if (fadeIn) {
        viewToAnimate.alpha = 0.0f;
        viewToAnimate.hidden = NO;
    }
    [UIView animateWithDuration:.3f animations:^{
        viewToAnimate.alpha = fadeIn ? 1.0f : 0.0f;
    } completion:^(BOOL finished) {
        viewToAnimate.hidden = finished && !fadeIn;
        if (finished && completion) {
            completion();
        }
    }];
}

-(void) animateViews:(NSArray*) views in:(BOOL) fadeIn onComplete:(void(^)(void)) completion
{
    for (UIView* v in views) {
        if ([v isEqual:[views lastObject]])
            [self animateView:v in:fadeIn onComplete:completion];
        else
            [self animateView:v in:fadeIn onComplete:nil];
        
    }
}


-(NSString*) stringForTutorialType:(iTutorialViewType) tutType
{
    switch (tutType) {
        case iTutorialViewTypeMarketsBar:
            return @"iTutorialViewTypeMarketsBar";
        case iTutorialViewTypeCatalogsCarousel:
            return @"iTutorialViewTypeCatalogsCarousel";
        case iTutorialViewTypeInsideCatalogs:
            return @"iTutorialViewTypeInsideCatalogs";
        default:
            return nil;
    }
}

-(iTutorialViewType) tutorialTypeForString:(NSString*) tutTypeAsString
{
    if ([tutTypeAsString isEqualToString:@"iTutorialViewTypeMarketsBar"]) {
        return iTutorialViewTypeMarketsBar;
    }
    if ([tutTypeAsString isEqualToString:@"iTutorialViewTypeInsideCatalogs"]) {
        return iTutorialViewTypeInsideCatalogs;
    }
    if ([tutTypeAsString isEqualToString:@"iTutorialViewTypeCatalogsCarousel"]) {
        return iTutorialViewTypeCatalogsCarousel;
    }
    return -1;
}

#pragma mark - public

-(void) updateProgress:(iTutorialViewType) tutorialType progress:(iTutorialViewStepNumber) progress
{
    [[NSUserDefaults standardUserDefaults] setInteger:progress forKey:[self stringForTutorialType:tutorialType]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


-(void) animateStepNumber:(iTutorialViewStepNumber) stepNumber inTutorialView:(iTutorialViewType) tutorialViewType
{
    if ([self tutorialViewForType:tutorialViewType].hidden) {
        return;
    }
    
    if ([[NSUserDefaults standardUserDefaults] integerForKey:[self stringForTutorialType:tutorialViewType]] >= stepNumber) {
        return;
    }
    
    switch (tutorialViewType) {
        case iTutorialViewTypeCatalogsCarousel:

            break;
        case iTutorialViewTypeInsideCatalogs:
            break;
        case iTutorialViewTypeMarketsBar:
            if (stepNumber == iTutorialViewStepNumberFirst) {
                [self animateViews:@[marketsBarTutorialUpperLabel, marketsBarTutorialSlideLeftRightImage] in:YES onComplete:^{
                    [self addArrowToMarketsBarTutorial:stepNumber];
                }];
            }
            else if (stepNumber == iTutorialViewStepNumberSecond)
            {
                [self animateViews:@[marketsBarTutorialLowerLabel, marketsBarTutorialTapImage] in:YES onComplete:^{
                    [self addArrowToMarketsBarTutorial:stepNumber];
                }];
            }
            break;
        default:
            break;
    }
}

-(void)show:(BOOL)show tutorialView:(iTutorialViewType)tutorialViewType
{
    [self setAllHidden:YES];
    TutorialView* tutView;
    switch (tutorialViewType) {
        case iTutorialViewTypeCatalogsCarousel:
            tutView = catalogsTutorialView;
          
            break;
        case iTutorialViewTypeInsideCatalogs:
            tutView = insideCatalogTutorialView;
            break;
        case iTutorialViewTypeMarketsBar:
            tutView = marketsBarTutorialView;
            if ([[NSUserDefaults standardUserDefaults] integerForKey:[self stringForTutorialType:tutorialViewType]] >= 1) {
                return;
            }
            break;
        default:
            break;
    }
    
    tutView.hidden = NO;
}

@end
