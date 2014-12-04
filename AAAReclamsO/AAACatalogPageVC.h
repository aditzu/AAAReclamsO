//
//  AAACatalogPageVC.h
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 17/11/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AAACatalogPageVC : UIViewController<UIScrollViewDelegate>

@property(nonatomic, strong) NSString* imageUrl;
@property(nonatomic) int indexInPageViewCtrl;
@property(nonatomic, strong) IBOutlet UIScrollView* scrollView;
-(void) downloadImage;
-(void) show:(BOOL)show;
//-(CGRect) scrollViewFrame;
@end
