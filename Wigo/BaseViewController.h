//
//  UIViewController+BaseViewController.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 4/10/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BaseViewController : UITabBarController

-(UIViewController*) viewControllerWithTabTitle:(NSString*)title image:(UIImage*)image;
-(void) addCenterButtonWithImage:(UIImage*)buttonImage highlightImage:(UIImage*)highlightImage;

@end
