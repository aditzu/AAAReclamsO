//
//  AAATutorialManager.h
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 18/12/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, TutorialView)
{
    TutorialViewDiscoverMarkets,
    TutorialViewTapOnMarket,
    TutorialViewDiscoverCatalogs,
    TutorialViewTapOnCatalog,
    TutorialViewExploreCatalog,
    TutorialViewZoomOnCatalog
};

@interface AAATutorialManager : NSObject
+(AAATutorialManager*) instance;
-(UIView*) addTutorialView:(TutorialView) tutView withDependecies:(NSArray*) dependencies atCenter:(CGPoint) point;
-(void) setupWithStoryboard:(UIStoryboard*) _storyboard;
-(void) showTutorialView:(TutorialView) tutorialViewToShow;
-(void) invalidateTutorialView:(TutorialView) tutorialToInvalidate;
-(void) hideAllTutorialViews;
@end
