//
//  AAACatalogPageVC.m
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 17/11/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import "AAACatalogPageVC.h"
#import "JMImageCache.h"

@implementation AAACatalogPageVC
{
    IBOutlet UIImageView* page;
    IBOutlet UIView* spinnerView;
    IBOutlet UIScrollView* scrollView;
    IBOutlet UIView* overlay;
    
    BOOL shown;
    UIImage* img;
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
//        NSLog(@"Downloading:%@", self.imageUrl);
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
        NSLog(@"Downloading:%@", self.imageUrl);
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
