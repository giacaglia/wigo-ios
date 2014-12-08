//
//  EventPeopleScrollView.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 10/29/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "EventPeopleScrollView.h"
#import "Globals.h"

#define sizeOfEachImage 90

BOOL fetchingEventAttendees;
NSNumber *page;
int xPosition;
Event *event;

@implementation EventPeopleScrollView

- (id)initWithEvent:(Event *)event {
    self = [super initWithFrame:CGRectMake(0, 0, 320, sizeOfEachImage + 10)];
    if (self) {
        self.contentSize = CGSizeMake(5, sizeOfEachImage + 10);
        self.showsHorizontalScrollIndicator = NO;
        self.delegate = self;
        self.event = event;
    }
    return self;
}


- (void)updateUI {
    page = @2;
    [self fillEventAttendees];
    [self loadUsers];
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.contentOffset.x + 320 >= scrollView.contentSize.width - sizeOfEachImage && !fetchingEventAttendees) {
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
    xPosition = 12;
    for (int i = 0; i < [[self.partyUser getObjectArray] count]; i++) {
        User *user = [[self.partyUser getObjectArray] objectAtIndex:i];
        if ([user isEqualToUser:[Profile user]]) {
            user = [Profile user];
        }
        UIButton *imageButton = [[UIButton alloc] initWithFrame:CGRectMake(xPosition, 10, sizeOfEachImage, sizeOfEachImage)];
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
        
        UILabel *nameBackground = [[UILabel alloc] initWithFrame:CGRectMake(0, sizeOfEachImage - 25, sizeOfEachImage, 25)];
        nameBackground.backgroundColor = RGBAlpha(0, 0, 0, 0.6f);
        [imgView addSubview:nameBackground];
        
        UILabel *profileName = [[UILabel alloc] initWithFrame:nameBackground.frame];
        profileName.text = [user firstName];
        profileName.textColor = [UIColor whiteColor];
        profileName.textAlignment = NSTextAlignmentCenter;
        profileName.font = [FontProperties lightFont:14.0f];
        [imgView addSubview:profileName];
    }
    
    int usersCantSee = (int)[[self.event numberAttending] intValue] - (int)[[self.partyUser getObjectArray] count];
    if (usersCantSee  > 0) {
        UIButton *imageButton = [[UIButton alloc] initWithFrame:CGRectMake(xPosition, 10, sizeOfEachImage, sizeOfEachImage)];
        xPosition += sizeOfEachImage + 3;
        [self addSubview:imageButton];
        self.contentSize = CGSizeMake(xPosition, sizeOfEachImage + 10);
        
        UIImageView *imgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"privacyLogo"]];
        imgView.frame = CGRectMake(0, 0, sizeOfEachImage, sizeOfEachImage);
        [imageButton addSubview:imgView];
        
        UILabel *profileName = [[UILabel alloc] init];
        profileName.text = [NSString stringWithFormat:@"+ %d more", usersCantSee ];;
        profileName.textColor = [UIColor whiteColor];
        profileName.textAlignment = NSTextAlignmentCenter;
        profileName.frame = CGRectMake(0, sizeOfEachImage - 20, sizeOfEachImage, 20);
        profileName.backgroundColor = RGBAlpha(0, 0, 0, 0.6f);
        profileName.font = [FontProperties getSmallPhotoFont];
        [imgView addSubview:profileName];
    }
}

- (void)chooseUser:(id)sender {
    UIButton *buttonSender = (UIButton *)sender;
    int tag = buttonSender.tag;
    User *user = [[self.partyUser getObjectArray] objectAtIndex:tag];
    [self.placesDelegate showUser:user];
}

- (void)fetchEventAttendeesAsynchronous {
    NSNumber *eventId = [self.event eventID];
    if (!fetchingEventAttendees && [page isEqualToNumber:@-1]) {
        fetchingEventAttendees = YES;
        NSString *queryString;
        if (self.groupID) {
              queryString = [NSString stringWithFormat:@"eventattendees/?group=%@&event=%@&limit=10&page=%@", [self.groupID stringValue] , [eventId stringValue], [page stringValue]];
        }
        else {
            queryString = [NSString stringWithFormat:@"eventattendees/?event=%@&limit=10&page=%@", [eventId stringValue], [page stringValue]];
        }
       
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
                                      [self.partyUser addObject:user];
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
