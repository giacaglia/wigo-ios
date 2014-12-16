//
//  ImageScrollView.m
//  Wigo
//
//  Created by Alex Grinman on 12/15/14.
//  Copyright (c) 2014 Alex Grinman. All rights reserved.
//

#import "ImageScrollView.h"
#import "UIImageView+ImageArea.h"

@interface ImageScrollView() {
    CGPoint _currentPoint;
    NSInteger _currentPage;
}
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) NSMutableArray *imageViews;

@end

@implementation ImageScrollView


- (instancetype)initWithFrame: (CGRect) frame imageURLs:(NSArray *)imageURLS infoDicts:(NSArray *)infoDicts areaDicts:(NSArray *)areaDicts {
    
    if (self = [super initWithFrame: frame]) {
        self.scrollView = [[UIScrollView alloc] initWithFrame: frame];
        self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.scrollView.autoresizesSubviews = YES;
        self.scrollView.delegate = self;
        self.scrollView.backgroundColor = [UIColor blackColor];
    
        [self addSubview: self.scrollView];
        
        _currentPage = 0;
        
        [self addImages: imageURLS infoDicts: infoDicts areaDicts: areaDicts];
    }
    
    return self;
}

- (void) addImages:(NSArray *)imageURLs infoDicts:(NSArray *)infoDicts areaDicts:(NSArray *)areaDicts {
    

    [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.imageViews = [[NSMutableArray alloc] init];
    for (int i = 0; i < [imageURLs count]; i++) {
        
        UIImageView *profileImgView = [self getNewProfileImageView: CGRectMake((self.frame.size.width + 10) * i, 0, self.frame.size.width, self.frame.size.width)];
        
        
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        spinner.frame = CGRectMake(0.0, 0.0, 40.0, 40.0);
        spinner.center = CGPointMake((self.frame.size.width + 10) * i + self.frame.size.width/2, self.frame.size.width/2);
        
        [self.scrollView addSubview:spinner];
        
        [spinner startAnimating];
        __weak UIActivityIndicatorView *weakSpinner = spinner;
        
        NSMutableDictionary *infoDict = [infoDicts objectAtIndex: i];
        
        NSDictionary *areaVal = [areaDicts objectAtIndex: i];
        
        [profileImgView setImageWithURL:[NSURL URLWithString:[imageURLs objectAtIndex:i]]
                              imageArea:areaVal
                               withInfo:infoDict
                              completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                                  [weakSpinner stopAnimating];
                                  
                                  if (i == 0) {
                                      dispatch_async(dispatch_get_main_queue(), ^{
                                          [self.delegate pageChangedTo: 0];
                                      });
                                  }
                              }];
        
        
        [self.imageViews addObject: profileImgView];
        [self.scrollView addSubview:profileImgView];
        
    }
    
    [self.scrollView setContentSize:CGSizeMake((self.frame.size.width + 10) * [imageURLs count] - 10, [[UIScreen mainScreen] bounds].size.width)];
}

- (UIImage *) getCurrentImage {
    if (_currentPage < self.imageViews.count) {
        UIImageView *imageView = ((UIImageView *)[self.imageViews objectAtIndex: _currentPage]);
        
        UIGraphicsBeginImageContext(CGSizeMake([[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.width));
        CGContextRef context = UIGraphicsGetCurrentContext();
        [imageView.layer renderInContext:context];
        UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return result;
        
    }

    return nil;
}


- (UIImageView *) getNewProfileImageView: (CGRect) frame {
    UIImageView *profileImgView = [[UIImageView alloc] init];
    profileImgView.contentMode = UIViewContentModeScaleAspectFill;
    profileImgView.clipsToBounds = YES;
    profileImgView.frame = frame;
    profileImgView.autoresizingMask = UIViewAutoresizingFlexibleWidth |UIViewAutoresizingFlexibleHeight;
    
    return profileImgView;
}

#pragma mark - UIScrollView Delegate
#pragma mark UIScrollView delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    CGFloat pageWidth = scrollView.frame.size.width;
    float fractionalPage = scrollView.contentOffset.x / pageWidth;
    NSInteger page = lround(fractionalPage);
    
    if (page != _currentPage) {
        _currentPage = page;
        [self.delegate pageChangedTo: page];
    }

}


-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    _currentPoint = scrollView.contentOffset;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate
{
    if (decelerate) {
        if (scrollView.contentOffset.x < _currentPoint.x) {
            [self stoppedScrollingToLeft:YES];
        } else if (scrollView.contentOffset.x >= _currentPoint.x) {
            [self stoppedScrollingToLeft:NO];
        }
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {

    if (scrollView.contentOffset.x < _currentPoint.x) {
        [self stoppedScrollingToLeft:YES];
    } else if (scrollView.contentOffset.x >= _currentPoint.x) {
        [self stoppedScrollingToLeft:NO];
    }
}

- (void)stoppedScrollingToLeft:(BOOL)leftBoolean
{
    CGFloat pageWidth = self.scrollView.frame.size.width; // you need to have a **iVar** with getter for scrollView
    float fractionalPage = self.scrollView.contentOffset.x / pageWidth;
    NSInteger page;
    if (leftBoolean) {
        if (fractionalPage - floor(fractionalPage) < 0.8) {
            page = floor(fractionalPage);
        }
        else {
            page = ceil(fractionalPage);
        }
    }
    else {
        if (fractionalPage - floor(fractionalPage) < 0.2) {
            page = floor(fractionalPage);
        }
        else {
            page = ceil(fractionalPage);
        }
    }
    [self.scrollView setContentOffset:CGPointMake((self.frame.size.width + 10) * page, 0.0f) animated:YES];
}


@end
