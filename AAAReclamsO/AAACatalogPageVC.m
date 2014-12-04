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

@implementation AAACatalogPageVC
{
    IBOutlet UIImageView* page;
    IBOutlet UIView* spinnerView;
    IBOutlet UIView* overlay;
    
    IBOutlet NSLayoutConstraint* pageYConstraint;
    IBOutlet NSLayoutConstraint* pageXConstraint;
    IBOutlet NSLayoutConstraint* pageWConstraint;
    IBOutlet NSLayoutConstraint* pageHConstraint;
    
    BOOL shown;
    UIImage* img;
    
    BOOL animating;
    float pageYConstraintInitial;
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
    pageYConstraintInitial = pageYConstraint.constant;
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    if (pageWConstraint.constant != self.scrollView.bounds.size.width) {
        pageWConstraint.constant  = self.scrollView.bounds.size.width;
    }
    
    if (pageHConstraint.constant != self.scrollView.bounds.size.height) {
        pageHConstraint.constant = self.scrollView.bounds.size.height - 4;//4 for the shadow
    }
    [page layoutIfNeeded];
    self.scrollView.zoomScale = 1.0f;
  
    
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
//    
//    pageWConstraint.constant = width;
//    pageHConstraint.constant = height;
//    pageXConstraint.constant += xoffset;
//    pageYConstraint.constant += yoffset;
//    [page layoutIfNeeded];
//    
//    
//    page.layer.masksToBounds = NO;
//    page.layer.shadowColor = [UIColor blackColor].CGColor;
//    page.layer.shadowOffset = CGSizeMake(0, 3);
//    page.layer.shadowOpacity = .5;
//    page.layer.shadowRadius = 1.0f;
//    [self.view layoutSubviews];
}

//-(CGRect)scrollViewFrame
//{
//    return page.frame;
//    return [self.view convertRect:page.superview.frame fromView:self.scrollView];
//}

-(void)setImageUrl:(NSString *)imageUrl
{
    _imageUrl = imageUrl;
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
        } failureBlock:^(NSURLRequest *request, NSURLResponse *response, NSError *error) {
            NSLog(@"Failed to download catalog page: %@", self.imageUrl);
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
        } failureBlock:^(NSURLRequest *request, NSURLResponse *response, NSError *error) {
            NSLog(@"Failed to download catalog page: %@", self.imageUrl);
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

- (void)handleDoubleTapFrom:(UITapGestureRecognizer *)recognizer {
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

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
}

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return page;
}
@end
