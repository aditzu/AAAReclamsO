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
    IBOutlet UIScrollView* scrollView;
    IBOutlet UIView* overlay;
    
    IBOutlet NSLayoutConstraint* pageYConstraint;
    IBOutlet NSLayoutConstraint* pageXConstraint;
    IBOutlet NSLayoutConstraint* pageWConstraint;
    IBOutlet NSLayoutConstraint* pageHConstraint;
    
    BOOL shown;
    UIImage* img;
    
    BOOL animating;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    scrollView.minimumZoomScale = 1.0f;
    scrollView.maximumZoomScale = 3.0f;
    scrollView.contentSize = page.frame.size;
    
    if (self.imageUrl) {
        [self updateImage];
    }
    spinnerView.hidden = (img != nil);
    
    UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTapFrom:)];
    tapGesture.numberOfTapsRequired = 2;
    [scrollView addGestureRecognizer:tapGesture];
    [self show:shown];
    self.view.clipsToBounds = NO;
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    if (pageWConstraint.constant != scrollView.bounds.size.width) {
        pageWConstraint.constant  = scrollView.bounds.size.width;
    }
    
    if (pageHConstraint.constant != scrollView.bounds.size.height) {
        pageHConstraint.constant = scrollView.bounds.size.height - 4;//4 for the shadow
    }
    [page layoutIfNeeded];
    scrollView.zoomScale = 1.0f;
    
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
    
    page.layer.masksToBounds = NO;
    page.layer.shadowColor = [UIColor blackColor].CGColor;
    page.layer.shadowOffset = CGSizeMake(0, 3);
    page.layer.shadowOpacity = .5;
    page.layer.shadowRadius = 1.0f;
    [self.view layoutSubviews];
}

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
    
    center = [page convertPoint:center fromView:scrollView];
    
    zoomRect.origin.x    = center.x - ((zoomRect.size.width / 2.0));
    zoomRect.origin.y    = center.y - ((zoomRect.size.height / 2.0));
    
    return zoomRect;
}

- (void)handleDoubleTapFrom:(UITapGestureRecognizer *)recognizer {
    page.translatesAutoresizingMaskIntoConstraints = NO;

    float newScale = scrollView.zoomScale * 4.0;
    
    if (scrollView.zoomScale > scrollView.minimumZoomScale)
    {
        [scrollView setZoomScale:scrollView.minimumZoomScale animated:YES];
    }
    else
    {
        CGRect zoomRect = [self zoomRectForScale:newScale
                                      withCenter:[recognizer locationInView:recognizer.view]];
        [scrollView zoomToRect:zoomRect animated:YES];
    }
}

#pragma mark - ScrollView

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return page;
}
@end
