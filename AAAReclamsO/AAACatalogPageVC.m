//
//  AAACatalogPageVC.m
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 17/11/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import "AAACatalogPageVC.h"

@implementation AAACatalogPageVC
{
    IBOutlet UIImageView* page;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    if (self.imageUrl) {
        [self updateImage];
    }
}

-(void)setImageUrl:(NSString *)imageUrl
{
    _imageUrl = imageUrl;
    if (page) {
        [self updateImage];
    }
}

-(void) updateImage
{
    [page setImage:[UIImage imageNamed:self.imageUrl]];
}

@end
