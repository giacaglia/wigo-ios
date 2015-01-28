//
//  EventPeopleScrollView.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 10/29/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "EventPeopleScrollView.h"
#import "Globals.h"


@implementation EventPeopleScrollView

- (id)initWithEvent:(WGEvent *)event {
    if (self.sizeOfEachImage == 0) self.sizeOfEachImage = (float)[[UIScreen mainScreen] bounds].size.width/(float)3.7;
    self = [super initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, self.sizeOfEachImage + 25)];
    if (self) {
        self.contentSize = CGSizeMake(15, self.sizeOfEachImage + 10);
        self.showsHorizontalScrollIndicator = NO;
        self.delegate = self;
        self.event = event;
    }
    return self;
}

+ (CGFloat) containerHeight {
    return (float)[[UIScreen mainScreen] bounds].size.width/(float)3.7 + 25;
}


-(void) updateUI {
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    self.xPosition = 10;
    int index = 0;
    for (WGEventAttendee *attendee in self.event.attendees) {
        WGUser *user = attendee.user;
        
        UIButton *imageButton = [[UIButton alloc] initWithFrame:CGRectMake(self.xPosition, 0, self.sizeOfEachImage, self.sizeOfEachImage)];
        imageButton.tag = index;
        index += 1;
        [imageButton addTarget:self action:@selector(chooseUser:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:imageButton];
        
        UIImageView *imgView = [[UIImageView alloc] init];
        imgView.frame = CGRectMake(0, 0, self.sizeOfEachImage, self.sizeOfEachImage);
        imgView.contentMode = UIViewContentModeScaleAspectFill;
        imgView.clipsToBounds = YES;
        [imgView setSmallImageForUser:user completed:nil];
        [imageButton addSubview:imgView];
        
        UILabel *backgroundName = [[UILabel alloc] initWithFrame:CGRectMake(self.xPosition, self.sizeOfEachImage, self.sizeOfEachImage, 25)];
        if ([user isCurrentUser]) backgroundName.backgroundColor = [FontProperties getBlueColor];
        else backgroundName.backgroundColor = RGB(71, 71, 71);
        [self addSubview:backgroundName];
        
        UILabel *profileName = [[UILabel alloc] initWithFrame:CGRectMake(self.xPosition, self.sizeOfEachImage, self.sizeOfEachImage, 25)];
        profileName.text = [user firstName];
        profileName.textColor = [UIColor whiteColor];
        profileName.textAlignment = NSTextAlignmentCenter;
        profileName.font = [FontProperties lightFont:14.0f];
        [self addSubview:profileName];
        
        
        self.xPosition += self.sizeOfEachImage + 3;
        self.contentSize = CGSizeMake(self.xPosition + 10, self.sizeOfEachImage + 25);
    }
    
    [self scrollToSavedPosition];
}

-(void) scrollToSavedPosition {
    if ([self.placesDelegate.eventOffsetDictionary objectForKey:[self.event.id stringValue]]) {
        self.contentOffset = CGPointMake([[self.placesDelegate.eventOffsetDictionary valueForKey:[self.event.id stringValue]] intValue], 0);
    }
}

-(void) saveScrollPosition {
    [self.placesDelegate.eventOffsetDictionary setObject:[NSNumber numberWithInt:self.contentOffset.x] forKey:[self.event.id stringValue]];
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // Add 3 images
    if (scrollView.contentOffset.x + [[UIScreen mainScreen] bounds].size.width + 4 * self.sizeOfEachImage >= scrollView.contentSize.width && !self.fetchingEventAttendees) {
        [self fetchEventAttendeesAsynchronous];
    }
}

- (void)chooseUser:(id)sender {
    UIButton *buttonSender = (UIButton *)sender;
    int tag = (int)buttonSender.tag;
    WGEventAttendee *attendee = (WGEventAttendee *)[self.event.attendees objectAtIndex:tag];
    // self.eventOffset = self.contentOffset.x;
    if (self.userSelectDelegate) {
        [self.userSelectDelegate showUser: attendee.user];
    } else {
        [self.placesDelegate.eventOffsetDictionary setValue:[NSNumber numberWithInt:self.contentOffset.x]
                                                     forKey:[self.event.id stringValue]];
        [self.placesDelegate showUser:attendee.user];
    }
}


- (void)fetchEventAttendeesAsynchronous {
    if (!self.fetchingEventAttendees) {
        self.fetchingEventAttendees = YES;
        __weak typeof(self) weakSelf = self;
        if (self.event.attendees.hasNextPage == nil) {
            [WGEventAttendee getForEvent:self.event withHandler:^(WGCollection *collection, NSError *error) {
                __strong typeof(self) strongSelf = weakSelf;
                if (error) {
                    [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                    strongSelf.fetchingEventAttendees = NO;
                    return;
                }
                [strongSelf.event.attendees addObjectsFromCollection: collection];
                strongSelf.event.attendees.hasNextPage = collection.hasNextPage;
                strongSelf.event.attendees.nextPage = collection.nextPage;
                
                [strongSelf saveScrollPosition];
                [strongSelf updateUI];
                
                strongSelf.fetchingEventAttendees = NO;
            }];
        } else if ([self.event.attendees.hasNextPage boolValue]) {
            [self.event.attendees addNextPage:^(BOOL success, NSError *error) {
                __strong typeof(self) strongSelf = weakSelf;
                if (error) {
                    [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                    strongSelf.fetchingEventAttendees = NO;
                    return;
                }
                
                [strongSelf saveScrollPosition];
                [strongSelf updateUI];
                
                strongSelf.fetchingEventAttendees = NO;
            }];
        } else {
            self.fetchingEventAttendees = NO;
        }
    }
}

@end
