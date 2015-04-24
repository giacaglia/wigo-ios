//
//  WGCameraViewController.h
//  Wigo
//
//  Created by Gabriel Mahoney on 4/23/15.
//  Copyright (c) 2015 Gabriel Mahoney. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <AVFoundation/AVFoundation.h>


@class CIDetector;

@interface WGCameraViewController : UIViewController <UIGestureRecognizerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>
{
    IBOutlet UIView *previewView;
    IBOutlet UISegmentedControl *camerasControl;
    AVCaptureVideoPreviewLayer *previewLayer;
    AVCaptureVideoDataOutput *videoDataOutput;
    BOOL detectFaces;
    dispatch_queue_t videoDataOutputQueue;
    AVCaptureStillImageOutput *stillImageOutput;
    UIView *flashView;
    UIImage *square;
    BOOL isUsingFrontFacingCamera;
    CIDetector *faceDetector;
    CGFloat beginGestureScale;
    CGFloat effectiveScale;
}

@property (nonatomic,strong) UIView *cameraOverlayView;

- (IBAction)takePicture:(id)sender;
- (IBAction)switchCameras:(id)sender;
- (IBAction)handlePinchGesture:(UIGestureRecognizer *)sender;
- (IBAction)toggleFaceDetection:(id)sender;


@end
