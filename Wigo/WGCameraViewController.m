//
//  WGCameraViewController.m
//  Wigo
//
//  Created by Gabriel Mahoney on 4/23/15.
//  Copyright (c) 2015 Gabriel Mahoney. All rights reserved.
//  Based on Apple's SquareCam sample app - https://developer.apple.com/library/ios/samplecode/SquareCam/Introduction/Intro.html

//  Additional help came from this page - http://www.ios-developer.net/iphone-ipad-programmer/development/camera/record-video-with-avcapturesession-2
//

#import "WGCameraViewController.h"

#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>
#import <AssertMacros.h>
#import <AssetsLibrary/AssetsLibrary.h>

#define kWGVideoAverageBitRate  937500
#define kWGVideoInputMinFrameDuration  CMTimeMake(1,30)


#pragma mark-

// used for KVO observation of the @"capturingStillImage" property to perform flash bulb animation
static const NSString *AVCaptureStillImageIsCapturingStillImageContext = @"AVCaptureStillImageIsCapturingStillImageContext";

static CGFloat DegreesToRadians(CGFloat degrees) {return degrees * M_PI / 180;};

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


@interface WGCameraViewController ()

@property (nonatomic,strong) AVAssetWriter *videoWriter;

@end

@implementation WGCameraViewController


- (void)setupAVCapture
{
    
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
        
        

        
        
        isUsingFrontFacingCamera = NO;
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
        [stillImageOutput addObserver:self forKeyPath:@"capturingStillImage" options:NSKeyValueObservingOptionNew context:(__bridge void *)((NSString *)AVCaptureStillImageIsCapturingStillImageContext)];
        if ( [self.captureSession canAddOutput:stillImageOutput] )
        [self.captureSession addOutput:stillImageOutput];
        
        _movieFileOutput = [AVCaptureMovieFileOutput new];
        
    
        // Make a video data output
        videoDataOutput = [AVCaptureVideoDataOutput new];
        
        // we want BGRA, both CoreGraphics and OpenGL work well with 'BGRA'
        NSDictionary *rgbOutputSettings = [NSDictionary dictionaryWithObject:
                                           [NSNumber numberWithInt:kCMPixelFormat_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        [videoDataOutput setVideoSettings:rgbOutputSettings];
        [videoDataOutput setAlwaysDiscardsLateVideoFrames:YES]; // discard if the data output queue is blocked (as we process the still image)
        
        // create a serial dispatch queue used for the sample buffer delegate as well as when a still image is captured
        // a serial dispatch queue must be used to guarantee that video frames will be delivered in order
        // see the header doc for setSampleBufferDelegate:queue: for more information
        videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
        [videoDataOutput setSampleBufferDelegate:self queue:videoDataOutputQueue];
        
        if ( [self.captureSession canAddOutput:videoDataOutput] )
            [self.captureSession addOutput:videoDataOutput];
        [[videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:NO];
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
    [stillImageOutput removeObserver:self forKeyPath:@"capturingStillImage"];
    //[stillImageOutput release];
    [previewLayer removeFromSuperlayer];
    //[previewLayer release];
    
    self.captureSession = nil;
}

// perform a flash bulb animation using KVO to monitor the value of the capturingStillImage property of the AVCaptureStillImageOutput class
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ( context == (__bridge void *)(AVCaptureStillImageIsCapturingStillImageContext) ) {
        BOOL isCapturingStillImage = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        
        if ( isCapturingStillImage ) {
            // do flash bulb like animation
            flashView = [[UIView alloc] initWithFrame:[previewView frame]];
            [flashView setBackgroundColor:[UIColor whiteColor]];
            [flashView setAlpha:0.f];
            [[[self view] window] addSubview:flashView];
            
            [UIView animateWithDuration:.4f
                             animations:^{
                                 [flashView setAlpha:1.f];
                             }
             ];
        }
        else {
            [UIView animateWithDuration:.4f
                             animations:^{
                                 [flashView setAlpha:0.f];
                             }
                             completion:^(BOOL finished){
                                 [flashView removeFromSuperview];
                                 //[flashView release];
                                 flashView = nil;
                             }
             ];
        }
    }
}

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

// utility routine to create a new image with the red square overlay with appropriate orientation
// and return the new composited image which can be saved to the camera roll
- (CGImageRef)newSquareOverlayedImageForFeatures:(NSArray *)features
                                       inCGImage:(CGImageRef)backgroundImage
                                 withOrientation:(UIDeviceOrientation)orientation
                                     frontFacing:(BOOL)isFrontFacing
{
    CGImageRef returnImage = NULL;
    CGRect backgroundImageRect = CGRectMake(0., 0., CGImageGetWidth(backgroundImage), CGImageGetHeight(backgroundImage));
    CGContextRef bitmapContext = CreateCGBitmapContextForSize(backgroundImageRect.size);
    CGContextClearRect(bitmapContext, backgroundImageRect);
    CGContextDrawImage(bitmapContext, backgroundImageRect, backgroundImage);
    CGFloat rotationDegrees = 0.;
    
    switch (orientation) {
        case UIDeviceOrientationPortrait:
            rotationDegrees = -90.;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            rotationDegrees = 90.;
            break;
        case UIDeviceOrientationLandscapeLeft:
            if (isFrontFacing) rotationDegrees = 180.;
            else rotationDegrees = 0.;
            break;
        case UIDeviceOrientationLandscapeRight:
            if (isFrontFacing) rotationDegrees = 0.;
            else rotationDegrees = 180.;
            break;
        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationFaceDown:
        default:
            break; // leave the layer in its last known orientation
    }
    UIImage *rotatedSquareImage = [square imageRotatedByDegrees:rotationDegrees];
    
    // features found by the face detector
    for ( CIFaceFeature *ff in features ) {
        CGRect faceRect = [ff bounds];
        CGContextDrawImage(bitmapContext, faceRect, [rotatedSquareImage CGImage]);
    }
    returnImage = CGBitmapContextCreateImage(bitmapContext);
    CGContextRelease (bitmapContext);
    
    return returnImage;
}

// utility routine used after taking a still image to write the resulting image to the camera roll
- (BOOL)writeCGImageToCameraRoll:(CGImageRef)cgImage withMetadata:(NSDictionary *)metadata
{
    CFMutableDataRef destinationData = CFDataCreateMutable(kCFAllocatorDefault, 0);
    CGImageDestinationRef destination = CGImageDestinationCreateWithData(destinationData,
                                                                         CFSTR("public.jpeg"),
                                                                         1,
                                                                         NULL);
    BOOL success = (destination != NULL);
    if(success) {
        
        // require(success, bail);
        
        const float JPEGCompQuality = 0.85f; // JPEGHigherQuality
        CFMutableDictionaryRef optionsDict = NULL;
        CFNumberRef qualityNum = NULL;
        
        qualityNum = CFNumberCreate(0, kCFNumberFloatType, &JPEGCompQuality);
        if ( qualityNum ) {
            optionsDict = CFDictionaryCreateMutable(0, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
            if ( optionsDict )
                CFDictionarySetValue(optionsDict, kCGImageDestinationLossyCompressionQuality, qualityNum);
            CFRelease( qualityNum );
        }
        
        CGImageDestinationAddImage( destination, cgImage, optionsDict );
        success = CGImageDestinationFinalize( destination );
        
        if ( optionsDict )
            CFRelease(optionsDict);
        
        //require(success, bail);
        if(success) {
            
            CFRetain(destinationData);
            ALAssetsLibrary *library = [ALAssetsLibrary new];
            [library writeImageDataToSavedPhotosAlbum:(__bridge id)destinationData metadata:metadata completionBlock:^(NSURL *assetURL, NSError *error) {
                if (destinationData)
                    CFRelease(destinationData);
            }];
            //[library release];
        }
    }
    
    if (destinationData)
        CFRelease(destinationData);
    if (destination)
        CFRelease(destination);
    return success;
}

// utility routine to display error aleart if takePicture fails
- (void)displayErrorOnMainQueue:(NSError *)error withMessage:(NSString *)message
{
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ (%d)", message, (int)[error code]]
                                                            message:[error localizedDescription]
                                                           delegate:nil
                                                  cancelButtonTitle:@"Dismiss"
                                                  otherButtonTitles:nil];
        [alertView show];
    });
}

- (void)takePictureWithCompletion:(void (^)(UIImage *image, NSDictionary *attachments, NSError *error))completion
{
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

- (void)startRecordingVideo {
    
//    AVCaptureConnection *videoConnection = [videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
//    UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
//    AVCaptureVideoOrientation avcaptureOrientation = [self avOrientationForDeviceOrientation:curDeviceOrientation];
//    [stillImageConnection setVideoOrientation:avcaptureOrientation];
//    [stillImageConnection setVideoScaleAndCropFactor:effectiveScale];
    
    
    if ([self.captureSession canAddOutput:self.movieFileOutput]) {
        [self.captureSession addOutput:self.movieFileOutput];
        
        
//        if (CaptureConnection.supportsVideoMinFrameDuration)
//            CaptureConnection.videoMinFrameDuration = CMTimeMake(1, CAPTURE_FRAMES_PER_SECOND);
//        if (CaptureConnection.supportsVideoMaxFrameDuration)
//            CaptureConnection.videoMaxFrameDuration = CMTimeMake(1, CAPTURE_FRAMES_PER_SECOND);
//        
//        CMTimeShow(CaptureConnection.videoMinFrameDuration);
//        CMTimeShow(CaptureConnection.videoMaxFrameDuration);
        
        
        AVCaptureDevice *device = self.videoDeviceInput.device;
        
        CMTimeShow(device.activeVideoMinFrameDuration);
        CMTimeShow(device.activeVideoMaxFrameDuration);
        
        NSError *configLockErr = nil;
        [device lockForConfiguration:&configLockErr];
        if(configLockErr) {
            NSLog(@"Error locking device configuration: %@", configLockErr.localizedDescription);
        }
        else {
            device.activeVideoMinFrameDuration = kWGVideoInputMinFrameDuration;
            [device unlockForConfiguration];
        }
        
        CMTimeShow(device.activeVideoMinFrameDuration);
        CMTimeShow(device.activeVideoMaxFrameDuration);
        
        NSURL *fileURL = [WGCameraViewController tempVideoURL];
        
        [self.movieFileOutput startRecordingToOutputFileURL:fileURL
                                          recordingDelegate:self];
        
    }
    else {
        // Handle the failure.
        NSLog(@"error starting recording");
    }
    
}

- (void)stopRecording {
    [self.movieFileOutput stopRecording];
}

// turn on/off face detection
- (IBAction)toggleFaceDetection:(id)sender
{
    detectFaces = [(UISwitch *)sender isOn];
    [[videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:detectFaces];
    if (!detectFaces) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            // clear out any squares currently displaying.
            [self drawFaceBoxesForFeatures:[NSArray array] forVideoBox:CGRectZero orientation:UIDeviceOrientationPortrait];
        });
    }
}

// find where the video box is positioned within the preview layer based on the video size and gravity
+ (CGRect)videoPreviewBoxForGravity:(NSString *)gravity frameSize:(CGSize)frameSize apertureSize:(CGSize)apertureSize
{
    CGFloat apertureRatio = apertureSize.height / apertureSize.width;
    CGFloat viewRatio = frameSize.width / frameSize.height;
    
    CGSize size = CGSizeZero;
    if ([gravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
        if (viewRatio > apertureRatio) {
            size.width = frameSize.width;
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
        } else {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
            size.height = frameSize.height;
        }
    } else if ([gravity isEqualToString:AVLayerVideoGravityResizeAspect]) {
        if (viewRatio > apertureRatio) {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
            size.height = frameSize.height;
        } else {
            size.width = frameSize.width;
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
        }
    } else if ([gravity isEqualToString:AVLayerVideoGravityResize]) {
        size.width = frameSize.width;
        size.height = frameSize.height;
    }
    
    CGRect videoBox;
    videoBox.size = size;
    if (size.width < frameSize.width)
        videoBox.origin.x = (frameSize.width - size.width) / 2;
    else
        videoBox.origin.x = (size.width - frameSize.width) / 2;
    
    if ( size.height < frameSize.height )
        videoBox.origin.y = (frameSize.height - size.height) / 2;
    else
        videoBox.origin.y = (size.height - frameSize.height) / 2;
    
    return videoBox;
}

// called asynchronously as the capture output is capturing sample buffers, this method asks the face detector (if on)
// to detect features and for each draw the red square in a layer and set appropriate orientation
- (void)drawFaceBoxesForFeatures:(NSArray *)features forVideoBox:(CGRect)clap orientation:(UIDeviceOrientation)orientation
{
    NSArray *sublayers = [NSArray arrayWithArray:[previewLayer sublayers]];
    NSInteger sublayersCount = [sublayers count], currentSublayer = 0;
    NSInteger featuresCount = [features count], currentFeature = 0;
    
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    
    // hide all the face layers
    for ( CALayer *layer in sublayers ) {
        if ( [[layer name] isEqualToString:@"FaceLayer"] )
            [layer setHidden:YES];
    }
    
    if ( featuresCount == 0 || !detectFaces ) {
        [CATransaction commit];
        return; // early bail.
    }
    
    CGSize parentFrameSize = [previewView frame].size;
    NSString *gravity = [previewLayer videoGravity];
    BOOL isMirrored = [previewLayer.connection isVideoMirrored];
    CGRect previewBox = [WGCameraViewController videoPreviewBoxForGravity:gravity
                                                                 frameSize:parentFrameSize
                                                              apertureSize:clap.size];
    
    for ( CIFaceFeature *ff in features ) {
        // find the correct position for the square layer within the previewLayer
        // the feature box originates in the bottom left of the video frame.
        // (Bottom right if mirroring is turned on)
        CGRect faceRect = [ff bounds];
        
        // flip preview width and height
        CGFloat temp = faceRect.size.width;
        faceRect.size.width = faceRect.size.height;
        faceRect.size.height = temp;
        temp = faceRect.origin.x;
        faceRect.origin.x = faceRect.origin.y;
        faceRect.origin.y = temp;
        // scale coordinates so they fit in the preview box, which may be scaled
        CGFloat widthScaleBy = previewBox.size.width / clap.size.height;
        CGFloat heightScaleBy = previewBox.size.height / clap.size.width;
        faceRect.size.width *= widthScaleBy;
        faceRect.size.height *= heightScaleBy;
        faceRect.origin.x *= widthScaleBy;
        faceRect.origin.y *= heightScaleBy;
        
        if ( isMirrored )
            faceRect = CGRectOffset(faceRect, previewBox.origin.x + previewBox.size.width - faceRect.size.width - (faceRect.origin.x * 2), previewBox.origin.y);
        else
            faceRect = CGRectOffset(faceRect, previewBox.origin.x, previewBox.origin.y);
        
        CALayer *featureLayer = nil;
        
        // re-use an existing layer if possible
        while ( !featureLayer && (currentSublayer < sublayersCount) ) {
            CALayer *currentLayer = [sublayers objectAtIndex:currentSublayer++];
            if ( [[currentLayer name] isEqualToString:@"FaceLayer"] ) {
                featureLayer = currentLayer;
                [currentLayer setHidden:NO];
            }
        }
        
        // create a new one if necessary
        if ( !featureLayer ) {
            featureLayer = [CALayer new];
            [featureLayer setContents:(id)[square CGImage]];
            [featureLayer setName:@"FaceLayer"];
            [previewLayer addSublayer:featureLayer];
            //[featureLayer release];
        }
        [featureLayer setFrame:faceRect];
        
        switch (orientation) {
            case UIDeviceOrientationPortrait:
                [featureLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(0.))];
                break;
            case UIDeviceOrientationPortraitUpsideDown:
                [featureLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(180.))];
                break;
            case UIDeviceOrientationLandscapeLeft:
                [featureLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(90.))];
                break;
            case UIDeviceOrientationLandscapeRight:
                [featureLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(-90.))];
                break;
            case UIDeviceOrientationFaceUp:
            case UIDeviceOrientationFaceDown:
            default:
                break; // leave the layer in its last known orientation
        }
        currentFeature++;
    }
    
    [CATransaction commit];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    // got an image
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
    CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer options:(__bridge NSDictionary *)attachments];
    if (attachments)
        CFRelease(attachments);
    NSDictionary *imageOptions = nil;
    UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
    int exifOrientation;
    
    /* kCGImagePropertyOrientation values
     The intended display orientation of the image. If present, this key is a CFNumber value with the same value as defined
     by the TIFF and EXIF specifications -- see enumeration of integer constants. 
     The value specified where the origin (0,0) of the image is located. If not present, a value of 1 is assumed.
     
     used when calling featuresInImage: options: The value for this key is an integer NSNumber from 1..8 as found in kCGImagePropertyOrientation.
     If present, the detection will be done based on that orientation but the coordinates in the returned features will still be based on those of the image. */
    
    enum {
        PHOTOS_EXIF_0ROW_TOP_0COL_LEFT			= 1, //   1  =  0th row is at the top, and 0th column is on the left (THE DEFAULT).
        PHOTOS_EXIF_0ROW_TOP_0COL_RIGHT			= 2, //   2  =  0th row is at the top, and 0th column is on the right.  
        PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT      = 3, //   3  =  0th row is at the bottom, and 0th column is on the right.  
        PHOTOS_EXIF_0ROW_BOTTOM_0COL_LEFT       = 4, //   4  =  0th row is at the bottom, and 0th column is on the left.  
        PHOTOS_EXIF_0ROW_LEFT_0COL_TOP          = 5, //   5  =  0th row is on the left, and 0th column is the top.  
        PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP         = 6, //   6  =  0th row is on the right, and 0th column is the top.  
        PHOTOS_EXIF_0ROW_RIGHT_0COL_BOTTOM      = 7, //   7  =  0th row is on the right, and 0th column is the bottom.  
        PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM       = 8  //   8  =  0th row is on the left, and 0th column is the bottom.  
    };
    
    switch (curDeviceOrientation) {
        case UIDeviceOrientationPortraitUpsideDown:  // Device oriented vertically, home button on the top
            exifOrientation = PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM;
            break;
        case UIDeviceOrientationLandscapeLeft:       // Device oriented horizontally, home button on the right
            if (isUsingFrontFacingCamera)
                exifOrientation = PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT;
            else
                exifOrientation = PHOTOS_EXIF_0ROW_TOP_0COL_LEFT;
            break;
        case UIDeviceOrientationLandscapeRight:      // Device oriented horizontally, home button on the left
            if (isUsingFrontFacingCamera)
                exifOrientation = PHOTOS_EXIF_0ROW_TOP_0COL_LEFT;
            else
                exifOrientation = PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT;
            break;
        case UIDeviceOrientationPortrait:            // Device oriented vertically, home button on the bottom
        default:
            exifOrientation = PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP;
            break;
    }
    
    imageOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:exifOrientation] forKey:CIDetectorImageOrientation];
    NSArray *features = [faceDetector featuresInImage:ciImage options:imageOptions];
    //[ciImage release];
    
    // get the clean aperture
    // the clean aperture is a rectangle that defines the portion of the encoded pixel dimensions
    // that represents image data valid for display.
    CMFormatDescriptionRef fdesc = CMSampleBufferGetFormatDescription(sampleBuffer);
    CGRect clap = CMVideoFormatDescriptionGetCleanAperture(fdesc, false /*originIsTopLeft == false*/);
    
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self drawFaceBoxesForFeatures:features forVideoBox:clap orientation:curDeviceOrientation];
    });
}

- (void)dealloc
{
    
    [self teardownAVCapture];
    // [faceDetector release];
    // [square release];
    // [super dealloc];
}

// use front/back camera
- (IBAction)switchCameras:(id)sender
{
    AVCaptureDevicePosition desiredPosition;
    if (isUsingFrontFacingCamera)
        desiredPosition = AVCaptureDevicePositionBack;
    else
        desiredPosition = AVCaptureDevicePositionFront;
    
    for (AVCaptureDevice *d in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if ([d position] == desiredPosition) {
            [[previewLayer session] beginConfiguration];
            AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:d error:nil];
            for (AVCaptureInput *oldInput in [[previewLayer session] inputs]) {
                [[previewLayer session] removeInput:oldInput];
            }
            [[previewLayer session] addInput:input];
            [[previewLayer session] commitConfiguration];
            break;
        }
    }
    isUsingFrontFacingCamera = !isUsingFrontFacingCamera;
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

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ( [gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] ) {
        beginGestureScale = effectiveScale;
    }
    return YES;
}

// scale image depending on users pinch gesture
- (IBAction)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer
{
    BOOL allTouchesAreOnThePreviewLayer = YES;
    NSUInteger numTouches = [recognizer numberOfTouches], i;
    for ( i = 0; i < numTouches; ++i ) {
        CGPoint location = [recognizer locationOfTouch:i inView:previewView];
        CGPoint convertedLocation = [previewLayer convertPoint:location fromLayer:previewLayer.superlayer];
        if ( ! [previewLayer containsPoint:convertedLocation] ) {
            allTouchesAreOnThePreviewLayer = NO;
            break;
        }
    }
    
    if ( allTouchesAreOnThePreviewLayer ) {
        effectiveScale = beginGestureScale * recognizer.scale;
        if (effectiveScale < 1.0)
            effectiveScale = 1.0;
        CGFloat maxScaleAndCropFactor = [[stillImageOutput connectionWithMediaType:AVMediaTypeVideo] videoMaxScaleAndCropFactor];
        if (effectiveScale > maxScaleAndCropFactor)
            effectiveScale = maxScaleAndCropFactor;
        [CATransaction begin];
        [CATransaction setAnimationDuration:.025];
        [previewLayer setAffineTransform:CGAffineTransformMakeScale(effectiveScale, effectiveScale)];
        [CATransaction commit];
    }
}


#pragma mark AVCaptureFileOutputRecordingDelegate methods

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
        
        [self convertVideoToLowQuailtyWithInputURL:outputFileURL
                                         outputURL:fileURL];
        
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



- (void)convertVideoToLowQuailtyWithInputURL:(NSURL*)inputURL
                                   outputURL:(NSURL*)outputURL
{
    //setup video writer
    AVAsset *videoAsset = [[AVURLAsset alloc] initWithURL:inputURL options:nil];
    
    AVAssetTrack *videoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    CGSize videoSize = videoTrack.naturalSize;
    videoSize = CGSizeMake(videoSize.width*0.75, videoSize.height*0.75);
    
    NSDictionary *videoWriterCompressionSettings =  [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kWGVideoAverageBitRate], AVVideoAverageBitRateKey, nil];
    
    
    NSDictionary *videoWriterSettings = @{AVVideoCodecKey:AVVideoCodecH264,
                                          AVVideoCompressionPropertiesKey:videoWriterCompressionSettings,
                                          AVVideoWidthKey:[NSNumber numberWithFloat:videoSize.width],
                                          AVVideoHeightKey:[NSNumber numberWithFloat:videoSize.height]};
    
    
    AVAssetWriterInput* videoWriterInput = [AVAssetWriterInput
                                            assetWriterInputWithMediaType:AVMediaTypeVideo
                                            outputSettings:videoWriterSettings];
    
    videoWriterInput.expectsMediaDataInRealTime = YES;
    
    videoWriterInput.transform = videoTrack.preferredTransform;
    
    self.videoWriter = [[AVAssetWriter alloc] initWithURL:outputURL fileType:AVFileTypeQuickTimeMovie error:nil];
    
    [self.videoWriter addInput:videoWriterInput];
    
    //setup video reader
    NSDictionary *videoReaderSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    
    AVAssetReaderTrackOutput *videoReaderOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:videoTrack outputSettings:videoReaderSettings];
    
    AVAssetReader *videoReader = [[AVAssetReader alloc] initWithAsset:videoAsset error:nil];
    
    [videoReader addOutput:videoReaderOutput];
    
    //setup audio writer
    AVAssetWriterInput* audioWriterInput = [AVAssetWriterInput
                                            assetWriterInputWithMediaType:AVMediaTypeAudio
                                            outputSettings:nil];
    
    audioWriterInput.expectsMediaDataInRealTime = NO;
    
    [self.videoWriter addInput:audioWriterInput];
    
    //setup audio reader
    AVAssetTrack* audioTrack = [[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    
    AVAssetReaderOutput *audioReaderOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTrack outputSettings:nil];
    
    AVAssetReader *audioReader = [AVAssetReader assetReaderWithAsset:videoAsset error:nil];
    
    [audioReader addOutput:audioReaderOutput];
    
    [self.videoWriter startWriting];
    
    //start writing from video reader
    [videoReader startReading];
    
    [self.videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    dispatch_queue_t processingQueue = dispatch_queue_create("processingQueue1", NULL);
    
    [videoWriterInput requestMediaDataWhenReadyOnQueue:processingQueue usingBlock:
     ^{
         
         while ([videoWriterInput isReadyForMoreMediaData]) {
             
             CMSampleBufferRef sampleBuffer;
             
             if ((sampleBuffer = [videoReaderOutput copyNextSampleBuffer])) {
                 
                 [videoWriterInput appendSampleBuffer:sampleBuffer];
                 CFRelease(sampleBuffer);
             }
             
             else {
                 
                 [videoWriterInput markAsFinished];
                 
                 if ([videoReader status] == AVAssetReaderStatusCompleted) {
                     
                     dispatch_async(dispatch_get_main_queue(),
                                    ^{
                                        
                                    
                     //start writing from audio reader
                     [audioReader startReading];
                     
                     [self.videoWriter startSessionAtSourceTime:kCMTimeZero];
                     
                     dispatch_queue_t processingQueue = dispatch_queue_create("processingQueue2", NULL);
                     
                     [audioWriterInput requestMediaDataWhenReadyOnQueue:processingQueue usingBlock:^{
                         
                         while (audioWriterInput.readyForMoreMediaData) {
                             
                             CMSampleBufferRef sampleBuffer;
                             
                             if ((sampleBuffer = [audioReaderOutput copyNextSampleBuffer])) {
                                 
                                 [audioWriterInput appendSampleBuffer:sampleBuffer];
                                 CFRelease(sampleBuffer);
                             }
                             
                             else {
                                 
                                 [audioWriterInput markAsFinished];
                                 
                                 if ([audioReader status] == AVAssetReaderStatusCompleted) {
                                     
                                     [self.videoWriter finishWritingWithCompletionHandler:^(){
                                         //[self sendMovieFileAtURL:outputURL];
                                         
                                         
                                         dispatch_async(dispatch_get_main_queue(),
                                                        ^{
                                                            NSLog(@"video writer status: %ld", (long)self.videoWriter.status);
                                                            
                                                            NSDictionary *dict = @{UIImagePickerControllerMediaType:(NSString *)kUTTypeMovie,
                                                                                   UIImagePickerControllerMediaURL:outputURL};
                                                            
                                                            
                                                            [self.delegate cameraController:self
                                                              didFinishPickingMediaWithInfo:dict];
                                                        });
                                         
                                     }];
                                     
                                 }
                             }
                         }
                         
                     }];
                                    });
                 }
             }
         }
     }
     ];
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
