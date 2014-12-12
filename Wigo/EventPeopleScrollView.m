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

- (id)initWithEvent:(Event *)event {
    if (self.sizeOfEachImage == 0) self.sizeOfEachImage = 90;
    self = [super initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, self.sizeOfEachImage + 10)];
    if (self) {
        self.contentSize = CGSizeMake(5, self.sizeOfEachImage + 10);
        self.showsHorizontalScrollIndicator = NO;
        self.delegate = self;
        self.event = event;
    }
    return self;
}


- (void)updateUI {
//    self.frame = CGRectMake(0, 0, 320, self.sizeOfEachImage + 10);
//    self.contentSize = CGSizeMake(5, self.sizeOfEachImage + 10);
    [self fillEventAttendees];
    [self loadUsers];
    self.page = @2;
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // Add 3 images
    if (scrollView.contentOffset.x + [[UIScreen mainScreen] bounds].size.width  + 3*self.sizeOfEachImage >= scrollView.contentSize.width - self.sizeOfEachImage &&

        !self.fetchingEventAttendees) {
        [self fetchEventAttendeesAsynchronous];
    }

}

- (void)fillEventAttendees {
    NSArray *eventAttendeesArray = [self.event getEventAttendees];
    self.partyUser = [[Party alloc] initWithObjectType:USER_TYPE];
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
        [self.partyUser addObject:user];
    }
}


- (void)loadUsers {
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.xPosition = 12;
    for (int i = 0; i < [[self.partyUser getObjectArray] count]; i++) {
        User *user = [[self.partyUser getObjectArray] objectAtIndex:i];
        if ([user isEqualToUser:[Profile user]]) {
            user = [Profile user];
        }
        UIButton *imageButton = [[UIButton alloc] initWithFrame:CGRectMake(self.xPosition, 10, self.sizeOfEachImage, self.sizeOfEachImage)];
        imageButton.tag = i;
        [imageButton addTarget:self action:@selector(chooseUser:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:imageButton];
        
        UIImageView *imgView = [[UIImageView alloc] init];
        imgView.frame = CGRectMake(0, 0, self.sizeOfEachImage, self.sizeOfEachImage);
        imgView.contentMode = UIViewContentModeScaleAspectFill;
        imgView.clipsToBounds = YES;
        [imgView setImageWithURL:[NSURL URLWithString:[user coverImageURL]] imageArea:[user coverImageArea]];
        [imageButton addSubview:imgView];
        
        UILabel *profileName = [[UILabel alloc] initWithFrame:CGRectMake(self.xPosition, self.sizeOfEachImage + 5, self.self.sizeOfEachImage, 25)];
        profileName.text = [user firstName];
        profileName.textColor = [UIColor blackColor];
        profileName.textAlignment = NSTextAlignmentCenter;
        profileName.font = [FontProperties lightFont:14.0f];
        [self addSubview:profileName];
        
        self.xPosition += self.sizeOfEachImage + 3;
        self.contentSize = CGSizeMake(self.xPosition, self.sizeOfEachImage + 10);
    }
    
    if ([[self.placesDelegate.eventOffsetDictionary allKeys] containsObject:[[self.event eventID] stringValue]]) {
        NSNumber *xNumber = [self.placesDelegate.eventOffsetDictionary valueForKey:[[self.event eventID] stringValue]];
        self.contentOffset = CGPointMake([xNumber intValue], 0);
    }
}

- (void)chooseUser:(id)sender {
    UIButton *buttonSender = (UIButton *)sender;
    int tag = (int)buttonSender.tag;
    User *user = [[self.partyUser getObjectArray] objectAtIndex:tag];
    self.eventOffset = self.contentOffset.x;
    [self.placesDelegate.eventOffsetDictionary setValue:[NSNumber numberWithInt:self.contentOffset.x]
                                                 forKey:[[self.event eventID] stringValue]];
    [self.placesDelegate showUser:user];
    [self.userSelectDelegate showUser: user];
}


- (void)fetchEventAttendeesAsynchronous {
    NSNumber *eventId = [self.event eventID];
    if (!self.fetchingEventAttendees && ![self.page isEqualToNumber:@-1]) {
        self.fetchingEventAttendees = YES;
        NSString *queryString;
        if (self.groupID) {
              queryString = [NSString stringWithFormat:@"eventattendees/?group=%@&event=%@&limit=10&page=%@", [self.groupID stringValue] , [eventId stringValue], [self.page stringValue]];
        }
        else {
            queryString = [NSString stringWithFormat:@"eventattendees/?event=%@&limit=10&page=%@", [eventId stringValue], [self.page stringValue]];
        }
       
        [Network queryAsynchronousAPI:queryString
                          withHandler:^(NSDictionary *jsonResponse, NSError *error) {
                              dispatch_async(dispatch_get_main_queue(), ^(void){
                                  NSArray *eventAttendeesArray = [jsonResponse objectForKey:@"objects"];
                                  [self.event addEventAttendees:eventAttendeesArray];
                                  if (self.placesDelegate) {
                                      [self.placesDelegate updateEvent:self.event];
                                  }
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
                                      [self.partyUser addObject:user];
                                  }
                                  if ([eventAttendeesArray count] > 0) {
                                      self.page = @([self.page intValue] + 1);
                                      self.eventOffset = self.contentOffset.x;
                                      [self.placesDelegate.eventOffsetDictionary setValue:[NSNumber numberWithInt:self.contentOffset.x]
                                                                                   forKey:[[self.event eventID] stringValue]];
                                      [self loadUsers];
                                  }
                                  else {
                                      self.page = @-1;
                                  }
                                  self.fetchingEventAttendees = NO;
                              });
        }];
    }
    else self.fetchingEventAttendees = NO;
}

@end
