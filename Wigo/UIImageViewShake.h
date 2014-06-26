//
//  UIImageViewShake.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 6/11/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImageViewShake : UIImageView

- (void)newShake;

@property int direction;
@property int shakes;
@property CGRect originalFrame;
@property int sizeDifference;

@end
