//
//  AAATutorialController.h
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 12/12/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, iTutorialViewStepNumber)
{
    iTutorialViewStepNumberNone = 0,
    iTutorialViewStepNumberFirst,
    iTutorialViewStepNumberSecond,
    iTutorialViewStepNumberThird,
    iTutorialViewStepNumberForth
};

typedef NS_ENUM(NSInteger, iTutorialViewType)
{
    iTutorialViewTypeMarketsBar = 0,
    iTutorialViewTypeCatalogsCarousel,
    iTutorialViewTypeInsideCatalogs
};

@interface AAATutorialViewController : UIViewController

@property (nonatomic, strong) UIView* superView;

+(void) initWithStoryboard:(UIStoryboard*) storyboard andSuperView:(UIView*) superview;
+(AAATutorialViewController*) instance;

-(void) show:(BOOL) show tutorialView:(iTutorialViewType) tutorialViewType;
-(void) animateStepNumber:(iTutorialViewStepNumber) stepNumber inTutorialView:(iTutorialViewType) tutorialViewType;
-(void) updateProgress:(iTutorialViewType) tutorialType progress:(iTutorialViewStepNumber) progress;
@end
