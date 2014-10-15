//
//  GKImageCropView.h
//  GKImagePicker
//

//

#import <UIKit/UIKit.h>

@interface GKImageCropView : UIView

@property (nonatomic, strong) UIImage *imageToCrop;
@property (nonatomic, assign) CGSize cropSize;
@property (nonatomic, assign) BOOL resizableCropArea;

- (UIImage *)croppedImage;
- (CGRect)croppedArea;

@end
