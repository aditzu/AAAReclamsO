//
//  AAATutorialVCViewController.m
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 18/12/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import "AAATutorialVC.h"
#import <QuartzCore/QuartzCore.h>

@interface AAATutorialVC ()
{
    NSString* identifier;
    UIImage* _image;
    NSString* _text;
}
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *label;
@end

@implementation AAATutorialVC

-(void) setProperties
{
    self.imageView.image = _image;
    self.label.text = _text;
}

-(void) setImage:(UIImage*) image text:(NSString *)text id:(NSString *)_identifier
{
    _image = image;
    _text = text;
    [self setProperties];
    identifier = _identifier;
}

-(void) start
{
    self.view.hidden = NO;
    self.view.alpha = 0.0f;
    self.isStarted = YES;
    [UIView animateWithDuration:.3f animations:^{
        self.view.alpha = 1.0f;
    } completion:^(BOOL finished) {
    }];
    
    UIViewAnimationOptions animOptions = UIViewAnimationOptionRepeat|UIViewAnimationOptionAutoreverse|UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction;
    switch (self.animationType) {
        case TutorialAnimationTypePulsing:
        {
            [UIView animateWithDuration:.4f delay:.3f options:animOptions animations:^{
                self.view.layer.transform = CATransform3DMakeScale(1.1f, 1.1f, 1.0f);
            } completion:^(BOOL finished) {
                
            }];

            break;
        }
        case TutorialAnimationTypeMoveLeftRight:
        {
            [UIView animateWithDuration:.4f delay:0 options:animOptions animations:^{
                self.view.layer.transform = CATransform3DMakeTranslation(10, 0, 0);
            } completion:^(BOOL finished) {
                
            }];
            break;
        }
        default:
            break;
    }
}

-(void) stop
{
    self.isStarted = NO;
    [UIView animateWithDuration:.3f animations:^{
        self.view.alpha = 0.0f;
    } completion:^(BOOL finished) {
        if (!self.isStarted) {
            [self.view.layer removeAllAnimations];
            self.view.hidden = YES;
            self.view.layer.transform = CATransform3DIdentity;
        }
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if (!self.isStarted) {
        self.view.hidden = YES;
    }
    [self setProperties];
}

@end
