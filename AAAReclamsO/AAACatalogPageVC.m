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
    UIImage* img;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    if (self.imageUrl) {
        [self updateImage];
    }
    spinnerView.hidden = (img != nil);
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
        NSLog(@"Downloading:%@", self.imageUrl);
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

@end
