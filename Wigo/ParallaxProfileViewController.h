//
//  ParallaxProfileViewController.h
//  Wigo
//
//  Created by Alex Grinman on 12/12/14.
//  Copyright (c) 2014 Alex Grinman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JPBParallaxBlurViewController.h"
#import "Globals.h"

@interface ParallaxProfileViewController : JPBParallaxBlurViewController

@property User *user;
@property STATE userState;

-(id)initWithUser:(User *)user;


@end
