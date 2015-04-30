//
//  WGCameraViewController.h
//  Wigo
//
//  Created by Gabriel Mahoney on 4/23/15.
//  Copyright (c) 2015 Gabriel Mahoney. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <AVFoundation/AVFoundation.h>


@protocol WGCameraViewControllerDelegate;

@class CIDetector;

@interface WGCameraViewController : UIViewController <UIGestureRecognizerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate>
{
    IBOutlet UIView *previewView;
    IBOutlet UISegmentedControl *camerasControl;
    AVCaptureVideoPreviewLayer *previewLayer;
    
    BOOL detectFaces;
    
    AVCaptureStillImageOutput *stillImageOutput;
    UIView *flashView;
    UIImage *square;
    BOOL isUsingFrontFacingCamera;
    CIDetector *faceDetector;
    CGFloat beginGestureScale;
    CGFloat effectiveScale;
}

@property (nonatomic,weak) id <WGCameraViewControllerDelegate> delegate;
@property (nonatomic,weak) AVCaptureDeviceInput *videoDeviceInput;

@property (nonatomic,strong) UIView *cameraOverlayView;

@property (nonatomic,readonly) BOOL isRecording;

- (void)takePictureWithCompletion:(void (^)(UIImage *image, NSDictionary *attachments, NSError *error))completion;
- (void)startRecordingVideo;
- (void)stopRecording;

- (void)switchCameras:(id)sender;
- (IBAction)handlePinchGesture:(UIGestureRecognizer *)sender;
- (IBAction)toggleFaceDetection:(id)sender;


@end


@protocol WGCameraViewControllerDelegate<NSObject>
@optional

- (void)cameraController:(WGCameraViewController *)controller didFinishPickingMediaWithInfo:(NSDictionary *)info;
- (void)cameraControllerDidCancel:(WGCameraViewController *)picker;

@end
