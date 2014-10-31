//
//  EventConversationViewController.m
//  Wigo
//
//  Created by Alex Grinman on 10/17/14.
//  Copyright (c) 2014 Alex Grinman. All rights reserved.
//

#import "EventConversationViewController.h"
#import "FontProperties.h"
#import "EventMessage.h"
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "Profile.h"

@interface EventConversationViewController ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate>
@property (nonatomic, strong) UIImage *userProfileImage;
@end

@implementation EventConversationViewController



#pragma mark - ViewController Delegate

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.event.name;
    
    [self loadMessages];
}

- (void)loadMessages {
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UICollectionViewDataSource

-(NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.eventMessages.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    FaceCell *myCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"FaceCell"forIndexPath: indexPath];
    
    return myCell;
}

#pragma mark UICollectionViewFlowLayoutDelegate

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(75,75);
}

- (UIEdgeInsets)collectionView: (UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    
    return UIEdgeInsetsMake(20, 10, 0, 0);
}

#pragma mark - UICollectionViewDelegate

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {

}

#define kActionPhotoVideo 0
#define kActionLibrary 1
#define kActionCancel 2

- (IBAction)tapPhotoVideoButton: (id) sender
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

}

- (void) sendVideo: (NSData *) data withThumbnail: (UIImage *) thumb {

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


@end

@implementation FaceCell

- (id) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder: aDecoder];
    
    if (self) {
        self.backgroundColor = UIColor.redColor;
    }
        
    return self;
}

@end

@implementation FaceLayout

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    layoutAttributes.frame = CGRectMake(10,10,75,75); // or whatever...
    return layoutAttributes;
}

@end
