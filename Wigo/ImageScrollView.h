//
//  ImageScrollView.h
//  Wigo
//
//  Created by Alex Grinman on 12/15/14.
//  Copyright (c) 2014 Alex Grinman. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol ImageScrollViewDelegate

- (void) pageChangedTo: (NSInteger) page;

@end

@interface ImageScrollView : UIView<UIScrollViewDelegate>

@property (nonatomic, assign) id<ImageScrollViewDelegate> delegate;

- (instancetype)initWithFrame: (CGRect) frame imageURLs:(NSArray *)imageURLS infoDicts:(NSArray *)infoDicts areaDicts:(NSArray *)arrayDicts;

- (UIImageView *) getImageAtPage: (NSInteger) page;

@end
