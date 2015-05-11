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
- (id) initWithFrame: (CGRect)frame andUser:(WGUser *)user;

@property (nonatomic, assign) id<ImageScrollViewDelegate> delegate;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, strong) WGUser *user;

- (UIImage *) getCurrentImage;

@end
