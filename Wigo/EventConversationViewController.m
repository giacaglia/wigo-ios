//
//  EventConversationViewController.m
//  Wigo
//
//  Created by Alex Grinman on 10/17/14.
//  Copyright (c) 2014 Alex Grinman. All rights reserved.
//

#import "EventConversationViewController.h"
#import "FontProperties.h"
#import "ContentManager.h"
#import "EventMessage.h"
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "Profile.h"

@interface EventConversationViewController ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate>
@property (nonatomic, strong) Event *event;
@property (nonatomic, strong) NSMutableArray *messageDatasource;
@property (nonatomic, strong) UIImage *userProfileImage;
@end

@implementation EventConversationViewController


#pragma mark - ViewController Delegate

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self loadMessages];
}

- (void)loadMessages {
    self.messageDatasource = [[[ContentManager sharedManager] generateConversation] mutableCopy];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [FontProperties getBlueColor], NSFontAttributeName:[FontProperties getTitleFont]};
    
    self.navigationController.navigationBar.tintColor = [FontProperties getBlueColor];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Message Delegate Methods
#pragma mark - SOMessaging data source
- (NSMutableArray *)messages
{
    return self.messageDatasource;
    
}

- (NSTimeInterval)intervalForMessagesGrouping
{
    // Return 0 for disableing grouping
    return 0;
}

- (void)configureMessageCell:(SOMessageCell *)cell forMessageAtIndex:(NSInteger)index
{
    EventMessage *message = self.messageDatasource[index];
    
    // Adjusting content for 3pt. (In this demo the width of bubble's tail is 3pt)
    if (!message.fromMe) {
        cell.contentInsets = UIEdgeInsetsMake(0, 3.0f, 0, 0); //Move content for 3 pt. to right
        cell.textView.textColor = [UIColor blackColor];
    } else {
        cell.contentInsets = UIEdgeInsetsMake(0, 0, 0, 3.0f); //Move content for 3 pt. to left
        cell.textView.textColor = [UIColor whiteColor];
    }
    
    cell.userImageView.layer.cornerRadius = self.userImageSize.width/2;
    
    // Fix user image position on top or bottom.
    cell.userImageView.autoresizingMask = message.fromMe ? UIViewAutoresizingFlexibleTopMargin : UIViewAutoresizingFlexibleBottomMargin;
    
    if (!self.userProfileImage) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSData *imageData = [NSData dataWithContentsOfURL: [NSURL URLWithString: [[Profile user] coverImageURL]]];
            self.userProfileImage = [UIImage imageWithData: imageData];
            dispatch_async(dispatch_get_main_queue(), ^{
                cell.userImage = message.fromMe ? self.userProfileImage: [UIImage imageNamed: @"jobs.jpg"];
            });
        });
    } else {
        cell.userImage = message.fromMe ? self.userProfileImage : [UIImage imageNamed: @"jobs.jpg"];
    }

    // Setting user images
}

- (CGSize)userImageSize
{
    return CGSizeMake(40, 40);
}

#pragma mark - SOMessaging delegate
- (void)didSelectMedia:(NSData *)media inMessageCell:(SOMessageCell *)cell
{
    // Show selected media in fullscreen
    [super didSelectMedia:media inMessageCell:cell];
}

- (void)messageInputView:(SOMessageInputView *)inputView didSendMessage:(NSString *)message
{
    if (![[message stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length]) {
        return;
    }
    
    EventMessage *msg = [[EventMessage alloc] init];
    msg.text = message;
    msg.fromMe = YES;
    
    [self sendMessage:msg];
}

#define kActionPhotoVideo 0
#define kActionLibrary 1
#define kActionCancel 2

- (void)messageInputViewDidSelectMediaButton:(SOMessageInputView *)inputView
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle: @"Add some fun media" delegate: self cancelButtonTitle: @"Cancel" destructiveButtonTitle: nil otherButtonTitles: @"Take a Photo or Video", @"Photo Library", nil];
    
    [actionSheet showInView: self.view];
}

    
#pragma mark - ActionSheet
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == kActionCancel) {
        return;
    }
    
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    
    if (buttonIndex == kActionPhotoVideo) {
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    } else {
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    
    picker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType: picker.sourceType];
    
    [self presentViewController:picker animated:YES completion:NULL];
}

#pragma mark - Image Picker {
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
    
    //video
    if (CFStringCompare ((__bridge CFStringRef) mediaType, kUTTypeMovie, 0) == kCFCompareEqualTo) {
        NSURL *videoUrl=(NSURL*)[info objectForKey:UIImagePickerControllerMediaURL];
        [self generateThumbnailAndSendVideo: videoUrl];
    }
    //image
    else if (CFStringCompare ((__bridge CFStringRef) mediaType, kUTTypeImage, 0) == kCFCompareEqualTo) {

        UIImage *image = [info objectForKey: UIImagePickerControllerEditedImage];
        NSData *imageData = UIImageJPEGRepresentation(image, 0.8);
        [self sendImage: imageData];
    }
    
    [picker dismissViewControllerAnimated: YES completion:nil];
}

- (void) sendImage: (NSData *) data{
    EventMessage *message = [[EventMessage alloc] init];
    message.type = SOMessageTypePhoto;
    message.date = [NSDate date];
    message.media = data;
    message.thumbnail = [UIImage imageWithData: data];
    
    [self sendMessage:message];

}

- (void) sendVideo: (NSData *) data withThumbnail: (UIImage *) thumb {
    EventMessage *message = [[EventMessage alloc] init];
    message.type = SOMessageTypeVideo;
    message.date = [NSDate date];
    message.media = data;
    message.thumbnail = thumb;
    
    [self sendMessage:message];
}
#pragma mark - Helpers

-(void)generateThumbnailAndSendVideo: (NSURL *) videoUrl
{
    AVURLAsset *asset=[[AVURLAsset alloc] initWithURL: videoUrl options:nil];
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform=TRUE;
    CMTime thumbTime = CMTimeMakeWithSeconds(0,30);
    
    AVAssetImageGeneratorCompletionHandler handler = ^(CMTime requestedTime, CGImageRef im, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error){
        if (result != AVAssetImageGeneratorSucceeded) {
            NSLog(@"couldn't generate thumbnail, error:%@", error);
        }
        UIImage *thumb =[UIImage imageWithCGImage:im];
        NSData *videoData = [NSData dataWithContentsOfURL: videoUrl];
        [self sendVideo: videoData withThumbnail: thumb];

    };
    
    CGSize maxSize = CGSizeMake(320, 180);
    generator.maximumSize = maxSize;
    [generator generateCGImagesAsynchronouslyForTimes:[NSArray arrayWithObject:[NSValue valueWithCMTime:thumbTime]] completionHandler:handler];
}

#pragma mark - Inititialization

- (id)initWithEvent: (Event *)event
{
    self = [super init];
    if (self) {
        self.event = event;
        self.title = event.name;
        self.view.backgroundColor = [UIColor whiteColor];
    }
    return self;
}





@end
