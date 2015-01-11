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


- (void)updateUI {
    [self fillEventAttendees];
    [self loadUsers];
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // Add 3 images
    if (scrollView.contentOffset.x + [[UIScreen mainScreen] bounds].size.width  + 3 * self.sizeOfEachImage >= scrollView.contentSize.width - self.sizeOfEachImage &&

        !self.fetchingEventAttendees) {
        [self fetchEventAttendeesAsynchronous];
    }

}

- (void)fillEventAttendees {
    self.attendees = self.event.attendees;
}


- (void)loadUsers {
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];

    self.xPosition = 10;
    int index = 0;
    for (WGEventAttendee *attendee in self.attendees) {
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
        [imgView setImageWithURL:user.coverImageURL imageArea:[user coverImageArea]];
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
    
    if ([[self.placesDelegate.eventOffsetDictionary allKeys] containsObject:[self.event.id stringValue]] && self.placesDelegate.visitedProfile) {
        NSNumber *xNumber = [self.placesDelegate.eventOffsetDictionary valueForKey:[self.event.id stringValue]];
        self.contentOffset = CGPointMake([xNumber intValue], 0);
    }
}

- (void)chooseUser:(id)sender {
    UIButton *buttonSender = (UIButton *)sender;
    int tag = (int)buttonSender.tag;
    WGEventAttendee *attendee = (WGEventAttendee *)[self.attendees objectAtIndex:tag];
    self.eventOffset = self.contentOffset.x;
    if (self.userSelectDelegate) {
        [self.userSelectDelegate showUser: attendee.user];
    }
    else {
        [self.placesDelegate.eventOffsetDictionary setValue:[NSNumber numberWithInt:self.contentOffset.x]
                                                     forKey:[self.event.id stringValue]];
        [self.placesDelegate showUser:attendee.user];
    }
}


- (void)fetchEventAttendeesAsynchronous {
    if (!self.fetchingEventAttendees) {
        self.fetchingEventAttendees = YES;
        __weak typeof(self) weakSelf = self;
        if (self.attendees.hasNextPage == nil) {
            [WGEventAttendee getForEvent:self.event withHandler:^(WGCollection *collection, NSError *error) {
                __strong typeof(self) strongSelf = weakSelf;
                strongSelf.fetchingEventAttendees = NO;
                if (error) {
                    [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                    return;
                }
                strongSelf.attendees = collection;
                
                strongSelf.eventOffset = self.contentOffset.x;
                [strongSelf.placesDelegate.eventOffsetDictionary setValue:[NSNumber numberWithInt:self.contentOffset.x]
                                                             forKey:[self.event.id stringValue]];
                [strongSelf.placesDelegate setVisitedProfile:YES];
                [strongSelf loadUsers];
            }];
        } else if ([self.attendees.hasNextPage boolValue]) {
            [self.attendees addNextPage:^(BOOL success, NSError *error) {
                __strong typeof(self) strongSelf = weakSelf;
                strongSelf.fetchingEventAttendees = NO;
                if (error) {
                    [[WGError sharedInstance] handleError:error actionType:WGActionLoad retryHandler:nil];
                    return;
                }
                strongSelf.eventOffset = strongSelf.contentOffset.x;
                [strongSelf.placesDelegate.eventOffsetDictionary setValue:[NSNumber numberWithInt:strongSelf.contentOffset.x]
                                                             forKey:[strongSelf.event.id stringValue]];
                [strongSelf.placesDelegate setVisitedProfile:YES];
                [strongSelf loadUsers];
            }];
        } else {
            self.fetchingEventAttendees = NO;
        }
    }
}

@end
