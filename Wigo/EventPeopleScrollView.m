//
//  EventPeopleScrollView.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 10/29/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "EventPeopleScrollView.h"
#import "Globals.h"

#define sizeOfEachImage 100

BOOL fetchingEventAttendees;
NSNumber *page;
Party *partyUser;
int xPosition;
Event *event;

@implementation EventPeopleScrollView

- (id)initWithEvent:(Event *)event {
    self = [super initWithFrame:CGRectMake(0, 0, 320, sizeOfEachImage + 10)];
    if (self) {
        self.contentSize = CGSizeMake(5, sizeOfEachImage + 10);
        self.showsHorizontalScrollIndicator = NO;
        self.delegate = self;
        _event = event;
    }
    return self;
}


- (void)setEvent:(Event *)event {
    if (event) {
        _event = event;
        page = @1;
        [self fillEventAttendees];
        [self loadUsers];
    }
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.contentOffset.x + 320 >= scrollView.contentSize.width - sizeOfEachImage && !fetchingEventAttendees) {
        fetchingEventAttendees = YES;
        [self fetchEventAttendeesAsynchronous];
    }

}

- (void)fillEventAttendees {
    NSArray *eventAttendeesArray = [_event getEventAttendees];
    partyUser = [[Party alloc] initWithObjectType:USER_TYPE];
    for (int j = 0; j < [eventAttendeesArray count]; j++) {
        NSDictionary *eventAttendee = [eventAttendeesArray objectAtIndex:j];
        NSDictionary *userDictionary = [eventAttendee objectForKey:@"user"];
        User *user;
        if ([userDictionary isKindOfClass:[NSDictionary class]]) {
            if ([Profile isUserDictionaryProfileUser:userDictionary]) {
                user = [Profile user];
            }
            else {
                user = [[User alloc] initWithDictionary:userDictionary];
            }
        }
        [user setValue:[eventAttendee objectForKey:@"event_owner"] forKey:@"event_owner"];
        [partyUser addObject:user];
    }
}


- (void)loadUsers {
    xPosition = 12;
    for (int i = 0; i < [[partyUser getObjectArray] count]; i++) {
        User *user = [[partyUser getObjectArray] objectAtIndex:i];
        if ([user isEqualToUser:[Profile user]]) {
            user = [Profile user];
        }
        UIButton *imageButton = [[UIButton alloc] initWithFrame:CGRectMake(xPosition, 20, sizeOfEachImage, sizeOfEachImage)];
        xPosition += sizeOfEachImage + 3;
        imageButton.tag = i;
        [imageButton addTarget:self action:@selector(chooseUser:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:imageButton];
        self.contentSize = CGSizeMake(xPosition, sizeOfEachImage + 10);
        
        UIImageView *imgView = [[UIImageView alloc] init];
        imgView.frame = CGRectMake(0, 0, sizeOfEachImage, sizeOfEachImage);
        imgView.contentMode = UIViewContentModeScaleAspectFill;
        imgView.clipsToBounds = YES;
        [imgView setImageWithURL:[NSURL URLWithString:[user coverImageURL]] imageArea:[user coverImageArea]];
        [imageButton addSubview:imgView];
        
        UILabel *profileName = [[UILabel alloc] init];
        profileName.text = [user firstName];
        profileName.textColor = [UIColor whiteColor];
        profileName.textAlignment = NSTextAlignmentCenter;
        profileName.frame = CGRectMake(0, sizeOfEachImage - 30, sizeOfEachImage, 30);
        profileName.backgroundColor = RGBAlpha(0, 0, 0, 0.6f);
        profileName.font = [FontProperties lightFont:13.0f];
        [imgView addSubview:profileName];
    }
}

- (void)chooseUser:(id)sender {
//    UIButton *buttonSender = (UIButton *)sender;
//    int tag = buttonSender.tag;
//    User *user = [[partyUser getObjectArray] objectAtIndex:tag];
//    [self.delegate loadViewOfUser:user];
}

- (void)fetchEventAttendeesAsynchronous {
    NSNumber *eventId = [_event eventID];
    if (!fetchingEventAttendees) {
        NSString *queryString = [NSString stringWithFormat:@"eventattendees/?event=%@&limit=10&page=%@", [eventId stringValue], [page stringValue]];
        [Network queryAsynchronousAPI:queryString
                          withHandler:^(NSDictionary *jsonResponse, NSError *error) {
                              dispatch_async(dispatch_get_main_queue(), ^(void){
                                  NSArray *eventAttendeesArray = [jsonResponse objectForKey:@"objects"];
                                  for (int j = 0; j < [eventAttendeesArray count]; j++) {
                                      NSDictionary *eventAttendee = [eventAttendeesArray objectAtIndex:j];
                                      NSDictionary *userDictionary = [eventAttendee objectForKey:@"user"];
                                      User *user;
                                      if ([userDictionary isKindOfClass:[NSDictionary class]]) {
                                          if ([Profile isUserDictionaryProfileUser:userDictionary]) {
                                              user = [Profile user];
                                          }
                                          else {
                                              user = [[User alloc] initWithDictionary:userDictionary];
                                          }
                                      }
                                      [partyUser addObject:user];
                                  }
                                  if ([eventAttendeesArray count] > 0) {
                                      page = @([page intValue] + 1);
                                  }
                                  else {
                                      page = @-1;
                                  }
                                  fetchingEventAttendees = NO;
                              });
        }];
    }
    else fetchingEventAttendees = NO;
}

@end
