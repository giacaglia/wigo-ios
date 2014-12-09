//
//  IQMediaCaptureController.m
//  https://github.com/hackiftekhar/IQMediaPickerController
//  Copyright (c) 2013-14 Iftekhar Qurashi.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


#import "IQMediaCaptureController.h"
#import "IQMediaView.h"
#import "IQFileManager.h"
#import "IQPartitionBar.h"
#import "IQBottomContainerView.h"
#import "IQMediaPickerControllerConstants.h"
#import "Globals.h"
#import "LLACircularProgressView.h"

#define kVideoTimeoutMax 8.0

@interface IQMediaCaptureController ()<IQCaptureSessionDelegate,IQPartitionBarDelegate,IQMediaViewDelegate>
{
    IQMediaCaptureControllerCaptureMode _expectedCaptureMode;
    IQMediaCaptureControllerCameraDevice _expectedCameraDevice;
    
    CADisplayLink *displayDuratioUpdate;
    
    NSMutableArray *videoURLs;
    NSMutableArray *audioURLs;
    NSMutableArray *arrayImagesAttribute;

    NSUInteger videoCounter;
    NSUInteger audioCounter;
    NSUInteger imageCounter;
    
    BOOL _previousNavigationBarHidden;
    BOOL _previousStatusBarHidden;
    BOOL longGesturePressed;
    
    BOOL isTouchedDown;
    double videoTimerCount;
    
    NSOperationQueue *operationQueue;
}

@property(nonatomic, strong, readonly) IQMediaView *mediaView;

@property(nonatomic, strong, readonly) UIView *settingsContainerView;
@property(nonatomic, strong, readonly) UIButton *buttonFlash, *buttonToggleCamera;

@property(nonatomic, strong, readonly) IQBottomContainerView *bottomContainerView;
@property(nonatomic, strong, readonly) IQPartitionBar *partitionBar;
@property(nonatomic, strong, readonly) UIImageView *imageViewProcessing;
@property(nonatomic, strong, readonly) UIButton *buttonCancel, *buttonCapture, *buttonToggleMedia, *buttonSelect, *buttonDelete;

//@property(nonatomic, strong, readonly) IQCaptureSession *session;

@property(nonatomic, assign) CGPoint labelPoint;
@property(nonatomic, strong) UITextField *textField;
@property(nonatomic, strong) UILabel *textLabel;
@property(nonatomic, assign) float startXPoint;
@end

@implementation IQMediaCaptureController
@synthesize session = _session;
@synthesize mediaView = _mediaView;

@synthesize settingsContainerView = _settingsContainerView;
@synthesize partitionBar = _partitionBar,imageViewProcessing = _imageViewProcessing, buttonCancel = _buttonCancel, buttonCapture = _buttonCapture, buttonToggleMedia = _buttonToggleMedia, buttonSelect = _buttonSelect, buttonDelete = _buttonDelete;

@synthesize bottomContainerView = _bottomContainerView;
@synthesize buttonFlash = _buttonFlash, buttonToggleCamera = _buttonToggleCamera;



#pragma mark - Lifetime
+(void)load
{
    [super load];

    [IQFileManager removeItemsAtPath:[[self class] temporaryAudioStoragePath]];
    [IQFileManager removeItemsAtPath:[[self class] temporaryVideoStoragePath]];
    [IQFileManager removeItemsAtPath:[[self class] temporaryImageStoragePath]];
}

-(void)dealloc
{
    [operationQueue cancelAllOperations];
    [operationQueue cancelAllOperations];
    
    operationQueue = nil;
    operationQueue = nil;
    
    [[self session] stopRunning];
    _session = nil;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _expectedCaptureMode = IQMediaCaptureControllerCaptureModePhoto;
        _expectedCameraDevice = IQMediaCaptureControllerCameraDeviceRear;
        
        videoURLs = [[NSMutableArray alloc] init];
        audioURLs = [[NSMutableArray alloc] init];
        arrayImagesAttribute = [[NSMutableArray alloc] init];
        
        videoCounter = 0;
        audioCounter = 0;
        imageCounter = 0;
        
        operationQueue = [[NSOperationQueue alloc] init];
        [operationQueue setMaxConcurrentOperationCount:1];
    }
    return self;
}

-(void)loadView
{
    self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.view.backgroundColor = [UIColor blackColor];
    
    [self.view addSubview:self.mediaView];
    [self.view addSubview:self.settingsContainerView];
    [self.view addSubview:self.bottomContainerView];
    
//    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
//    gradientLayer.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
//    gradientLayer.colors = @[(id)RGBAlpha(0, 0, 0, 0.7f).CGColor,
//                             (id)RGBAlpha(0, 0, 0, 0.2f).CGColor,
//                             (id)RGBAlpha(0, 0, 0, 0.0f).CGColor,
//                             (id)RGBAlpha(0, 0, 0, 0.0f).CGColor,
//                             (id)RGBAlpha(0, 0, 0, 0.7f).CGColor
//                             ];
//    gradientLayer.locations = @[[NSNumber numberWithFloat:0.0f],
//                                [NSNumber numberWithFloat:0.2f],
//                                [NSNumber numberWithFloat:0.3f],
//                                [NSNumber numberWithFloat:0.85f],
//                                [NSNumber numberWithFloat:1],
//                                ];
//    [self.view.layer addSublayer:gradientLayer];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.buttonToggleMedia.hidden = YES;    //Toggling media type in running mode is officially not supported. Explicitly hides toggle button.
    
    [IQFileManager removeItemsAtPath:[[self class] temporaryAudioStoragePath]];
    [IQFileManager removeItemsAtPath:[[self class] temporaryVideoStoragePath]];
    [IQFileManager removeItemsAtPath:[[self class] temporaryImageStoragePath]];


    [self updateUI];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _session.delegate = self;
    
    [[self session] startRunning];
    [self setCaptureMode:_expectedCaptureMode animated:NO];
    [self setCaptureDevice:_expectedCameraDevice animated:NO];
    self.mediaView.previewSession = [self session].captureSession;

    _previousNavigationBarHidden = self.navigationController.navigationBarHidden;
    _previousStatusBarHidden = [[UIApplication sharedApplication] isStatusBarHidden];
    
    self.navigationController.navigationBarHidden = YES;
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    _session.delegate = nil;
    
    [[self session] stopRunning];
    
    [displayDuratioUpdate removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [displayDuratioUpdate invalidate];
    displayDuratioUpdate = nil;
    
    self.navigationController.navigationBarHidden = _previousNavigationBarHidden;
    [[UIApplication sharedApplication] setStatusBarHidden:_previousStatusBarHidden withAnimation:UIStatusBarAnimationSlide];
}

#pragma mark - UI handling

-(void)updateUI
{
    [UIView animateWithDuration:0.3 delay:0 options:(UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseOut) animations:^{
        
        self.buttonToggleCamera.enabled = ([[IQCaptureSession supportedVideoCaptureDevices] count]>1)?YES:NO;
        
        //Flash
        if ([self session].fakeFlashMode == AVCaptureFlashModeOn) {
            for (UIView *subview in self.buttonFlash.subviews) {
                if ([subview isKindOfClass:[UIImageView class]]) [subview removeFromSuperview];
            }
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 16, 26)];
            imageView.image = [UIImage imageNamed:@"flashOn"];
            [self.buttonFlash addSubview:imageView];
            self.buttonFlash.alpha = 1.0f;
        }
        else if ([self session].fakeFlashMode == AVCaptureFlashModeOff) {
            for (UIView *subview in self.buttonFlash.subviews) {
                if ([subview isKindOfClass:[UIImageView class]]) [subview removeFromSuperview];
            }
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 26, 31)];
            imageView.image = [UIImage imageNamed:@"flashOff"];
            [self.buttonFlash addSubview:imageView];
            self.buttonFlash.alpha = 0.3f;
        }
        self.buttonFlash.enabled = YES;
        
        
        //Focus
        {
            [self.mediaView setFocusMode:[self session].focusMode];
            [self.mediaView setFocusPointOfInterest:[self session].focusPoint];
            
        }

        //Exposure
        {
            [self.mediaView setExposureMode:[self session].exposureMode];
            [self.mediaView setExposurePointOfInterest:[self session].exposurePoint];
            
        }
        
        {
            [self.buttonCapture setImage:[UIImage imageNamed:@"captureCamera"] forState:UIControlStateNormal];

        }
        
    } completion:^(BOOL finished) {
    }];
}

-(void)updateDuration
{
     if ([[self session] isRecording])
    {
        NSMutableArray *durations;
        
        if (self.captureMode == IQMediaCaptureControllerCaptureModeAudio)
        {
            durations = [[IQFileManager durationsOfFilesAtPath:[[self class] temporaryAudioStoragePath]] mutableCopy];
        }
        else if (self.captureMode == IQMediaCaptureControllerCaptureModeVideo)
        {
            durations = [[IQFileManager durationsOfFilesAtPath:[[self class] temporaryVideoStoragePath]] mutableCopy];
        }
        
        double duration = [[self session] recordingDuration];
        bool isInfinite = isinf(duration);
        if (isInfinite == false)
        {
            [durations addObject:[NSNumber numberWithDouble:duration]];
        }
        
        [self.partitionBar setPartitions:durations animated:NO];
        
    }
    else
    {
        [self.buttonCapture setTransform:CGAffineTransformIdentity];;

        [displayDuratioUpdate removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [displayDuratioUpdate invalidate];
        displayDuratioUpdate = nil;
    }
}

#pragma mark - Camera Session Settings

-(void)setCaptureDevice:(IQMediaCaptureControllerCameraDevice)captureDevice
{
    [self setCaptureDevice:captureDevice animated:NO];
}

-(void)setCaptureMode:(IQMediaCaptureControllerCaptureMode)captureMode animated:(BOOL)animated
{
    if (_mediaView == nil)
    {
        _expectedCaptureMode = captureMode;
    }
    else
    {
        [self.mediaView setBlur:NO];
        
        [operationQueue addOperationWithBlock:^{
            
            BOOL success = NO;
            
            if (captureMode == IQMediaCaptureControllerCaptureModePhoto)
            {
                success = [[self session] setCaptureMode:IQCameraCaptureModePhoto];
            }
            else if (captureMode == IQMediaCaptureControllerCaptureModeVideo)
            {
                success = [[self session] setCaptureMode:IQCameraCaptureModeVideo];
            }
            else if (captureMode == IQMediaCaptureControllerCaptureModeAudio)
            {
                success = [[self session] setCaptureMode:IQCameraCaptureModeAudio];
            }
            
            if (success)
            {
                _captureMode = captureMode;
            }
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                
                [UIView transitionWithView:self.buttonToggleMedia duration:((animated && success)?0.5:0) options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionTransitionFlipFromLeft|UIViewAnimationOptionCurveEaseOut animations:^{
                    
                    [self.mediaView setCaptureMode:_captureMode];

                    
                    if ([self session].captureMode == IQCameraCaptureModePhoto)
                    {
                        self.settingsContainerView.hidden = NO;
                        
                        [self.bottomContainerView setTopContentView:nil];
                        [self.buttonToggleMedia setImage:[UIImage imageNamed:@"IQ_camera"] forState:UIControlStateNormal];
                    }
                    else if ([self session].captureMode == IQCameraCaptureModeVideo)
                    {
                        self.settingsContainerView.hidden = NO;
//                        [self.mediaView setOverlayColor:nil];
                        
                        NSArray *durations = [IQFileManager durationsOfFilesAtPath:[[self class] temporaryVideoStoragePath]];
                        [self.partitionBar setPartitions:durations animated:YES];
                        
                        [self.bottomContainerView setTopContentView:self.partitionBar];
                        [self.buttonToggleMedia setImage:[UIImage imageNamed:@"IQ_video"] forState:UIControlStateNormal];
                    }
                    else if ([self session].captureMode == IQCameraCaptureModeAudio)
                    {
                        self.settingsContainerView.hidden = YES;
//                        [self.mediaView setOverlayColor:[UIColor orangeColor]];
                        
                        NSArray *durations = [IQFileManager durationsOfFilesAtPath:[[self class] temporaryAudioStoragePath]];
                        [self.partitionBar setPartitions:durations animated:YES];
                        
                        [self.bottomContainerView setTopContentView:self.partitionBar];
                        [self.buttonToggleMedia setImage:[UIImage imageNamed:@"IQ_audio"] forState:UIControlStateNormal];
                    }
                    
                } completion:^(BOOL finished) {
                    [self updateUI];
                    [self.mediaView setBlur:NO];
                }];
            }];
        }];
    }
}

-(void)setCaptureMode:(IQMediaCaptureControllerCaptureMode)captureMode
{
    [self setCaptureMode:captureMode animated:NO];
}

-(void)setCaptureDevice:(IQMediaCaptureControllerCameraDevice)captureDevice animated:(BOOL)animated
{
    if (_mediaView == nil)
    {
        _expectedCameraDevice = captureDevice;
    }
    else
    {
        [self.mediaView setBlur:NO];
        
        [operationQueue addOperationWithBlock:^{
            
            BOOL success = NO;
            
            if (captureDevice == IQMediaCaptureControllerCameraDeviceRear)
            {
                success = [[self session] setCameraPosition:AVCaptureDevicePositionBack];
            }
            else if (captureDevice == IQMediaCaptureControllerCameraDeviceFront)
            {
                success = [[self session] setCameraPosition:AVCaptureDevicePositionFront];
            }
            
            if (success)
            {
                _captureDevice = captureDevice;
            }
            
            if (success)
            {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    
                    [UIView transitionWithView:self.mediaView duration:((animated && success)?0.5:0) options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionTransitionFlipFromLeft|UIViewAnimationOptionCurveEaseOut animations:^{
                        
                        [self updateUI];
                        
                    } completion:^(BOOL finished) {
                        
                        [self.mediaView setBlur:NO];
                    }];
                }];
            }
        }];
    }
}

- (void)toggleCameraAction
{
    if ([self session].cameraPosition == AVCaptureDevicePositionBack)
    {
        [[self session] setFlashMode:AVCaptureFlashModeOff];
        [self setCaptureDevice:IQMediaCaptureControllerCameraDeviceFront animated:YES];
    }
    else
    {
        [self setCaptureDevice:IQMediaCaptureControllerCameraDeviceRear animated:YES];
    }
    self.buttonToggleCamera.clipsToBounds = YES;
    [UIView animateWithDuration:.15f animations:^{
        self.buttonToggleCamera.imageView.transform = CGAffineTransformMakeScale(1.5,1.5);
    }completion:^(BOOL finished) {
        [UIView animateWithDuration:.15f animations:^{
            self.buttonToggleCamera.imageView.transform = CGAffineTransformMakeScale(1.0,1.0);
        }];
    }];
}

- (void)toggleCaptureMode:(UIButton *)sender
{
    if ([self session].captureMode == IQCameraCaptureModePhoto)
    {
        [self setCaptureMode:IQMediaCaptureControllerCaptureModeVideo animated:YES];
    }
    else if ([self session].captureMode == IQCameraCaptureModeVideo)
    {
        [self setCaptureMode:IQMediaCaptureControllerCaptureModeAudio animated:YES];
    }
    else if ([self session].captureMode == IQCameraCaptureModeAudio)
    {
        [self setCaptureMode:IQMediaCaptureControllerCaptureModePhoto animated:YES];
    }
}

- (void)toggleFlash:(UIButton *)sender
{
    if ([self session].fakeFlashMode == AVCaptureFlashModeOff)
    {
        [[self session] setFakeFlashMode:AVCaptureFlashModeOn];
        if ([[self session] isFlashModeSupported:AVCaptureFlashModeOn])
            [[self session] setFlashMode:AVCaptureFlashModeOn];
        
    }
    else if ([self session].fakeFlashMode == AVCaptureFlashModeOn)
    {
        [[self session] setFakeFlashMode:AVCaptureFlashModeOff];
        if ([[self session] isFlashModeSupported:AVCaptureFlashModeOff])
            [[self session] setFlashMode:AVCaptureFlashModeOff];
    }
       
    [self updateUI];
}

- (void)toggleTorch:(UIButton *)sender
{
    if ([self session].torchMode == AVCaptureTorchModeOff)
    {
        if ([[self session] isTorchModeSupported:AVCaptureTorchModeOn])
            [[self session] setTorchMode:AVCaptureTorchModeOn];
    }
    else if ([self session].torchMode == AVCaptureTorchModeOn)
    {
        if ([[self session] isTorchModeSupported:AVCaptureTorchModeOff])
            [[self session] setTorchMode:AVCaptureTorchModeOff];
    }
    
    [self updateUI];
}

- (void)toggleExposure:(UIButton *)sender
{
    if ([self session].exposureMode == AVCaptureExposureModeLocked)
    {
        if ([[self session] isExposureModeSupported:AVCaptureExposureModeAutoExpose])
            [[self session] setExposureMode:AVCaptureExposureModeAutoExpose];
        else if ([[self session] isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure])
            [[self session] setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
    }
    else if ([self session].exposureMode == AVCaptureExposureModeAutoExpose)
    {
        if ([[self session] isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure])
            [[self session] setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
        else if ([[self session] isExposureModeSupported:AVCaptureExposureModeLocked])
            [[self session] setExposureMode:AVCaptureExposureModeLocked];
    }
    else if ([self session].exposureMode == AVCaptureExposureModeContinuousAutoExposure)
    {
        if ([[self session] isExposureModeSupported:AVCaptureExposureModeLocked])
            [[self session] setExposureMode:AVCaptureExposureModeLocked];
        else if ([[self session] isExposureModeSupported:AVCaptureExposureModeAutoExpose])
            [[self session] setExposureMode:AVCaptureExposureModeAutoExpose];
    }
    
    [self updateUI];
}

- (void)whiteBalance:(UIButton *)sender
{
    if ([self session].whiteBalanceMode == AVCaptureWhiteBalanceModeLocked)
    {
        if ([[self session] isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance])
            [[self session] setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance];
        else if ([[self session] isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance])
            [[self session] setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
    }
    else if ([self session].whiteBalanceMode == AVCaptureWhiteBalanceModeAutoWhiteBalance)
    {
        if ([[self session] isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance])
            [[self session] setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
        else if ([[self session] isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeLocked])
            [[self session] setWhiteBalanceMode:AVCaptureWhiteBalanceModeLocked];
    }
    else if ([self session].whiteBalanceMode == AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance)
    {
        if ([[self session] isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeLocked])
            [[self session] setWhiteBalanceMode:AVCaptureWhiteBalanceModeLocked];
        else if ([[self session] isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance])
            [[self session] setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance];
    }
    
    [self updateUI];
}

- (void)captureAction:(UIButton *)sender
{

    if ([[self session] isSessionRunning] == NO)
    {
        [self.buttonCapture setImage:[UIImage imageNamed:@"IQ_start_capture_mode"] forState:UIControlStateNormal];

        [[self session] startRunning];
        [self.bottomContainerView setRightContentView:self.buttonToggleMedia];
        
        //Resetting
        if (self.allowsCapturingMultipleItems == NO)
        {
            videoCounter = 0;
            audioCounter = 0;
            imageCounter = 0;
            
            [videoURLs removeAllObjects];
            [audioURLs removeAllObjects];
            [arrayImagesAttribute removeAllObjects];
            
            [IQFileManager removeItemsAtPath:[[self class] temporaryAudioStoragePath]];
            [IQFileManager removeItemsAtPath:[[self class] temporaryVideoStoragePath]];
            [IQFileManager removeItemsAtPath:[[self class] temporaryImageStoragePath]];
            
            [self.partitionBar setPartitions:[NSArray new] animated:YES];
        }
    }
    else
    {
        if ([self session].captureMode == IQCameraCaptureModePhoto)
        {
            [self setFrontFlash];
            [UIView animateWithDuration:0.2 delay:0 options:(UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseOut) animations:^{
                [self.buttonCapture setImage:[UIImage new] forState:UIControlStateNormal];
                for (UIView *subview in self.buttonCancel.subviews) {
                    if ([subview isKindOfClass:[UIImageView class]]) {
                        [subview removeFromSuperview];
                    }
                }
                self.buttonCancel.titleLabel.font = [FontProperties mediumFont:20.0f];
                [self.buttonCancel setTitle:@"< Cancel" forState:UIControlStateNormal];
                self.buttonCancel.titleLabel.layer.shadowColor = [[UIColor blackColor] CGColor];
                self.buttonCancel.titleLabel.layer.shadowOffset = CGSizeMake(0.0f, 0.5f);
                self.buttonCancel.titleLabel.layer.shadowOpacity = 0.5;
                self.buttonCancel.titleLabel.layer.shadowRadius = 0.5;
                self.settingsContainerView.alpha = 0.0;
            } completion:NULL];

            [self.bottomContainerView setLeftContentView:nil];
            [self.bottomContainerView setRightContentView:nil];
            self.buttonToggleCamera.hidden = YES;
            self.buttonFlash.hidden = YES;

        }
        else if ([self session].captureMode == IQCameraCaptureModeVideo)
        {
            if ([self session].isRecording == NO)
            {
                [[self session] startVideoRecording];
                
                [UIView animateWithDuration:0.2 delay:0 options:(UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseOut) animations:^{
                    [self.buttonCapture setImage:[UIImage imageNamed:@"IQ_stop_capture_mode"] forState:UIControlStateNormal];
                    [self.partitionBar setSelectedIndex:-1];
                    self.settingsContainerView.alpha = 0.0;
                } completion:NULL];
                
                [self.partitionBar setUserInteractionEnabled:NO];
                [self.bottomContainerView setLeftContentView:nil];
                [self.bottomContainerView setRightContentView:nil];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

                    displayDuratioUpdate = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateDuration)];
                    [displayDuratioUpdate addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
                });
            }
            else
            {
                [[self session] stopVideoRecording];
                [UIView animateWithDuration:0.2 delay:0 options:(UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseOut) animations:^{
                    [self.buttonCapture setImage:[UIImage imageNamed:@"IQ_neutral_mode"] forState:UIControlStateNormal];
                    [self.buttonCapture setTransform:CGAffineTransformIdentity];;
                } completion:NULL];
                
                [self.bottomContainerView setLeftContentView:nil];
                [self.bottomContainerView setRightContentView:nil];
                [self.bottomContainerView setMiddleContentView:nil];
                
                [displayDuratioUpdate removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
                [displayDuratioUpdate invalidate];
                displayDuratioUpdate = nil;
                
                [self.partitionBar setUserInteractionEnabled:YES];
            }
        }
        else if ([self session].captureMode == IQCameraCaptureModeAudio)
        {
            if ([self session].isRecording == NO)
            {
                [[self session] startAudioRecording];
                
                [UIView animateWithDuration:0.2 delay:0 options:(UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseOut) animations:^{
                    [self.buttonCapture setImage:[UIImage imageNamed:@"IQ_stop_capture_mode"] forState:UIControlStateNormal];
                    [self.partitionBar setSelectedIndex:-1];
                    self.settingsContainerView.alpha = 0.0;
                } completion:NULL];
                
                [self.partitionBar setUserInteractionEnabled:NO];
                [self.bottomContainerView setLeftContentView:nil];
                [self.bottomContainerView setRightContentView:nil];

                displayDuratioUpdate = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateDuration)];
                [displayDuratioUpdate addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            }
            else
            {
                [[self session] stopAudioRecording];
                [UIView animateWithDuration:0.2 delay:0 options:(UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseOut) animations:^{
                    [self.buttonCapture setImage:[UIImage imageNamed:@"IQ_neutral_mode"] forState:UIControlStateNormal];
                    [self.buttonCapture setTransform:CGAffineTransformIdentity];;
                } completion:NULL];
                
                [self.bottomContainerView setLeftContentView:nil];
                [self.bottomContainerView setRightContentView:nil];
                [self.bottomContainerView setMiddleContentView:nil];
//                [self.bottomContainerView setMiddleContentView:self.imageViewProcessing];
                
                [displayDuratioUpdate removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
                [displayDuratioUpdate invalidate];
                displayDuratioUpdate = nil;

                [self.partitionBar setUserInteractionEnabled:YES];
            }
        }
    }
}

- (void)setFrontFlash {
    if ([self session].cameraPosition == AVCaptureDevicePositionFront &&
        [self session].fakeFlashMode == AVCaptureFlashModeOn) {
        CGFloat oldBrightness = [UIScreen mainScreen].brightness;
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, window.frame.size.width, window.frame.size.height)];
        [UIView animateWithDuration:0.1f
                              delay:0.0
                            options:UIViewAnimationOptionCurveLinear
                         animations:^
         {
             [window addSubview:view];
             [[UIScreen mainScreen]setBrightness:1.0];
             view.backgroundColor = [UIColor whiteColor];
             view.alpha = 1.0f;
         }
                         completion:^(BOOL finished)
         {
             if (finished)
             {
                 [[self session] takePicture];
                 [UIView beginAnimations:nil context:nil];
                 [UIView setAnimationBeginsFromCurrentState:YES];
                 [UIView setAnimationCurve:UIViewAnimationCurveLinear];
                 [UIView setAnimationDuration:1.0f];
                 view.alpha = 0.0;
                 [view removeFromSuperview];
                 [[UIScreen mainScreen]setBrightness:oldBrightness];
                 [UIView commitAnimations];
             }
         }];
    }
    else {
        [[self session] takePicture];
    }
}

- (void)longPress:(UILongPressGestureRecognizer*)gesture {
//    if (!longGesturePressed && gesture.state == UIGestureRecognizerStateBegan) {
//        
////        NSLog(@"touch down");
//        [[self session] setCaptureMode:IQCameraCaptureModeVideo];
//        [[self session] startVideoRecording];
//        
//        LLACircularProgressView *circularProgressView = [[LLACircularProgressView alloc] initWithFrame: self.buttonCapture.frame];
//        // Optionally set the current progress
//        circularProgressView.progress = 0.0f;
//        circularProgressView.tintColor = [FontProperties getBlueColor];
//        circularProgressView.innerObjectTintColor = [FontProperties getOrangeColor];
//        circularProgressView.backgroundColor = [UIColor clearColor];
//        
//        [self.buttonCapture addSubview:circularProgressView];
//        
//        videoTimerCount = kVideoTimeoutMax;
//        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [[NSTimer scheduledTimerWithTimeInterval: 0.01 target: self selector:@selector(videoCaptureTimerFired:) userInfo: @{@"gesture": gesture, @"progress": circularProgressView} repeats: YES] fire];
//        });
//        
//        longGesturePressed = YES;
//        
//    }
//    if ( (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) && longGesturePressed) {
//
//        [[self session] stopVideoRecording];
//        longGesturePressed = NO;
//        
//    }
}

- (void) videoCaptureTimerFired:(NSTimer *) timer {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        videoTimerCount -= timer.timeInterval;
        
        LLACircularProgressView *circularProgressView = timer.userInfo[@"progress"];
        UILongPressGestureRecognizer *gesture = timer.userInfo[@"gesture"];
        [circularProgressView setProgress: MIN(1.0, (kVideoTimeoutMax - videoTimerCount)/kVideoTimeoutMax) animated:YES];
        
        
        if (videoTimerCount <= 0) {
            
            [timer invalidate];
            
            //hack to cancel the gesture.
            gesture.enabled = NO;
            gesture.enabled = YES;
            
            [self longPress: gesture];
            
        }
    });
}



#pragma mark - Other Actions

- (void)cancelAction:(UIButton *)sender
{
    if ([[self session] isSessionRunning] == NO) {
        [self.mediaView stopReplayVideo];
        [[self session] setCaptureMode:IQCameraCaptureModePhoto];
        [[self session] startRunning];
        [self.bottomContainerView setRightContentView:self.buttonToggleMedia];
        
        //Resetting
        if (self.allowsCapturingMultipleItems == NO)
        {
            videoCounter = 0;
            audioCounter = 0;
            imageCounter = 0;
            
            [videoURLs removeAllObjects];
            [audioURLs removeAllObjects];
            [arrayImagesAttribute removeAllObjects];
            
            [IQFileManager removeItemsAtPath:[[self class] temporaryAudioStoragePath]];
            [IQFileManager removeItemsAtPath:[[self class] temporaryVideoStoragePath]];
            [IQFileManager removeItemsAtPath:[[self class] temporaryImageStoragePath]];
            
            [self.partitionBar setPartitions:[NSArray new] animated:YES];
        }
     
        for (UIView *subview in self.buttonCancel.subviews) {
            if ([subview isKindOfClass:[UIImageView class]]) {
                [subview removeFromSuperview];
            }
        }
        [self.buttonCancel setTitle:nil forState:UIControlStateNormal];
        UIImageView *cancelCamera = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 36, 36)];
        cancelCamera.image = [UIImage imageNamed:@"cancelCamera"];
        [self.buttonCancel addSubview:cancelCamera];
        
        for (UIView *subview in self.buttonCapture.subviews) {
            if ([subview isKindOfClass:[LLACircularProgressView class]]) {
                [subview removeFromSuperview];
            }
        }
        [self.buttonCapture setImage:[UIImage imageNamed:@"captureCamera"] forState:UIControlStateNormal];
        [self.bottomContainerView setMiddleContentView:self.buttonCapture];
        self.buttonToggleCamera.hidden = NO;
        self.buttonFlash.hidden = NO;
        self.textField.text = @"";
        self.textField.hidden = YES;
        self.textLabel.text = @"";
        self.textLabel.hidden = YES;
    }
    
    else {
        if ([self.delegate respondsToSelector:@selector(mediaCaptureControllerDidCancel:)])
        {
            [self.delegate mediaCaptureControllerDidCancel:self];
        }
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)selectAction:(UIButton *)sender
{
    if ([self.delegate respondsToSelector:@selector(mediaCaptureController:didFinishMediaWithInfo:)])
    {
        NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
        
        if ([arrayImagesAttribute count])
        {
            [info setObject:arrayImagesAttribute forKey:IQMediaTypeImage];
        }
        
        if ([videoURLs count])
        {
            [self.mediaView stopReplayVideo];

            NSMutableArray *videoMedias = [[NSMutableArray alloc] init];
            
            for (NSURL *videoURL in videoURLs)
            {
                NSDictionary *dict = [NSDictionary dictionaryWithObject:videoURL forKey:IQMediaURL];
                [videoMedias addObject:dict];
            }
            
            [info setObject:videoMedias forKey:IQMediaTypeVideo];
        }
        
        if ([audioURLs count])
        {
            NSMutableArray *audioMedias = [[NSMutableArray alloc] init];
            
            for (NSURL *audioURL in audioURLs)
            {
                NSDictionary *dict = [NSDictionary dictionaryWithObject:audioURL forKey:IQMediaURL];
                [audioMedias addObject:dict];
            }
            
            [info setObject:audioMedias forKey:IQMediaTypeAudio];
        }
        if (self.textField && self.textField.text.length > 0) {
            NSMutableArray *textMedias = [[NSMutableArray alloc] init];

            NSDictionary *dict = @{
                                   IQMediaText: self.textField.text,
                                   IQMediaYPosition:@(self.labelPoint.y)
                                   };
            [textMedias addObject:dict];

            [info setObject:textMedias forKey:IQMediaTypeText];
        }
        [self.delegate mediaCaptureController:self didFinishMediaWithInfo:info];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)deleteAction:(UIButton *)sender
{
    NSURL *mediaURL = [videoURLs objectAtIndex:self.partitionBar.selectedIndex];
    
    [videoURLs removeObject:mediaURL];
    [IQFileManager removeItemAtPath:mediaURL.relativePath];
    
    [self.partitionBar removeSelectedPartition];
    
    if (self.partitionBar.partitions.count > 0)
    {
        [self.bottomContainerView setLeftContentView:self.buttonDelete];
    }
    else
    {
        [self.bottomContainerView setLeftContentView:self.buttonCancel];
    }
}

#pragma mark - IQMediaView Delegates

- (void)doneWithEditingMediaView:(IQMediaView *)mediaView {
    if (!self.session.isSessionRunning) {
        [self.textField endEditing:YES];
        [UIView animateWithDuration:0.3 animations:^{
            self.textField.hidden = YES;
            self.textLabel.hidden = NO;
            self.textLabel.text = self.textField.text;
            self.textLabel.frame =  CGRectMake(0, self.labelPoint.y, self.view.frame.size.width, 40);
        }];
        if (self.textField.text.length == 0) {
            self.textField.hidden = YES;
            self.textLabel.hidden = YES;
        }
    }
}


-(void)mediaView:(IQMediaView*)mediaView focusPointOfInterest:(CGPoint)focusPoint
{
    if ([self session].isSessionRunning) {
        [[self session] setFocusPoint:focusPoint];
    }
}

-(void)mediaView:(IQMediaView*)mediaView exposurePointOfInterest:(CGPoint)exposurePoint
{
    if ([self session].isSessionRunning) {
        [[self session] setExposurePoint:exposurePoint];
    }
}

- (void)mediaView:(IQMediaView *)mediaView editLabelAtPoint:(CGPoint)labelPoint {
    if (![self session].isSessionRunning) {
        if (!self.textField) {
            self.textField = [[UITextField alloc] init];
            self.textField.backgroundColor = RGBAlpha(0, 0, 0, 0.7f);
            self.textField.textColor = [UIColor whiteColor];
            self.textField.textAlignment = NSTextAlignmentCenter;
            self.textField.font = [FontProperties mediumFont:17.0f];
            self.textField.delegate = self;
            self.textField.returnKeyType = UIReturnKeyDone;
            [self.view addSubview:self.textField];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardDidShowNotification object:nil];
            
            self.textLabel = [[UILabel alloc] init];
            self.textLabel.hidden = YES;
            self.textLabel.backgroundColor = RGBAlpha(0, 0, 0, 0.7f);
            self.textLabel.textColor = [UIColor whiteColor];
            self.textLabel.textAlignment = NSTextAlignmentCenter;
            self.textLabel.font = [FontProperties mediumFont:17.0f];
            [self.view addSubview:self.textLabel];
        }
        self.textLabel.hidden = YES;
        self.textField.hidden = NO;
        self.labelPoint = labelPoint;
        [self.textField becomeFirstResponder];
    }
}


- (void)mediaView:(IQMediaView *)mediaView labelPointOfInterest:(CGPoint)labelPoint {
    if (![self.textField isFirstResponder]) {
        labelPoint.y = MIN(MAX(labelPoint.y, 110), 460);
        self.textField.hidden = YES;
        self.textLabel.hidden = NO;
        self.textLabel.text = self.textField.text;
        self.textLabel.frame =  CGRectMake(0, labelPoint.y, self.view.frame.size.width, 40);
//        self.textField.frame = CGRectMake(0, labelPoint.y, self.view.frame.size.width, 40);
        self.labelPoint = labelPoint;
    }
}

-(void)mediaView:(IQMediaView*)mediaView translate:(CGPoint)translationPoint
{
    if ([[self session] isSessionRunning]){
        UIView *topSuperView = (UIView *)(UIView *)(UIView *)(UIView *)(UIView *)self.view.superview.superview.superview.superview.superview.superview;
        if ([topSuperView isKindOfClass:[UIScrollView class]]) {
            UIScrollView *scrollView = (UIScrollView *)topSuperView;
            if (!self.startXPoint) {
                self.startXPoint = scrollView.contentOffset.x;
            }
            if (translationPoint.x > 0) {
                scrollView.contentOffset = CGPointMake(self.startXPoint - translationPoint.x, scrollView.contentOffset.y);
            }
        }

    }
}

- (void)mediaView:(IQMediaView *)mediaView stopTranslateAt:(CGPoint)translatePoint {
    if ([self session].isSessionRunning) {
        UIView *topSuperView = (UIView *)(UIView *)(UIView *)(UIView *)(UIView *)self.view.superview.superview.superview.superview.superview.superview;
        if ([topSuperView isKindOfClass:[UIScrollView class]]) {
            
            UIScrollView *scrollView = (UIScrollView *)topSuperView;
            if (!self.startXPoint) {
                self.startXPoint = scrollView.contentOffset.x;
            }
            if (translatePoint.x > 0) {
                float fractionalPage = (self.startXPoint - translatePoint.x)/320;
                int page;
                if (fractionalPage - floor(fractionalPage) < 0.8) {
                    page = floor(fractionalPage);
                }
                else {
                    page = ceil(fractionalPage);
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:@"notificationHighlightPage"
                                                                    object:nil
                                                                  userInfo:@{@"page": [NSNumber numberWithInt:page]}];
            }
        }

    }
   
}

- (void)keyboardWillShow:(NSNotification*)notification
{
    NSDictionary* userInfo = [notification userInfo];
    CGRect kbFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.textField.frame = CGRectMake(0, kbFrame.origin.y - 40, self.view.frame.size.width, 40);
    }];
}

//- (void)keyboardWillChange:(NSNotification *)note {
////    NSLog(@"keybaorddidchange: user info: %@", userInfo);
//    NSValue *keyboardEndFrameValue = [[note userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey];
//    CGRect keyboardEndFrame = [keyboardEndFrameValue CGRectValue];
////    CGRect properlyRotatedCoords = [self.view.window convertRect:kbFrame toView:self.view.window.rootViewController.view];
//    
//    NSLog(@"keyboard frame change: %f, %f", keyboardEndFrame.size.height, keyboardEndFrame.origin.y);
////    NSLog(@"properly frame change: %f, %f", properlyRotatedCoords.size.height, properlyRotatedCoords.origin.y);
//}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.textField endEditing:YES];
    [UIView animateWithDuration:0.3 animations:^{
        self.textField.hidden = YES;
        self.textLabel.hidden = NO;
        self.textLabel.text = self.textField.text;
        self.textLabel.frame =  CGRectMake(0, self.labelPoint.y, self.view.frame.size.width, 40);
    }];
    if (self.textField.text.length  == 0) {
        self.textField.hidden = YES;
        self.textLabel.hidden = YES;
    }
    return YES;
}
- (BOOL)textField:(UITextField *)textField
shouldChangeCharactersInRange:(NSRange)range
replacementString:(NSString *)string {
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    CGSize size = [newString sizeWithAttributes:
                   @{NSFontAttributeName:textField.font}];
    if (size.width < self.view.frame.size.width - 10) return YES;
    return NO;
}

- (void)reverseCamera {
    if ([self session].isSessionRunning) {
       [self toggleCameraAction];
    }
}

#pragma mark - IQCaptureSession Delegates

- (void)captureSession:(IQCaptureSession*)audioSession didUpdateMeterLevel:(CGFloat)meterLevel
{
    self.mediaView.meteringLevel = meterLevel;
}

-(void)captureSession:(IQCaptureSession*)captureSession didFinishMediaWithInfo:(NSDictionary *)info error:(NSError*)error
{
    [[self session] stopRunning];
    
    //Resetting
    if (self.allowsCapturingMultipleItems == NO)
    {
        videoCounter = 0;
        audioCounter = 0;
        imageCounter = 0;
        
        [videoURLs removeAllObjects];
        [audioURLs removeAllObjects];
        [arrayImagesAttribute removeAllObjects];
        
        [IQFileManager removeItemsAtPath:[[self class] temporaryAudioStoragePath]];
        [IQFileManager removeItemsAtPath:[[self class] temporaryVideoStoragePath]];
        [IQFileManager removeItemsAtPath:[[self class] temporaryImageStoragePath]];
        
        [self.partitionBar setPartitions:[NSArray new] animated:YES];
    }

    [UIView animateWithDuration:0.2 delay:0 options:(UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseOut) animations:^{
        self.settingsContainerView.alpha = 1.0;
    } completion:NULL];
    
    [self.bottomContainerView setLeftContentView:self.buttonCancel];
    [self.bottomContainerView setMiddleContentView:nil];
    [self.bottomContainerView setRightContentView:self.buttonSelect];
    
    if (error == nil)
    {
        if ([[info objectForKey:IQMediaType] isEqualToString:IQMediaTypeVideo])
        {
            NSURL *mediaURL = [info objectForKey:IQMediaURL];
            
            NSString *nextMediaPath = [[[self class] temporaryVideoStoragePath] stringByAppendingFormat:@"/movie%lu.mov",(unsigned long)videoCounter++];
            
            [IQFileManager copyItemAtPath:mediaURL.relativePath toPath:nextMediaPath];
            
            [videoURLs addObject:[IQFileManager URLForFilePath:nextMediaPath]];
            
            NSArray *durations = [IQFileManager durationsOfFilesAtPath:[[self class] temporaryVideoStoragePath]];
            
            [self.partitionBar setPartitions:durations animated:NO];
            [self.mediaView replayVideoAtPath:[IQFileManager URLForFilePath:nextMediaPath]];
        }
        else if ([[info objectForKey:IQMediaType] isEqualToString:IQMediaTypeImage])
        {
            NSURL *mediaURL = [info objectForKey:IQMediaURL];
            
            NSString *nextMediaPath = [[[self class] temporaryImageStoragePath] stringByAppendingFormat:@"/image%lu.jpg",(unsigned long)imageCounter++];
            
            [IQFileManager copyItemAtPath:mediaURL.relativePath toPath:nextMediaPath];
            
            NSMutableDictionary *dict = [info mutableCopy];
            [dict removeObjectForKey:IQMediaType];
            [dict setObject:[IQFileManager URLForFilePath:nextMediaPath] forKey:IQMediaURL];
            
            [arrayImagesAttribute addObject:dict];
        }
        else if ([[info objectForKey:IQMediaType] isEqualToString:IQMediaTypeAudio])
        {
            NSURL *mediaURL = [info objectForKey:IQMediaURL];
            
            NSString *nextMediaPath = [[[self class] temporaryAudioStoragePath] stringByAppendingFormat:@"/audio%lu.m4a",(unsigned long)audioCounter++];
            
            [IQFileManager copyItemAtPath:mediaURL.relativePath toPath:nextMediaPath];
            
            [audioURLs addObject:[IQFileManager URLForFilePath:nextMediaPath]];
            
            NSArray *durations = [IQFileManager durationsOfFilesAtPath:[[self class] temporaryAudioStoragePath]];
            
            [self.partitionBar setPartitions:durations animated:NO];
        }
    }
}

#pragma mark - IQPartitionBar Delegate
-(void)partitionBar:(IQPartitionBar*)bar didSelectPartitionIndex:(NSUInteger)index
{
    if (index != -1 && bar.partitions.count > 0)
    {
        [self.bottomContainerView setLeftContentView:self.buttonDelete];
    }
    else
    {
        [self.bottomContainerView setLeftContentView:self.buttonCancel];
    }
}

#pragma mark - Overrides
-(IQCaptureSession *)session
{
    if (_session == nil)
    {
        _session = [[IQCaptureSession alloc] init];
        [_session setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
        [_session setFocusMode:AVCaptureFocusModeAutoFocus];
    }
    return _session;
}

-(IQMediaView *)mediaView
{
    if (_mediaView == nil)
    {
        _mediaView = [[IQMediaView alloc] initWithFrame:self.view.bounds];
        _mediaView.delegate = self;
    }
    
    return _mediaView;
}

-(UIView *)settingsContainerView
{
    if (_settingsContainerView == nil)
    {
        _settingsContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, 20, 320, 44)];
        [_settingsContainerView addSubview:self.buttonToggleCamera];
        [_settingsContainerView addSubview:self.buttonFlash];
    }
    
    return _settingsContainerView;
}


-(UIButton *)buttonFlash
{
    if (_buttonFlash == nil)
    {
        _buttonFlash = [[UIButton alloc] initWithFrame:CGRectMake(20, 20, 52, 62)];
        [_buttonFlash addTarget:self action:@selector(toggleFlash:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _buttonFlash;
}


-(UIButton *)buttonToggleCamera
{
    if (_buttonToggleCamera == nil)
    {
        _buttonToggleCamera = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 60, 0, 73, 60)];
        [_buttonToggleCamera setImage:[UIImage imageNamed:@"cameraIcon"] forState:UIControlStateNormal];
        [_buttonToggleCamera addTarget:self action:@selector(toggleCameraAction) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _buttonToggleCamera;
}


-(IQBottomContainerView *)bottomContainerView
{
    if (_bottomContainerView == nil)
    {
        _bottomContainerView = [[IQBottomContainerView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.bounds)-90, CGRectGetWidth(self.view.bounds), 90)];
        [_bottomContainerView setTopContentView:self.partitionBar];
        [_bottomContainerView setLeftContentView:self.buttonCancel];
        [_bottomContainerView setMiddleContentView:self.buttonCapture];
        [_bottomContainerView setRightContentView:self.buttonToggleMedia];
    }
    return _bottomContainerView;
}

-(IQPartitionBar *)partitionBar
{
    if (_partitionBar == nil)
    {
        _partitionBar = [[IQPartitionBar alloc] init];
        _partitionBar.delegate = self;
        _partitionBar.backgroundColor = [UIColor clearColor];
    }
    
    return _partitionBar;
}

-(UIImageView *)imageViewProcessing
{
    if (_imageViewProcessing == nil)
    {
        _imageViewProcessing = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"IQ_hourglass"]];
        _imageViewProcessing.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _imageViewProcessing;
}

-(UIButton *)buttonCancel
{
    if (_buttonCancel == nil)
    {
        _buttonCancel = [UIButton buttonWithType:UIButtonTypeCustom];
        [_buttonCancel.titleLabel setFont:[UIFont boldSystemFontOfSize:18.0]];
        UIImageView *cancelCamera = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 36, 36)];
        cancelCamera.image = [UIImage imageNamed:@"cancelCamera"];
        [_buttonCancel addSubview:cancelCamera];
        [_buttonCancel addTarget:self action:@selector(cancelAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _buttonCancel;
}

-(UIButton *)buttonCapture
{
    if (_buttonCapture == nil)
    {
        _buttonCapture = [UIButton buttonWithType:UIButtonTypeCustom];
        [_buttonCapture setImage:[UIImage imageNamed:@"IQ_neutral_mode"] forState:UIControlStateNormal];
        [_buttonCapture addTarget:self action:@selector(captureAction:) forControlEvents:UIControlEventTouchUpInside];
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
        [_buttonCapture addGestureRecognizer:longPress];
        
    }
    
    return _buttonCapture;
}

-(UIButton *)buttonToggleMedia
{
    if (_buttonToggleMedia == nil)
    {
        _buttonToggleMedia = [UIButton buttonWithType:UIButtonTypeCustom];
        [_buttonToggleMedia setImage:[UIImage imageNamed:@"IQ_camera"] forState:UIControlStateNormal];
        [_buttonToggleMedia addTarget:self action:@selector(toggleCaptureMode:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _buttonToggleMedia;
}

-(UIButton *)buttonSelect
{
    if (_buttonSelect == nil)
    {
        _buttonSelect = [UIButton buttonWithType:UIButtonTypeCustom];
        [_buttonSelect.titleLabel setFont:[FontProperties mediumFont:20.0f]];
        [_buttonSelect setTitle:@"Post >" forState:UIControlStateNormal];
        _buttonSelect.titleLabel.layer.shadowColor = [[UIColor blackColor] CGColor];
         _buttonSelect.titleLabel.layer.shadowOffset = CGSizeMake(0.0f, 0.5f);
         _buttonSelect.titleLabel.layer.shadowOpacity = 0.5;
        _buttonSelect.titleLabel.layer.shadowRadius = 0.5;
        [_buttonSelect setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_buttonSelect addTarget:self action:@selector(selectAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _buttonSelect;
}

-(UIButton *)buttonDelete
{
    if (_buttonDelete == nil)
    {
        _buttonDelete = [UIButton buttonWithType:UIButtonTypeCustom];
        [_buttonDelete setImage:[UIImage imageNamed:@"IQ_delete"] forState:UIControlStateNormal];
        [_buttonDelete addTarget:self action:@selector(deleteAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _buttonDelete;
}

#pragma mark - Temporary path
+(NSString*)temporaryVideoStoragePath
{
    NSString *videoPath = [[IQFileManager IQDocumentDirectory] stringByAppendingString:@"/IQVideo/"];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:videoPath] == NO)
        [[NSFileManager defaultManager] createDirectoryAtPath:videoPath withIntermediateDirectories:NO attributes:nil error:NULL];
    
    return videoPath;
}

+(NSString*)temporaryAudioStoragePath
{
    NSString *audioPath = [[IQFileManager IQDocumentDirectory] stringByAppendingString:@"/IQAudio/"];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:audioPath] == NO)
        [[NSFileManager defaultManager] createDirectoryAtPath:audioPath withIntermediateDirectories:NO attributes:nil error:NULL];
    
    return audioPath;
}

+(NSString*)temporaryImageStoragePath
{
    NSString *audioPath = [[IQFileManager IQDocumentDirectory] stringByAppendingString:@"/IQImage/"];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:audioPath] == NO)
        [[NSFileManager defaultManager] createDirectoryAtPath:audioPath withIntermediateDirectories:NO attributes:nil error:NULL];
    
    return audioPath;
}


@end
