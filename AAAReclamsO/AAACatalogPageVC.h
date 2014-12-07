//
//  AAACatalogPageVC.h
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 17/11/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AAACatalogPageVC;

@protocol AAACatalogPageVCDelegate <NSObject>
@optional
-(void) catalogPage:(AAACatalogPageVC*) catalogPage contentSizeDidChange:(CGSize) newSize;
@end

@interface AAACatalogPageVC : UIViewController<UIScrollViewDelegate>

@property(nonatomic, strong) NSString* imageUrl;
@property(nonatomic) int indexInPageViewCtrl;
@property(nonatomic, strong) IBOutlet UIScrollView* scrollView;
@property(nonatomic, strong) id<AAACatalogPageVCDelegate> delegate;
-(void) downloadImage;
-(void) show:(BOOL)show;
-(CGRect) scrollViewFrame;
@end
