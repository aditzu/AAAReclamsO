//
//  AAATutorialManager.m
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 18/12/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import "AAATutorialManager.h"
#import "AAATutorialVC.h"

@interface AAATutorialManager()
{
    NSMutableDictionary* tutorialViews;
    NSMutableDictionary* tutViewsDependencies;
    NSMutableDictionary* tutViewsSeen;
    UIStoryboard* storyboard;
}
@end

@implementation AAATutorialManager

static AAATutorialManager* _instance;

+(AAATutorialManager *)instance
{
    if (!_instance) {
        _instance = [[AAATutorialManager alloc] init];
    }
    return _instance;
}

-(instancetype)init
{
    if (self == [super init]) {
        tutorialViews = [NSMutableDictionary dictionary];
        tutViewsDependencies = [NSMutableDictionary dictionary];
        tutViewsSeen = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - public

-(void) setupWithStoryboard:(UIStoryboard*) _storyboard
{
    storyboard = _storyboard;
}

-(void) invalidateTutorialView:(TutorialView) tutorialToInvalidate
{
    if ([self isValidToPerform:tutorialToInvalidate])
    {
//        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:[self idForTutorialView:tutorialToInvalidate]];
//        [[NSUserDefaults standardUserDefaults] synchronize];
        [tutViewsSeen setObject:[NSNumber numberWithBool:YES] forKey:@(tutorialToInvalidate)];
        AAATutorialVC* tutorialVC = [tutorialViews objectForKey:@(tutorialToInvalidate)];
        if (tutorialVC) {
            [[tutorialViews objectForKey:@(tutorialToInvalidate)] stop];
        }
    }
}

-(void) showTutorialView:(TutorialView) tutorialViewToShow
{
    if ([self isValidToPerform:tutorialViewToShow])
    {
        if ([tutorialViews[@(tutorialViewToShow)] isStarted]) {
            return;
        }
        for (NSNumber* key in [tutorialViews allKeys]) {
            [tutorialViews[key] stop];
        }
        
        AAATutorialVC* tutorialVC = [tutorialViews objectForKey:@(tutorialViewToShow)];
        [tutorialVC start];
    }
}

-(BOOL) isValidToPerform:(TutorialView) tutorialV
{
    if ([tutViewsSeen objectForKey:@(tutorialV)] && [[tutViewsSeen objectForKey:@(tutorialV)] boolValue]) {
        return NO;
    }
    NSArray* dependencies = [tutViewsDependencies objectForKey:@(tutorialV)];
    BOOL shouldShow = YES;
    if (dependencies) {
        for (NSNumber* tutViewKey in dependencies) {
            BOOL tutViewSeen = [[tutViewsSeen objectForKey:tutViewKey] boolValue];
            shouldShow = tutViewSeen;
            if (!shouldShow) {
                break;
            }
        }
    }
    return shouldShow;
}

-(void) setView:(AAATutorialVC*) tutVC atClampedCenter:(CGPoint) center
{
    CGRect frame = tutVC.view.frame;
    CGRect screenBounds = [UIScreen mainScreen].bounds;

    if (center.x < 0) {
        center.x = 0;
    }
    if (center.y < 0) {
        center.y = 0;
    }
    if (center.x + frame.size.width/2 > screenBounds.size.width) {
        center.x = screenBounds.size.width - frame.size.width/2;
    }
    if (center.y + frame.size.height /2 > screenBounds.size.height) {
        center.y = screenBounds.size.height - frame.size.height/2;
    }
    tutVC.view.center = center;
}

-(UIView*) addTutorialView:(TutorialView) tutView withDependecies:(NSArray*) dependencies atCenter:(CGPoint) point
{
    if ([tutorialViews objectForKey:@(tutView)]) {
        [self setView:((AAATutorialVC*)tutorialViews[@(tutView)]) atClampedCenter:point];
        return ((AAATutorialVC*)tutorialViews[@(tutView)]).view;
    }
    NSString* key = [self idForTutorialView:tutView];
    BOOL seen = [tutViewsSeen objectForKey:@(tutView)] ? [tutViewsSeen[@(tutView)] boolValue] : [[NSUserDefaults standardUserDefaults] boolForKey:key];
    [tutViewsSeen setObject:[NSNumber numberWithBool:seen] forKey:@(tutView)];
    if (seen) {
        return nil;
    }
    
    AAATutorialVC* tutorialVC = [self instantiateTutorialVCForType:tutView];
    [self setView:tutorialVC atClampedCenter:point];
    [tutorialViews setObject:tutorialVC forKey:@(tutView)];
    [tutViewsDependencies setObject:dependencies forKey:@(tutView)];
    return tutorialVC.view;
}

#pragma mark - private

-(AAATutorialVC*) instantiateTutorialVCForType:(TutorialView) tutorialViewType
{
    AAATutorialVC* tutorialVC = [storyboard instantiateViewControllerWithIdentifier:@"tutorialVC"];
    switch (tutorialViewType) {
        case TutorialViewDiscoverMarkets:
        {
            [tutorialVC setImage:[UIImage imageNamed:@"swipe_left_right"] text:@"Descopera Magazinele" id:[self idForTutorialView:tutorialViewType]];
            tutorialVC.animationType = TutorialAnimationTypeMoveLeftRight;
            break;
        }
        case TutorialViewTapOnMarket:
        {
            [tutorialVC setImage:[UIImage imageNamed:@"tap"] text:@"Selecteaza Magazinul" id:[self idForTutorialView:tutorialViewType]];
            tutorialVC.animationType = TutorialAnimationTypePulsing;
            break;
        }
            case TutorialViewDiscoverCatalogs:
        {
            [tutorialVC setImage:[UIImage imageNamed:@"swipe_left_right"] text:@"Descopera Oferta" id:[self idForTutorialView:tutorialViewType]];
            tutorialVC.animationType = TutorialAnimationTypeMoveLeftRight;
            break;
        }
            case TutorialViewTapOnCatalog:
        {
            [tutorialVC setImage:[UIImage imageNamed:@"tap"] text:@"Selecteaza Oferta" id:[self idForTutorialView:tutorialViewType]];
            tutorialVC.animationType = TutorialAnimationTypePulsing;
            break;
        }
            case TutorialViewExploreCatalog:
        {
            [tutorialVC setImage:[UIImage imageNamed:@"swipe_left_right"] text:@"Exploreaza Catalogul" id:[self idForTutorialView:tutorialViewType]];
            tutorialVC.animationType = TutorialAnimationTypeMoveLeftRight;
            break;
        }
//            case TutorialViewCloseCatalog:
//        {
//            [tutorialVC setImage:[UIImage imageNamed:@"tap"] text:@"Inchide" id:[self idForTutorialView:tutorialViewType]];
//            tutorialVC.animationType = TutorialAnimationTypePulsing;
//            break;
//        }
            case TutorialViewZoomOnCatalog:
        {
            [tutorialVC setImage:[UIImage imageNamed:@"zoom"] text:@"Zoom" id:[self idForTutorialView:tutorialViewType]];
            tutorialVC.animationType = TutorialAnimationTypePulsing;//todo
            break;
        }
        default:
            break;
    }
    return tutorialVC;
}

-(NSString*) idForTutorialView:(TutorialView)tutView
{
    return [NSString stringWithFormat:@"%i", tutView];
}

@end
