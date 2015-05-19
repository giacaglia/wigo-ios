//
//  PhotoViewController.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/13/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PhotoViewController : UIViewController

- (id)initWithImage:(NSDictionary *)image;
@property (nonatomic, assign) int indexOfImage;
@property (nonatomic, strong) UIView *bgView;
@property (nonatomic, strong) UIView *grayView;

@end
