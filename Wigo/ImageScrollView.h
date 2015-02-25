//
//  ImageScrollView.h
//  Wigo
//
//  Created by Alex Grinman on 12/15/14.
//  Copyright (c) 2014 Alex Grinman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Globals.h"

@protocol ImageScrollViewDelegate

- (void) pageChangedTo: (NSInteger) page;

@end

@interface ImageScrollView : UIView<UIScrollViewDelegate>

@property (nonatomic, assign) id<ImageScrollViewDelegate> delegate;

@property (nonatomic, strong) WGUser *user;

- (id) initWithFrame: (CGRect)frame andUser:(WGUser *)user;

- (UIImage *) getCurrentImage;

- (void)updateImages;

@end
