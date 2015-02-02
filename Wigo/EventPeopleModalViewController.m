//
//  EventPeopleModalViewViewController.m
//  Wigo
//
//  Created by Adam Eagle on 2/1/15.
//  Copyright (c) 2015 Adam Eagle. All rights reserved.
//

#import "EventPeopleModalViewController.h"
#import "EventPeopleScrollView.h"

#define kNameBarHeight 32
#define kBorderWidth 10
#define kMaxVelocity 20

@interface EventPeopleModalViewController ()

@end

int imageWidth;
int initializedLocationCount;

@implementation EventPeopleModalViewController

- (id)initWithEvent:(WGEvent *)event startIndex:(int)index andBackgroundImage:(UIImage *)image {
    self = [super init];
    if (self) {
        self.event = event;
        self.backgroundImage = image;
        self.fetchingEventAttendees = NO;
        self.velocity = 0;
        initializedLocationCount = 0;
        self.startIndex = index;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    imageWidth = [UIScreen mainScreen].bounds.size.width - kBorderWidth * 2;
    
    self.view.backgroundColor = [UIColor clearColor];
    UIImageView* backView = [[UIImageView alloc] initWithFrame:self.view.frame];
    backView.image = self.backgroundImage;
    [self.view addSubview:backView];
    
    self.attendeesPhotosScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, ([UIScreen mainScreen].bounds.size.height - imageWidth - kNameBarHeight) / 2, [UIScreen mainScreen].bounds.size.width, imageWidth + kNameBarHeight)];
    self.attendeesPhotosScrollView.showsHorizontalScrollIndicator = NO;

    [self.view addSubview:self.attendeesPhotosScrollView];
    
    [self updateUI];

    self.attendeesPhotosScrollView.contentOffset = [self indexToOffset:self.startIndex];
    
    [self loadLargeImageForIndex:self.startIndex];
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.016 target:self selector:@selector(updateScrollPosition) userInfo:nil repeats:YES];
}

-(void) updateScrollPosition {
    float minX = 0;
    float maxX = [self indexToOffset:(int)self.event.attendees.count - 1].x;
    float newOffset = self.attendeesPhotosScrollView.contentOffset.x + self.velocity;
    self.attendeesPhotosScrollView.contentOffset = CGPointMake(MAX(minX, MIN(maxX, newOffset)), 0);

    if ((self.attendeesPhotosScrollView.contentOffset.x == maxX && ![self.event.attendees.hasNextPage boolValue]) || self.attendeesPhotosScrollView.contentOffset.x == minX) {
        self.initialPosition = self.lastPosition;
        self.velocity = 0;
    }
    
    self.initialPosition = CGPointMake(self.initialPosition.x * 0.5 + self.lastPosition.x * 0.5, self.initialPosition.y * 0.95 + self.lastPosition.y * 0.05);
    
    int currentIndex = [self indexAtOffset:self.attendeesPhotosScrollView.contentOffset];
    [self loadLargeImageForIndex:currentIndex];
    if (currentIndex + 1 < [self.images count]) {
        [self loadLargeImageForIndex:currentIndex + 1];
    }
    if (currentIndex >= [self.images count] - 2) {
        [self fetchEventAttendeesAsynchronous];
    }
    
    // NSLog(@"Velocity: %f", self.velocity);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void) untap:(UILongPressGestureRecognizer *)gestureRecognizer withSender:(id)sender {
    CGPoint touchPoint = [gestureRecognizer locationInView:self.attendeesPhotosScrollView];
    int touchIndex = [self indexAtPoint:touchPoint];
    WGEventAttendee *attendee;
    for (int i = 0; i < [self.images count]; i++) {
        UIImageView *imageView = (UIImageView *)[self.images objectAtIndex:i];
        if (CGRectContainsPoint(imageView.superview.frame, touchPoint)) {
            attendee = (WGEventAttendee *)[self.event.attendees objectAtIndex:imageView.tag];
        }
    }
    
    EventPeopleScrollView *source = (EventPeopleScrollView *)sender;
    
    [self.placesDelegate.eventOffsetDictionary setObject:[NSNumber numberWithInt:MIN(MAX(0, source.contentSize.width - source.bounds.size.width), MAX(0, [source indexToPoint:touchIndex - 2].x))] forKey:[self.event.id stringValue]];
    
    [source scrollToSavedPosition];
    
    NSLog(@"Scroll Position: %f", source.contentOffset.x);
    
    [self dismissViewControllerAnimated:YES completion:^{
        if (attendee) {
            // Present User Disabled!
            // [self.placesDelegate showUser:attendee.user];
        }
    }];
    [self.timer invalidate];
}

-(void) touchedLocation:(UIGestureRecognizer *)gestureRecognizer {
    self.lastPosition = [gestureRecognizer locationInView:self.view];
    
    if (initializedLocationCount < 5) {
        initializedLocationCount += 1;
        self.initialPosition = self.lastPosition;
        return;
    }
    
    // NSLog(@"Initial: %f", self.initialPosition.x);
    // NSLog(@"Current: %f", self.lastPosition.x);
    
    self.velocity += (self.lastPosition.x - self.initialPosition.x) / 7.5;
    
    if (self.velocity > kMaxVelocity) {
        self.velocity = kMaxVelocity;
    } else if (self.velocity < -kMaxVelocity) {
        self.velocity = -kMaxVelocity;
    }
}

-(int) indexAtPoint:(CGPoint) point {
    return MAX(0, floor((point.x - kBorderWidth) / (imageWidth + kBorderWidth)));
}

-(int) indexAtOffset:(CGPoint) point {
    return MAX(0, floor(point.x / (imageWidth + kBorderWidth)));
}

-(CGPoint) indexToPoint:(int) index {
    return CGPointMake(kBorderWidth + index * (imageWidth + kBorderWidth), 0);
}

-(CGPoint) indexToOffset:(int) index {
    return CGPointMake(index * (imageWidth + kBorderWidth), 0);
}

-(void) loadLargeImageForIndex:(int)index {
    if (![[self.imageDidLoad objectAtIndex:index] boolValue]) {
        UIImageView *imageView = (UIImageView *)[self.images objectAtIndex:index];
        
        UIImage *smallCoverImage = [imageView.image copy];
        
        WGEventAttendee *attendee = (WGEventAttendee *)[self.event.attendees objectAtIndex:index];
        [imageView setImageWithURL:[attendee.user coverImageURL] placeholderImage:smallCoverImage imageArea:[attendee.user coverImageArea] completed:nil];
        [self.imageDidLoad setObject:@YES atIndexedSubscript:index];
    }
}

-(void) updateUI {
    [self.attendeesPhotosScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    self.images = [[NSMutableArray alloc] init];
    self.imageDidLoad = [[NSMutableArray alloc] init];
    int index = 0;
    for (WGEventAttendee *attendee in self.event.attendees) {
        WGUser *user = attendee.user;
        
        CGPoint position = [self indexToPoint:index];
        
        UIButton *imageButton = [[UIButton alloc] initWithFrame:CGRectMake(position.x, position.y, imageWidth, imageWidth)];
        imageButton.tag = index;
        [self.attendeesPhotosScrollView addSubview:imageButton];
        
        UIImageView *imgView = [[UIImageView alloc] init];
        imgView.frame = CGRectMake(0, 0, imageWidth, imageWidth);
        imgView.contentMode = UIViewContentModeScaleAspectFill;
        imgView.clipsToBounds = YES;
        imgView.tag = index;
        [imgView setSmallImageForUser:user completed:nil];
        
        [self.images addObject:imgView];
        [self.imageDidLoad addObject:@NO];
        
        [imageButton addSubview:imgView];
        
        UILabel *backgroundName = [[UILabel alloc] initWithFrame:CGRectMake(position.x, position.y + imageWidth, imageWidth, kNameBarHeight)];
        if ([user isCurrentUser]) {
            backgroundName.backgroundColor = [FontProperties getBlueColor];
        } else {
            backgroundName.backgroundColor = RGBAlpha(0, 0, 0, 0.5f);
        }
        [self.attendeesPhotosScrollView addSubview:backgroundName];
        
        UILabel *profileName = [[UILabel alloc] initWithFrame:CGRectMake(position.x, position.y + imageWidth, imageWidth, kNameBarHeight)];
        profileName.text = [user firstName];
        profileName.textColor = [UIColor whiteColor];
        profileName.textAlignment = NSTextAlignmentCenter;
        profileName.font = [FontProperties lightFont:15.0f];
        [self.attendeesPhotosScrollView addSubview:profileName];
        
        self.attendeesPhotosScrollView.contentSize = CGSizeMake(position.x + kBorderWidth, imageWidth + kNameBarHeight);
        
        index += 1;
    }
}

- (void)fetchEventAttendeesAsynchronous {
    if (!self.fetchingEventAttendees) {
        self.fetchingEventAttendees = YES;
        __weak typeof(self) weakSelf = self;
        if ([self.event.attendees.hasNextPage boolValue]) {
            [self.event.attendees addNextPage:^(BOOL success, NSError *error) {
                __strong typeof(self) strongSelf = weakSelf;
                if (error) {
                    [[WGError sharedInstance] logError:error forAction:WGActionLoad];
                    strongSelf.fetchingEventAttendees = NO;
                    return;
                }
                
                CGPoint oldOffset = strongSelf.attendeesPhotosScrollView.contentOffset;
                [strongSelf updateUI];
                strongSelf.attendeesPhotosScrollView.contentOffset = oldOffset;
                
                strongSelf.fetchingEventAttendees = NO;
            }];
        } else {
            self.fetchingEventAttendees = NO;
        }
    }
}


@end
