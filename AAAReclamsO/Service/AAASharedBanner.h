//
//  AAASharedBanner.h
//  AAAReclamsO
//
//  Created by Adrian Ancuta on 08/12/14.
//  Copyright (c) 2014 Adrian Ancuta. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GADBannerView.h"

@interface AAASharedBanner : NSObject

@property (nonatomic, strong) GADBannerView* bannerView;

-(id)initWithAdUnitId:(NSString*) adUnitId;
-(void) setRootViewController:(UIViewController*) vc;

@end
