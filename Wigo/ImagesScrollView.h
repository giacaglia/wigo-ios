//
//  ImagesScrollView.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 11/4/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImagesScrollView : UIScrollView

@property (nonatomic, strong) NSMutableArray *eventMessages;
- (void)loadContent;
@end
