//
//  AAATutorialVCViewController.h
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 18/12/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, TutorialAnimationType)
{
    TutorialAnimationTypePulsing,
    TutorialAnimationTypeMoveLeftRight
};

@interface AAATutorialVC : UIViewController
@property(nonatomic) TutorialAnimationType animationType;
@property(nonatomic) BOOL isStarted;
//@property(nonatomic)  BOOL seen;
-(void) setImage:(UIImage*) image text:(NSString*) text id:(NSString*) identifier;
-(void) start;
-(void) stop;
@end
