//
//  ImagesScrollView.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 11/4/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IQMediaPickerController.h"

@interface ImagesScrollView : UIScrollView

@property (nonatomic, strong) NSMutableArray *eventMessages;
@property (nonatomic, strong) IQMediaPickerController *controller;
@property (nonatomic, strong) NSNumber *index;
- (void)loadContent;
@end
