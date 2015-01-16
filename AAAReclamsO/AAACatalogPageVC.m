//
//  AAACatalogPageVC.m
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 17/11/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import "AAACatalogPageVC.h"
#import "JMImageCache.h"
#import <QuartzCore/QuartzCore.h>
#import "Flurry.h"
#import "AAAGlobals.h"

@implementation AAACatalogPageVC
{
    IBOutlet UIImageView* page;
    IBOutlet UIView* spinnerView;
    IBOutlet UIView* overlay;
    
    IBOutlet NSLayoutConstraint* pageWConstraint;
    IBOutlet NSLayoutConstraint* pageHConstraint;
    
    BOOL shown;
    UIImage* img;
    
    NSMutableArray* onPageLoadedBlocks;
}

-(instancetype)init
{
    if (self = [super init]) {
        onPageLoadedBlocks = [NSMutableArray array];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        onPageLoadedBlocks = [NSMutableArray array];
    }
    return self;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    self.scrollView.minimumZoomScale = 1.0f;
    self.scrollView.maximumZoomScale = 3.0f;
    self.scrollView.contentSize = page.frame.size;
    
    if (self.imageUrl) {
        [self updateImage];
    }
    spinnerView.hidden = (img != nil);
    
    UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTapFrom:)];
    tapGesture.numberOfTapsRequired = 2;
    [self.scrollView addGestureRecognizer:tapGesture];
    [self show:shown];
    self.view.clipsToBounds = NO;
}

-(void)setIsPageLoaded:(BOOL)isPageLoaded
{
    _isPageLoaded = isPageLoaded;
    [self alertOnPageLoadedListeners:isPageLoaded];
    if (self.delegate && [self.delegate respondsToSelector:@selector(catalogPage:pageLoaded:)])
    {
        [self.delegate catalogPage:self pageLoaded:isPageLoaded];
    }
}

-(void)addOnPageLoaded:(onPageLoadedBlock)onPageLoaded
{
    [onPageLoadedBlocks addObject:[onPageLoaded copy]];
}

-(void) alertOnPageLoadedListeners:(BOOL) success
{
    for (onPageLoadedBlock _onPgLoaded in onPageLoadedBlocks) {
        _onPgLoaded(self, success);
    }
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if (!self.scrollView.isZooming)
    {
        if (pageWConstraint.constant != self.scrollView.bounds.size.width) {
            pageWConstraint.constant  = self.scrollView.bounds.size.width;
        }
        
        if (pageHConstraint.constant != self.scrollView.bounds.size.height){// - 4) {
            pageHConstraint.constant = self.scrollView.bounds.size.height;// - 4;//4 for the shadow
            [page layoutIfNeeded];
            if (self.onScrollViewHeightConstraintChange) {
                self.onScrollViewHeightConstraintChange(self);
            }
        }
        [self.view layoutIfNeeded];
        self.scrollView.zoomScale = 1.0f;
    }
}

//-(void) cutTheImage
//{
//    float imageRatio = page.image.size.width/ page.image.size.height;
//    float imageViewRatio = page.frame.size.width / page.frame.size.height;
//    
//    float width = 0, height = 0, yoffset = 0, xoffset = 0;
//    if (imageRatio > imageViewRatio) {
//        width = page.frame.size.width;
//        height = width / imageRatio;
//        assert(page.frame.size.height > height);
//        yoffset = (page.frame.size.height - height)/2.0f;
//    }
//    else
//    {
//        height = page.frame.size.height;
//        width = height * imageRatio;
//        assert(page.frame.size.width > width);
//        xoffset = (page.frame.size.width - width) / 2.0f;
//    }
//    pageWConstraint.constant = width;
//    pageHConstraint.constant = height;
//    [self.view layoutSubviews];
//}

-(CGRect) croppedPageCalculatedFrame
{
    return  [self croppedPageCalculatedFrameInParentFrame:page.frame];
}

-(CGRect) croppedPageCalculatedFrameInParentFrame:(CGRect) parentFrame
{
    if (!self.isPageLoaded) {
        return [self.view convertRect:parentFrame toView:self.scrollView];
    }
    
    float imageRatio = img.size.width/ img.size.height;
    float imageViewRatio = parentFrame.size.width / parentFrame.size.height;
    
    float width = 0, height = 0, yoffset = 0, xoffset = 0;
    if (imageRatio > imageViewRatio) {
        width = parentFrame.size.width;
        height = width / imageRatio;
        assert(parentFrame.size.height >= height);
        yoffset = (parentFrame.size.height - height)/2.0f;
    }
    else
    {
        height = parentFrame.size.height;
        width = height * imageRatio;
        assert(parentFrame.size.width >= width);
        xoffset = (parentFrame.size.width - width) / 2.0f;
    }
    
    CGRect imgViewFrame = parentFrame;
    imgViewFrame.size.width = width;
    imgViewFrame.size.height = height;
    imgViewFrame.origin.x += xoffset;
    imgViewFrame.origin.y += yoffset;
    return [self.view convertRect:imgViewFrame fromView:self.scrollView];
}

-(void)setImageUrl:(NSString *)imageUrl
{
    _imageUrl = [imageUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    if (page) {
        [self updateImage];
    }
}

-(void) downloadImage
{
    if (!img) {
        [[JMImageCache sharedCache] imageForURL:[NSURL URLWithString:self.imageUrl] completionBlock:^(UIImage *image) {
            img = image;
            spinnerView.hidden = YES;
            self.isPageLoaded = YES;
        } failureBlock:^(NSURLRequest *request, NSURLResponse *response, NSError *error) {
            NSLog(@"Failed to download catalog page: %@", self.imageUrl);
            [Flurry logError:FlurryEventErrorFromServer message:@"downloadImage" error:error];
            self.isPageLoaded = NO;
        }];
    }
}

-(void) updateImage
{
    if (img) {
        [page setImage:img];
    }
    else
    {
        [[JMImageCache sharedCache] imageForURL:[NSURL URLWithString:self.imageUrl] completionBlock:^(UIImage *image) {
            img = image;
            spinnerView.hidden = YES;
            [page setImage: image];
            self.isPageLoaded = YES;
        } failureBlock:^(NSURLRequest *request, NSURLResponse *response, NSError *error) {
            [Flurry logError:FlurryEventErrorFromServer message:@"updateImage" error:error];
            NSLog(@"Failed to download catalog page: %@", self.imageUrl);
            self.isPageLoaded = NO;
        }];
    }
}

-(void) show:(BOOL)show
{
    shown = show;
    overlay.hidden = show;
}

- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center {
    
    CGRect zoomRect;
    
    zoomRect.size.height = page.frame.size.height / scale;
    zoomRect.size.width  = page.frame.size.width  / scale;
    
    center = [page convertPoint:center fromView:self.scrollView];
    
    zoomRect.origin.x    = center.x - ((zoomRect.size.width / 2.0));
    zoomRect.origin.y    = center.y - ((zoomRect.size.height / 2.0));
    
    return zoomRect;
}

- (void)handleDoubleTapFrom:(UITapGestureRecognizer *)recognizer
{
    page.translatesAutoresizingMaskIntoConstraints = NO;
    float newScale = self.scrollView.zoomScale * 4.0;
    
    if (self.scrollView.zoomScale > self.scrollView.minimumZoomScale)
    {
        [self.scrollView setZoomScale:self.scrollView.minimumZoomScale animated:YES];
    }
    else
    {
        CGRect zoomRect = [self zoomRectForScale:newScale
                                      withCenter:[recognizer locationInView:recognizer.view]];
        [self.scrollView zoomToRect:zoomRect animated:YES];
    }
}

#pragma mark - ScrollView

-(void) scrollViewDidZoom:(UIScrollView *)scrollView
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(catalogPage:contentSizeDidChange:)])
    {
        [self.delegate catalogPage:self contentSizeDidChange:scrollView.contentSize];
    }
//    CGSize contentSize = scrollView.contentSize;
//    if (contentSize.height < scrollView.bounds.size.height) {
//        float y = scrollView.bounds.size.height - contentSize.height;
//        if (y <= pageYConstraintInitial) {
//            pageYConstraint.constant = scrollView.bounds.size.height - contentSize.height;
//        }
//    }
//    else
//    {
//        pageYConstraint.constant = 0.0f;
//    }
//    [page layoutIfNeeded];
}

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return page;
}
@end
