//
//  WGCameraViewController.m
//  Wigo
//
//  Created by Gabriel Mahoney on 4/23/15.
//  Copyright (c) 2015 Gabriel Mahoney. All rights reserved.
//  Based on Apple's SquareCam sample app - https://developer.apple.com/library/ios/samplecode/SquareCam/Introduction/Intro.html

//  Additional help came from this page - http://www.ios-developer.net/iphone-ipad-programmer/development/camera/record-video-with-avcapturesession-2

// This StackOverflow answer on compressing camera video output directly was also EXTREMELY helpful
// http://stackoverflow.com/questions/4944083/can-use-avcapturevideodataoutput-and-avcapturemoviefileoutput-at-the-same-time
//

#import "WGCameraViewController.h"

#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>
#import <AssertMacros.h>
#import <AssetsLibrary/AssetsLibrary.h>

// comment this out to use default compression
#define kWGVideoAverageBitRate  937500

#define kWGVideoScale   0.7


#pragma mark-

// used for KVO observation of the @"capturingStillImage" property to perform flash bulb animation
static const NSString *AVCaptureStillImageIsCapturingStillImageContext = @"AVCaptureStillImageIsCapturingStillImageContext";

static CGFloat DegreesToRadians(CGFloat degrees) {return degrees * M_PI / 180;};

static int64_t frameNumber;

static void ReleaseCVPixelBuffer(void *pixel, const void *data, size_t size);
static void ReleaseCVPixelBuffer(void *pixel, const void *data, size_t size)
{
    CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)pixel;
    CVPixelBufferUnlockBaseAddress( pixelBuffer, 0 );
    CVPixelBufferRelease( pixelBuffer );
}

// create a CGImage with provided pixel buffer, pixel buffer must be uncompressed kCVPixelFormatType_32ARGB or kCVPixelFormatType_32BGRA
static OSStatus CreateCGImageFromCVPixelBuffer(CVPixelBufferRef pixelBuffer, CGImageRef *imageOut);
static OSStatus CreateCGImageFromCVPixelBuffer(CVPixelBufferRef pixelBuffer, CGImageRef *imageOut)
{
    OSStatus err = noErr;
    OSType sourcePixelFormat;
    size_t width, height, sourceRowBytes;
    void *sourceBaseAddr = NULL;
    CGBitmapInfo bitmapInfo;
    CGColorSpaceRef colorspace = NULL;
    CGDataProviderRef provider = NULL;
    CGImageRef image = NULL;
    
    sourcePixelFormat = CVPixelBufferGetPixelFormatType( pixelBuffer );
    if ( kCVPixelFormatType_32ARGB == sourcePixelFormat )
        bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaNoneSkipFirst;
    else if ( kCVPixelFormatType_32BGRA == sourcePixelFormat )
        bitmapInfo = kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst;
    else
        return -95014; // only uncompressed pixel formats
    
    sourceRowBytes = CVPixelBufferGetBytesPerRow( pixelBuffer );
    width = CVPixelBufferGetWidth( pixelBuffer );
    height = CVPixelBufferGetHeight( pixelBuffer );
    
    CVPixelBufferLockBaseAddress( pixelBuffer, 0 );
    sourceBaseAddr = CVPixelBufferGetBaseAddress( pixelBuffer );
    
    colorspace = CGColorSpaceCreateDeviceRGB();
    
    CVPixelBufferRetain( pixelBuffer );
    provider = CGDataProviderCreateWithData( (void *)pixelBuffer, sourceBaseAddr, sourceRowBytes * height, ReleaseCVPixelBuffer);
    image = CGImageCreate(width, height, 8, 32, sourceRowBytes, colorspace, bitmapInfo, provider, NULL, true, kCGRenderingIntentDefault);
    
bail:
    if ( err && image ) {
        CGImageRelease( image );
        image = NULL;
    }
    if ( provider ) CGDataProviderRelease( provider );
    if ( colorspace ) CGColorSpaceRelease( colorspace );
    *imageOut = image;
    return err;
}

// utility used by newSquareOverlayedImageForFeatures for
static CGContextRef CreateCGBitmapContextForSize(CGSize size);
static CGContextRef CreateCGBitmapContextForSize(CGSize size)
{
    CGContextRef    context = NULL;
    CGColorSpaceRef colorSpace;
    int             bitmapBytesPerRow;
    
    bitmapBytesPerRow = (size.width * 4);
    
    colorSpace = CGColorSpaceCreateDeviceRGB();
    context = CGBitmapContextCreate (NULL,
                                     size.width,
                                     size.height,
                                     8,      // bits per component
                                     bitmapBytesPerRow,
                                     colorSpace,
                                     (int)kCGImageAlphaPremultipliedLast);
    CGContextSetAllowsAntialiasing(context, NO);
    CGColorSpaceRelease( colorSpace );
    return context;
}

@implementation UIImage (RotationMethods)

- (UIImage *)imageRotatedByDegrees:(CGFloat)degrees
{
    // calculate the size of the rotated view's containing box for our drawing space
    UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.size.width, self.size.height)];
    CGAffineTransform t = CGAffineTransformMakeRotation(DegreesToRadians(degrees));
    rotatedViewBox.transform = t;
    CGSize rotatedSize = rotatedViewBox.frame.size;
    //[rotatedViewBox release];
    
    // Create the bitmap context
    UIGraphicsBeginImageContext(rotatedSize);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();
    
    // Move the origin to the middle of the image so we will rotate and scale around the center.
    CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
    
    //   // Rotate the image context
    CGContextRotateCTM(bitmap, DegreesToRadians(degrees));
    
    // Now, draw the rotated/scaled image into the context
    CGContextScaleCTM(bitmap, 1.0, -1.0);
    CGContextDrawImage(bitmap, CGRectMake(-self.size.width / 2, -self.size.height / 2, self.size.width, self.size.height), [self CGImage]);
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
    
}

@end


@interface WGCameraViewController () <AVCaptureAudioDataOutputSampleBufferDelegate>



@property (nonatomic,strong) AVCaptureSession *captureSession;

@property (nonatomic,strong) AVCaptureDeviceInput *videoDeviceInput;

@property (nonatomic,strong) AVAssetWriter *videoWriter;
@property (nonatomic,strong) AVAssetWriterInput* videoWriterInput;
@property (nonatomic,strong) AVCaptureMovieFileOutput *movieFileOutput;
@property (nonatomic,strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic,strong) AVCaptureAudioDataOutput *audioDataOutput;
@property (nonatomic,strong) dispatch_queue_t videoDataOutputQueue;
@property (nonatomic,strong) AVAssetWriterInputPixelBufferAdaptor *pixelBufferAdaptor;
@property (nonatomic,strong) AVAssetWriterInput *audioWriterInput;
@property (nonatomic,assign) CMTime startTime;

@property (nonatomic,copy) NSURL *videoOutputURL;

@end

@implementation WGCameraViewController


- (void)setupAVCapture
{
    
    
    _isRecording = NO;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),
                   ^{
    NSError *error = nil;
    
    self.captureSession = [AVCaptureSession new];
                       
    if ([self.captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
       [self.captureSession setSessionPreset:AVCaptureSessionPreset1280x720];
    }
    else {
       [self.captureSession setSessionPreset:AVCaptureSessionPresetMedium];
    }
    
    
    // Select a video device, make an input
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    self.videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if(error == nil) {
        NSLog(@"1");
        
        
//        NSError *configLockErr = nil;
//        [device lockForConfiguration:&configLockErr];
//        if(configLockErr) {
//            NSLog(@"Error locking device configuration: %@", configLockErr.localizedDescription);
//        }
//        else {
//            device.activeVideoMinFrameDuration = CMTimeMake(1, 5);
//            [device unlockForConfiguration];
//        }
        
        
        NSLog(@"max duration: %lld, %d", device.activeVideoMaxFrameDuration.value, device.activeVideoMaxFrameDuration.timescale);
        
        NSLog(@"min duration: %lld, %d", device.activeVideoMaxFrameDuration.value, device.activeVideoMinFrameDuration.timescale);
        
        

        
        
        self.isUsingFrontFacingCamera = NO;
        if ( [self.captureSession canAddInput:self.videoDeviceInput] )
            [self.captureSession addInput:self.videoDeviceInput];
        
        
        error = nil;
        AVCaptureDevice *mic = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        AVCaptureDeviceInput *micInput = [AVCaptureDeviceInput deviceInputWithDevice:mic error:&error];
        
        if(!error) {
            if([self.captureSession canAddInput:micInput]) {
                [self.captureSession addInput:micInput];
            }
            else {
                NSLog(@"unable to add microphone input");
            }
        }
        else {
            NSLog(@"error adding mic: %@", error.localizedDescription);
        }
        
        // Make a still image output
        stillImageOutput = [AVCaptureStillImageOutput new];
//        [stillImageOutput addObserver:self forKeyPath:@"capturingStillImage" options:NSKeyValueObservingOptionNew context:(__bridge void *)((NSString *)AVCaptureStillImageIsCapturingStillImageContext)];
        if ( [self.captureSession canAddOutput:stillImageOutput] )
        [self.captureSession addOutput:stillImageOutput];
        
        _movieFileOutput = [AVCaptureMovieFileOutput new];
        
    
        // Make a video data output
        self.videoDataOutput = [AVCaptureVideoDataOutput new];
        AVCaptureConnection *videoConnection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
        [videoConnection setEnabled:NO];
        
        
        self.audioDataOutput = [AVCaptureAudioDataOutput new];
        AVCaptureConnection *audioConnection = [self.audioDataOutput connectionWithMediaType:AVMediaTypeAudio];
        [audioConnection setEnabled:NO];
        
        
        /*
         UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
         AVCaptureVideoOrientation avcaptureOrientation = [self avOrientationForDeviceOrientation:curDeviceOrientation];
         [stillImageConnection setVideoOrientation:avcaptureOrientation];
         */
        
        
        // we want BGRA, both CoreGraphics and OpenGL work well with 'BGRA'
        NSDictionary *rgbOutputSettings = [NSDictionary dictionaryWithObject:
                                           [NSNumber numberWithInt:kCMPixelFormat_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        [self.videoDataOutput setVideoSettings:rgbOutputSettings];
        
        if ( [self.captureSession canAddOutput:self.videoDataOutput] ) {
            [self.captureSession addOutput:self.videoDataOutput];
        }
        
        if ( [self.captureSession canAddOutput:self.audioDataOutput] ) {
            [self.captureSession addOutput:self.audioDataOutput];
        }
        
        
        //[videoDataOutput setAlwaysDiscardsLateVideoFrames:YES]; // discard if the data output queue is blocked (as we process the still image)
        
        // create a serial dispatch queue used for the sample buffer delegate as well as when a still image is captured
        // a serial dispatch queue must be used to guarantee that video frames will be delivered in order
        // see the header doc for setSampleBufferDelegate:queue: for more information
        
        self.videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", NULL);//DISPATCH_QUEUE_SERIAL);
        [self.videoDataOutput setSampleBufferDelegate:self queue:self.videoDataOutputQueue];
        [self.audioDataOutput setSampleBufferDelegate:self queue:self.videoDataOutputQueue];
        
        NSLog(@"2");
        
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           effectiveScale = 1.0;
                           previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
                           [previewLayer setBackgroundColor:[[UIColor blackColor] CGColor]];
                           [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
                           CALayer *rootLayer = [previewView layer];
                           [rootLayer setMasksToBounds:YES];
                           [previewLayer setFrame:[rootLayer bounds]];
                           [rootLayer addSublayer:previewLayer];
                           NSLog(@"3");
                           dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),
                                          ^{
                                              [self.captureSession startRunning];
                                          });
                       });
    }
    else {
    

        //[session release];
        if (error) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Failed with error %d", (int)[error code]]
                                                                message:[error localizedDescription]
                                                               delegate:nil
                                                      cancelButtonTitle:@"Dismiss"
                                                      otherButtonTitles:nil];
            [alertView show];
            //[alertView release];
            [self teardownAVCapture];
        }
    }
                       
                   });
}

// clean up capture setup
- (void)teardownAVCapture
{
    //[videoDataOutput release];
    //if (videoDataOutputQueue)
    //    dispatch_release(videoDataOutputQueue);
    //if([stillImageOutput])
    
    [self.captureSession removeOutput:self.audioDataOutput];
    [self.captureSession removeOutput:self.videoDataOutput];
    
    //[stillImageOutput removeObserver:self forKeyPath:@"capturingStillImage"];
    //[stillImageOutput release];
    [previewLayer removeFromSuperlayer];
    //[previewLayer release];
    
    [self.captureSession stopRunning];
    self.captureSession = nil;
    
    _isRecording = NO;
}
//
//// perform a flash bulb animation using KVO to monitor the value of the capturingStillImage property of the AVCaptureStillImageOutput class
//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
//{
//    if ( context == (__bridge void *)(AVCaptureStillImageIsCapturingStillImageContext) ) {
//        BOOL isCapturingStillImage = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
//        
//        if ( isCapturingStillImage ) {
//            // do flash bulb like animation
//            flashView = [[UIView alloc] initWithFrame:[previewView frame]];
//            [flashView setBackgroundColor:[UIColor whiteColor]];
//            [flashView setAlpha:0.f];
//            [[[self view] window] addSubview:flashView];
//            
//            [UIView animateWithDuration:.4f
//                             animations:^{
//                                 [flashView setAlpha:1.f];
//                             }
//             ];
//        }
//        else {
//            [UIView animateWithDuration:.4f
//                             animations:^{
//                                 [flashView setAlpha:0.f];
//                             }
//                             completion:^(BOOL finished){
//                                 [flashView removeFromSuperview];
//                                 //[flashView release];
//                                 flashView = nil;
//                             }
//             ];
//        }
//    }
//}

// utility routing used during image capture to set up capture orientation
- (AVCaptureVideoOrientation)avOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation
{
    AVCaptureVideoOrientation result = (int)deviceOrientation;
    if ( deviceOrientation == UIDeviceOrientationLandscapeLeft )
        result = AVCaptureVideoOrientationLandscapeRight;
    else if ( deviceOrientation == UIDeviceOrientationLandscapeRight )
        result = AVCaptureVideoOrientationLandscapeLeft;
    return result;
}





- (void)takePictureWithCompletion:(void (^)(UIImage *image, NSDictionary *attachments, NSError *error))completion
{
    AVCaptureDevice *currentCamera = self.videoDeviceInput.device;
    
    if(self.flashEnabled &&
       [currentCamera hasFlash] &&
       [currentCamera isFlashModeSupported:AVCaptureFlashModeOn]) {
        
        if(currentCamera.flashMode != AVCaptureFlashModeOn) {
            NSError *err;
            [currentCamera lockForConfiguration:&err];
            if(!err) {
                [currentCamera setFlashMode:AVCaptureFlashModeOn];
            }
            else {
                NSLog(@"flash lock error: %@", err.localizedDescription);
            }
        }
    }
    else {
        if(currentCamera.flashMode != AVCaptureFlashModeOff) {
            
            NSError *err;
            [currentCamera lockForConfiguration:&err];
            if(!err) {
                [currentCamera setFlashMode:AVCaptureFlashModeOff];
            }
            else {
                NSLog(@"flash lock error: %@", err.localizedDescription);
            }
        }
    }
    
    // Find out the current orientation and tell the still image output.
    AVCaptureConnection *stillImageConnection = [stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
    AVCaptureVideoOrientation avcaptureOrientation = [self avOrientationForDeviceOrientation:curDeviceOrientation];
    [stillImageConnection setVideoOrientation:avcaptureOrientation];
    [stillImageConnection setVideoScaleAndCropFactor:effectiveScale];
    


    [stillImageOutput setOutputSettings:[NSDictionary dictionaryWithObject:AVVideoCodecJPEG
                                                                        forKey:AVVideoCodecKey]];
    
    [stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection
     
      completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
          if (error) {
              completion(nil, nil, error);
          }
          else {
              
              // trivial simple JPEG case
              NSData *jpegData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
              UIImage *ret = [[UIImage alloc] initWithData:jpegData];
              
              CFDictionaryRef attachmentsCF = CMCopyDictionaryOfAttachments(kCFAllocatorDefault,
                                                                          imageDataSampleBuffer,
                                                                          kCMAttachmentMode_ShouldPropagate);
              
              NSDictionary *attachments = (__bridge NSDictionary *)attachmentsCF;
              
              if (attachments) {
                  CFRelease(attachmentsCF);
              }
              completion (ret, attachments, nil);
          }
      }
     ];
}

// turn on/off face detection
- (IBAction)toggleFaceDetection:(id)sender
{
//    detectFaces = [(UISwitch *)sender isOn];
//    [[videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:detectFaces];
//    if (!detectFaces) {
//        dispatch_async(dispatch_get_main_queue(), ^(void) {
//            // clear out any squares currently displaying.
//            [self drawFaceBoxesForFeatures:[NSArray array] forVideoBox:CGRectZero orientation:UIDeviceOrientationPortrait];
//        });
//    }
}



- (void)dealloc
{
    
    [self teardownAVCapture];
    // [faceDetector release];
    // [square release];
    // [super dealloc];
}

// use front/back camera
- (void)switchCameras:(id)sender
{
    AVCaptureDevicePosition desiredPosition;
    if (self.isUsingFrontFacingCamera)
        desiredPosition = AVCaptureDevicePositionBack;
    else
        desiredPosition = AVCaptureDevicePositionFront;
    
    for (AVCaptureDevice *d in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if ([d position] == desiredPosition) {
            [self.captureSession beginConfiguration];
            
            [self.captureSession removeInput:self.videoDeviceInput];
            self.videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:d error:nil];
            [self.captureSession addInput:self.videoDeviceInput];
            
            [self.captureSession commitConfiguration];
            break;
        }
    }
    self.isUsingFrontFacingCamera = !self.isUsingFrontFacingCamera;
}

- (void)toggleFlash {
    if(self.flashEnabled) {
        self.flashEnabled = NO;
        
    }
    else {
        self.flashEnabled = YES;
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)loadView {
    [super loadView];
    previewView = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:previewView];
    
    [self.view addSubview:self.cameraOverlayView];
}

- (void)setCameraOverlayView:(UIView *)cameraOverlayView {
    _cameraOverlayView = cameraOverlayView;
    [self.view addSubview:cameraOverlayView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSLog(@"setting up av capture");
    [self setupAVCapture];
    NSLog(@"av capture setup complete");
    square = [UIImage imageNamed:@"squarePNG"];
    NSDictionary *detectorOptions = [[NSDictionary alloc] initWithObjectsAndKeys:CIDetectorAccuracyLow, CIDetectorAccuracy, nil];
    faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:detectorOptions];
    //[detectorOptions release];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark Video Recording

- (void)startRecordingVideo {
    
    
    // set up torch
    
    AVCaptureDevice *currentCamera = self.videoDeviceInput.device;
    
    if(self.flashEnabled &&
       [currentCamera hasTorch] &&
       [currentCamera isTorchModeSupported:AVCaptureTorchModeOn]) {
        
        if(currentCamera.torchMode != AVCaptureTorchModeOn) {
            NSError *err;
            [currentCamera lockForConfiguration:&err];
            if(!err) {
                [currentCamera setTorchMode:AVCaptureTorchModeOn];
            }
            else {
                NSLog(@"torch lock error: %@", err.localizedDescription);
            }
        }
    }
    else {
        if(currentCamera.torchMode != AVCaptureTorchModeOff) {
            
            NSError *err;
            [currentCamera lockForConfiguration:&err];
            if(!err) {
                [currentCamera setTorchMode:AVCaptureTorchModeOff];
            }
            else {
                NSLog(@"torch lock error: %@", err.localizedDescription);
            }
        }
    }
    
    _startTime = kCMTimeZero;
    
    
    self.videoOutputURL = [WGCameraViewController tempVideoURL];
    
    [[self.audioDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:YES];
    [[self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:YES];
    
    
    NSDictionary *recommendedSettings = [self.videoDataOutput recommendedVideoSettingsForAssetWriterWithOutputFileType:AVFileTypeMPEG4];
    
    NSNumber *videoWidth = recommendedSettings[AVVideoWidthKey];
    NSNumber *videoHeight= recommendedSettings[AVVideoHeightKey];
    
    NSNumber *recommendedBitRate = recommendedSettings[AVVideoCompressionPropertiesKey][AVVideoAverageBitRateKey];
    
#ifdef kWGVideoAverageBitRate
    recommendedBitRate = [NSNumber numberWithInt:kWGVideoAverageBitRate];
#endif
    
#ifdef kWGVideoScale
    // width and height need to be multiples of 2
    CGFloat width = ([videoWidth floatValue] * kWGVideoScale);
    int widthInt = ((int)(width*0.5+0.5))*2;
    videoWidth = [NSNumber numberWithInt:widthInt];
    
    CGFloat height = ([videoHeight floatValue] * kWGVideoScale);
    int heightInt = ((int)(height*0.5+0.5))*2;
    videoHeight = [NSNumber numberWithInt:heightInt];
#endif
    
    
    NSDictionary *videoWriterCompressionSettings =  [NSDictionary dictionaryWithObjectsAndKeys:recommendedBitRate, AVVideoAverageBitRateKey, nil];
    
    
    NSDictionary *videoWriterSettings = @{AVVideoCodecKey:AVVideoCodecH264,
                                          AVVideoCompressionPropertiesKey:videoWriterCompressionSettings,
                                          AVVideoWidthKey:videoWidth,
                                          AVVideoHeightKey:videoHeight};
    
    
    self.videoWriterInput = [AVAssetWriterInput
                                            assetWriterInputWithMediaType:AVMediaTypeVideo
                                            outputSettings:videoWriterSettings];
    
    self.videoWriterInput.expectsMediaDataInRealTime = YES;
    
    // rotate video to portrait mode
    self.videoWriterInput.transform = CGAffineTransformMake(0.0,1.0,-1.0,0.0,[videoHeight floatValue],0.0);
    
    
    /* I'm going to push pixel buffers to it, so will need a
     AVAssetWriterPixelBufferAdaptor, to expect the same 32BGRA input as I've
     asked the AVCaptureVideDataOutput to supply */
    
    self.pixelBufferAdaptor =
    [[AVAssetWriterInputPixelBufferAdaptor alloc]
     initWithAssetWriterInput:self.videoWriterInput
     sourcePixelBufferAttributes:
     [NSDictionary dictionaryWithObjectsAndKeys:
      [NSNumber numberWithInt:kCVPixelFormatType_32BGRA],
      kCVPixelBufferPixelFormatTypeKey,
      nil]];
    
    //setup audio writer
    
    NSDictionary *recommendedAudioSettings = [self.audioDataOutput recommendedAudioSettingsForAssetWriterWithOutputFileType:AVFileTypeMPEG4];
    
    self.audioWriterInput = [AVAssetWriterInput
                             assetWriterInputWithMediaType:AVMediaTypeAudio
                             outputSettings:recommendedAudioSettings];
    
    self.audioWriterInput.expectsMediaDataInRealTime = YES;
    
    
    
    NSError *videoWriterError;
    
    
    
    self.videoWriter = [[AVAssetWriter alloc]
                                  initWithURL:self.videoOutputURL
                                  fileType:AVFileTypeMPEG4
                                  error:&videoWriterError];
    
    
    
    
    frameNumber = 0;
    
    _isRecording = YES;
    
    [self.videoWriter addInput:self.videoWriterInput];
    [self.videoWriter addInput:self.audioWriterInput];
    
    NSLog(@"starting writing");
    [self.videoWriter startWriting];
//    [self.videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    
    
    
}

- (void)stopRecording {
    //[self.movieFileOutput stopRecording];
    
    _isRecording = NO;
    
    [[self.audioDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:NO];
    [[self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:NO];
    
    [self.videoWriter finishWritingWithCompletionHandler:^{
        
        
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           
                           NSLog(@"video writer status: %ld", (long)self.videoWriter.status);
                           
                           NSDictionary *dict = @{UIImagePickerControllerMediaType:(NSString *)kUTTypeMovie,
                                                  UIImagePickerControllerMediaURL:self.videoOutputURL};
                           
                           
                           [self.delegate cameraController:self
                             didFinishPickingMediaWithInfo:dict];
                       });
        
        
        
    }];
}




#pragma mark AVCaptureFileOutputRecordingDelegate methods


- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    
    //NSLog(@"video writer status: %d", (int)self.videoWriter.status);
    
    if(!self.isRecording) {
        return;
    }
    
    switch (self.videoWriter.status) {
        case AVAssetWriterStatusUnknown:
            
            
            
//            if(captureOutput == self.audioDataOutput) {
//                NSLog(@"starting audio with time - ");
//                CMTimeShow(_startTime);
//            }
//            else if(captureOutput == self.videoDataOutput) {
//                NSLog(@"starting video with time - ");
//                CMTimeShow(_startTime);
//            }

            
            //[self.videoWriter startWriting];
            
            //[self.videoWriter startSessionAtSourceTime:kCMTimeZero];
            
            
            CMTimeShow(_startTime);
            
            //Break if not ready, otherwise fall through.
            if (self.videoWriter.status != AVAssetWriterStatusWriting) {
                break ;
            }
//            break;
            
        case AVAssetWriterStatusWriting:
            
            if (_startTime.value == 0) {
                _startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                [self.videoWriter startSessionAtSourceTime:_startTime];
            }
            
            if(captureOutput == self.videoDataOutput) {
                
                @try {
                    
                    if(! self.videoWriterInput.readyForMoreMediaData) {
                        break;
                    }
                    
                    //NSLog(@"writing video");
//
//                    if(! [self.videoWriterInput appendSampleBuffer:sampleBuffer]) {
//                        NSLog(@"Video writing error");
//                    }

                    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
                    
//                    CMTime pt = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
//                    pt = CMTimeSubtract(pt, _startTime);
                    
                    CMTime pt = CMTimeMake(frameNumber,30);
                    pt = CMTimeAdd(pt, _startTime);
                    
//                    NSLog(@"sample buffer time");
//                    CMTimeShow(CMSampleBufferGetPresentationTimeStamp(sampleBuffer));
//                    CMTimeShow(pt);
                    
                    if(! [self.pixelBufferAdaptor appendPixelBuffer:imageBuffer
                                               withPresentationTime:pt]) {
                        NSLog(@"error writing pixel buffer");
                    }
                    //NSLog(@"appending frame %lld", frameNumber);
                    frameNumber++;
                    
                    
                }
                @catch (NSException *e) {
                    NSLog(@"Video Exception Exception: %@", [e reason]);
                }
            }
            else if(captureOutput == self.audioDataOutput) {
                
                @try {
                    if(! self.audioWriterInput.readyForMoreMediaData) {
                        break;
                    }
                    
//                    CMTime pt = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
//                    pt = CMTimeSubtract(pt, _startTime);
//                    CMSampleBufferSetOutputPresentationTimeStamp(sampleBuffer, pt);
                    
                    //NSLog(@"writing audio");
                    if(! [self.audioWriterInput appendSampleBuffer:sampleBuffer]) {
                        NSLog(@"Audio writing error");
                    }
                }
                @catch (NSException *e) {
                    NSLog(@"Audio Exception: %@", [e reason]);
                }
            }
            
            
            break;
        case AVAssetWriterStatusCompleted:
            return;
        case AVAssetWriterStatusFailed:
            NSLog(@"critical error writing queues");
            
            [self stopRecording];
            return;
        case AVAssetWriterStatusCancelled:
            break;
    }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput
  didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    
    NSString *droppedReason = @"";
    
    CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer,  kCMAttachmentMode_ShouldPropagate);
    
    
    if(attachments) {
        NSDictionary *dict = (__bridge NSDictionary *)attachments;
        droppedReason = dict[(NSString *)kCMSampleBufferAttachmentKey_DroppedFrameReason];
    }
    
    if(captureOutput == self.videoDataOutput) {
        NSLog(@"dropped video sample buffer - writer status: %ld, reason: %@", self.videoWriter.status, droppedReason);
    }
    else if(captureOutput == self.audioDataOutput) {
        NSLog(@"dropped audio sample buffer - writer status: %ld, reason: %@", self.videoWriter.status, droppedReason);
    }
    
}


- (void)captureOutput:(AVCaptureFileOutput *)captureOutput
didStartRecordingToOutputFileAtURL:(NSURL *)fileURL
      fromConnections:(NSArray *)connections {
    NSLog(@"started recording");
    
    NSLog(@"connections: %@", connections.description);
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput
didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
      fromConnections:(NSArray *)connections
                error:(NSError *)error {
    
    [self.captureSession removeOutput:self.movieFileOutput];
    
    if(error) {
        NSLog(@"error finishing movie");
        
        // signal delegate that an error occurred
        [self.delegate cameraControllerDidCancel:self];
        return;
    }
    
    AVCaptureDevice *device = self.videoDeviceInput.device;
    
    NSError *configLockErr;
    [device lockForConfiguration:&configLockErr];
    if(!configLockErr) {
        device.activeVideoMinFrameDuration = kCMTimeInvalid;
    }
    else {
        NSLog(@"config lock error: %@", configLockErr.localizedDescription);
    }
    
    BOOL recordedSuccessfully = YES;
    if ([error code] != noErr) {
        // A problem occurred: Find out if the recording was successful.
        id value = [[error userInfo] objectForKey:AVErrorRecordingSuccessfullyFinishedKey];
        if (value) {
            recordedSuccessfully = [value boolValue];
            
        }
    }
    
    if(recordedSuccessfully) {
        
        NSURL *fileURL = [WGCameraViewController tempVideoURL];
        
        NSData *fileData = [NSData dataWithContentsOfURL:outputFileURL];
        NSLog(@"original file length: %ld", (long)fileData.length);
        
//        [self convertVideoToLowQuailtyWithInputURL:outputFileURL
//                                         outputURL:fileURL];
        
//        NSDictionary *dict = @{UIImagePickerControllerMediaType:(NSString *)kUTTypeMovie,
//                               UIImagePickerControllerMediaURL:outputFileURL};
//        
//        
//        [self.delegate cameraController:self
//          didFinishPickingMediaWithInfo:dict];
        
        
    }
    else {
        
    }

}





// random string for tmp file name
// (hat tip http://stackoverflow.com/questions/2633801/generate-a-random-alphanumeric-string-in-cocoa )

+ (NSURL *)tempVideoURL {
    
    NSString *tempDirectory;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    if ([paths count] > 0) {
        tempDirectory = [paths objectAtIndex:0];
        
        NSString *randomString = [WGCameraViewController randomStringWithLength:8];
        return [NSURL fileURLWithPath:[tempDirectory stringByAppendingFormat:@"/%@.mp4", randomString]];
    }
    
    return nil;
}

+ (NSString *)randomStringWithLength:(int)length {
    
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

    NSMutableString *randomString = [NSMutableString stringWithCapacity:length];
    
    for (int i = 0; i < length; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform((uint)[letters length])]];
    }
    
    return [NSString stringWithString:randomString];
    
}



@end
