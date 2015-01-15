//
//  AAACatalogPageVC.h
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 17/11/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AAACatalogPageVC;
typedef void (^onPageLoadedBlock) (AAACatalogPageVC* catalogPageVC, BOOL success);
typedef void (^OnScrollViewHeightConstraintChange) (AAACatalogPageVC* catalogPageVC);

@protocol AAACatalogPageVCDelegate <NSObject>
@optional
-(void) catalogPage:(AAACatalogPageVC*) catalogPage pageLoaded:(BOOL)pageLoaded;
-(void) catalogPage:(AAACatalogPageVC*) catalogPage contentSizeDidChange:(CGSize) newSize;
@end

@interface AAACatalogPageVC : UIViewController<UIScrollViewDelegate>

@property(nonatomic, strong) NSString* imageUrl;
@property(nonatomic) int indexInPageViewCtrl;
@property(nonatomic, strong) IBOutlet UIScrollView* scrollView;
@property(nonatomic, strong) id<AAACatalogPageVCDelegate> delegate;
@property(nonatomic) BOOL isPageLoaded;
@property(nonatomic, copy) OnScrollViewHeightConstraintChange onScrollViewHeightConstraintChange;
-(void) downloadImage;
-(void) show:(BOOL)show;
-(CGRect) croppedPageCalculatedFrame;
-(CGRect) croppedPageCalculatedFrameInParentFrame:(CGRect) parentFrame;
-(void) addOnPageLoaded:(onPageLoadedBlock) onPageLoaded;
@end
