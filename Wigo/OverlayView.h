//
//  OverlayView.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 2/11/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Delegate.h"

@interface OverlayView : UIView
@property(nonatomic,assign) id<CameraDelegate> cameraDelegate;
@end
