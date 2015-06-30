//
//  ConversationViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/27/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "ConversationViewController.h"
#import "Globals.h"
#import "UIButtonAligned.h"
#import "ProfileViewController.h"
#define kTimeDifferenceToShowDate 1800 // 30 minutes

@implementation ConversationViewController

- (id)initWithUser: (WGUser *)user
{
    self = [super init];
    if (self) {
        self.user = user;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.dataSource = self;
    self.delegate = self;
    self.view.backgroundColor = UIColor.whiteColor;
    
    [self initializeLeftBarButton];
    [self initializeRightBarButton];
    [self initializeBlueView];
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    CGRect frame =  self.navigationController.navigationBar.frame;
    self.navigationController.navigationBar.frame =  CGRectMake(frame.origin.x, 20, frame.size.width, frame.size.height);
    self.title = self.user.fullName;
    [self.navigationController.navigationBar setBackgroundImage:[[FontProperties getBlueColor] imageFromColor]
                                                  forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.barTintColor = UIColor.whiteColor;
    self.blueBannerView.hidden = NO;
    
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [self.navigationController.navigationBar setBackgroundImage:[[FontProperties getBlueColor] imageFromColor] forBarMetrics:UIBarMetricsDefault];
    
    [WGAnalytics tagEvent:@"Conversation View"];
    [WGAnalytics tagView:@"conversation" withTargetUser:nil];
}

-(void) viewWillDisappear:(BOOL)animated {
    self.blueBannerView.hidden = YES;
    WGProfile.currentUser.lastMessageRead = [NSDate date];
}

-(void) initializeBlueView {
    self.blueBannerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 20)];
    self.blueBannerView.backgroundColor = [FontProperties getBlueColor];
    [self.navigationController.view addSubview:self.blueBannerView];
}


-(void) keyboardWillShow:(NSNotification *)notification {
    if (!self.viewForEmptyConversation) return;
    
    [UIView
     animateWithDuration:0.5
     animations:^{
         self.viewForEmptyConversation.frame = CGRectMake(self.viewForEmptyConversation.frame.origin.x, self.viewForEmptyConversation.frame.origin.y / 2, self.viewForEmptyConversation.frame.size.width, self.viewForEmptyConversation.frame.size.height);
     }];
    
}

-(void) keyboardWillHide:(NSNotification *)notification {
    if (!self.viewForEmptyConversation) return;
    [UIView
     animateWithDuration:0.5
     animations:^{
         self.viewForEmptyConversation.frame = CGRectMake(self.viewForEmptyConversation.frame.origin.x, self.viewForEmptyConversation.frame.origin.y * 2, self.viewForEmptyConversation.frame.size.width, self.viewForEmptyConversation.frame.size.height);
     }];
}

- (void) initializeLeftBarButton {
    UIButtonAligned *barBt = [[UIButtonAligned alloc] initWithFrame:CGRectMake(0, 0, 65, 44) andType:@0];
    [barBt setImage:[UIImage imageNamed:@"whiteBackIcon"] forState:UIControlStateNormal];
    [barBt setTitle:@" Back" forState:UIControlStateNormal];
    [barBt setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    barBt.titleLabel.font = [FontProperties getSubtitleFont];
    [barBt addTarget:self action: @selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barItem =  [[UIBarButtonItem alloc]init];
    [barItem setCustomView:barBt];
    self.navigationItem.leftBarButtonItem = barItem;
}

- (void) initializeRightBarButton {
    UIButtonAligned *profileButton = [[UIButtonAligned alloc] initWithFrame:CGRectMake(0, 0, 30, 30) andType:@3];
    [profileButton addTarget:self action:@selector(showUser) forControlEvents:UIControlEventTouchUpInside];
    UIImageView *profileImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    profileImageView.clipsToBounds = YES;
    profileImageView.layer.borderColor = UIColor.clearColor.CGColor;
    profileImageView.layer.borderWidth = 1.0f;
    profileImageView.layer.cornerRadius = profileImageView.frame.size.width/2;
    [profileImageView setSmallImageForUser:self.user completed:nil];
    [profileButton addSubview:profileImageView];
    [profileButton setShowsTouchWhenHighlighted:NO];
    UIBarButtonItem *profileBarButton =[[UIBarButtonItem alloc] initWithCustomView:profileButton];
    self.navigationItem.rightBarButtonItem = profileBarButton;
}


- (void) goBack {
    self.navigationController.navigationBarHidden = self.hideNavBar;
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)showUser {
    ProfileViewController* profileViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier: @"ProfileViewController"];
    self.user.isFriend = @YES;
    profileViewController.user = self.user;
    
    [self.navigationController pushViewController:profileViewController animated:YES];
}


#pragma mark - ATLConversationViewControllerDataSource

typedef NS_ENUM(NSInteger, ATLMDateProximity) {
    ATLMDateProximityToday,
    ATLMDateProximityYesterday,
    ATLMDateProximityWeek,
    ATLMDateProximityYear,
    ATLMDateProximityOther,
};

static ATLMDateProximity ATLMProximityToDate(NSDate *date)
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *now = [NSDate date];
    NSCalendarUnit calendarUnits = NSEraCalendarUnit | NSYearCalendarUnit | NSWeekOfMonthCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
    NSDateComponents *dateComponents = [calendar components:calendarUnits fromDate:date];
    NSDateComponents *todayComponents = [calendar components:calendarUnits fromDate:now];
    if (dateComponents.day == todayComponents.day &&
        dateComponents.month == todayComponents.month &&
        dateComponents.year == todayComponents.year &&
        dateComponents.era == todayComponents.era) {
        return ATLMDateProximityToday;
    }
    
    NSDateComponents *componentsToYesterday = [NSDateComponents new];
    componentsToYesterday.day = -1;
    NSDate *yesterday = [calendar dateByAddingComponents:componentsToYesterday toDate:now options:0];
    NSDateComponents *yesterdayComponents = [calendar components:calendarUnits fromDate:yesterday];
    if (dateComponents.day == yesterdayComponents.day &&
        dateComponents.month == yesterdayComponents.month &&
        dateComponents.year == yesterdayComponents.year &&
        dateComponents.era == yesterdayComponents.era) {
        return ATLMDateProximityYesterday;
    }
    
    if (dateComponents.weekOfMonth == todayComponents.weekOfMonth &&
        dateComponents.month == todayComponents.month &&
        dateComponents.year == todayComponents.year &&
        dateComponents.era == todayComponents.era) {
        return ATLMDateProximityWeek;
    }
    
    if (dateComponents.year == todayComponents.year &&
        dateComponents.era == todayComponents.era) {
        return ATLMDateProximityYear;
    }
    
    return ATLMDateProximityOther;
}

static NSDateFormatter *ATLMShortTimeFormatter()
{
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.timeStyle = NSDateFormatterShortStyle;
    }
    return dateFormatter;
}

static NSDateFormatter *ATLMDayOfWeekDateFormatter()
{
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"EEEE"; // Tuesday
    }
    return dateFormatter;
}

static NSDateFormatter *ATLMRelativeDateFormatter()
{
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        dateFormatter.doesRelativeDateFormatting = YES;
    }
    return dateFormatter;
}

static NSDateFormatter *ATLMThisYearDateFormatter()
{
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"E, MMM dd,"; // Sat, Nov 29,
    }
    return dateFormatter;
}

static NSDateFormatter *ATLMDefaultDateFormatter()
{
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"MMM dd, yyyy,"; // Nov 29, 2013,
    }
    return dateFormatter;
}

- (id<ATLParticipant>)conversationViewController:(ATLConversationViewController *)conversationViewController participantForIdentifier:(NSString *)participantIdentifier
{
    if (participantIdentifier) {
        for (WGUser *user in NetworkFetcher.defaultGetter.allUsers) {
            if ([participantIdentifier isEqual:user.id.stringValue]) {
                return user;
            }
        }
    }
    return nil;
}


- (NSAttributedString *)conversationViewController:(ATLConversationViewController *)conversationViewController attributedStringForDisplayOfDate:(NSDate *)date {
    NSDateFormatter *dateFormatter;
    ATLMDateProximity dateProximity = ATLMProximityToDate(date);
    switch (dateProximity) {
        case ATLMDateProximityToday:
        case ATLMDateProximityYesterday:
            dateFormatter = ATLMRelativeDateFormatter();
            break;
        case ATLMDateProximityWeek:
            dateFormatter = ATLMDayOfWeekDateFormatter();
            break;
        case ATLMDateProximityYear:
            dateFormatter = ATLMThisYearDateFormatter();
            break;
        case ATLMDateProximityOther:
            dateFormatter = ATLMDefaultDateFormatter();
            break;
    }
    
    NSString *dateString = [dateFormatter stringFromDate:date];
    NSString *timeString = [ATLMShortTimeFormatter() stringFromDate:date];
    
    NSMutableAttributedString *dateAttributedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %@", dateString, timeString]];
    [dateAttributedString addAttribute:NSForegroundColorAttributeName value:[UIColor grayColor] range:NSMakeRange(0, dateAttributedString.length)];
    [dateAttributedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:11] range:NSMakeRange(0, dateAttributedString.length)];
    [dateAttributedString addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:11] range:NSMakeRange(0, dateString.length)];
    return dateAttributedString;
}

//- (NSAttributedString *)conversationViewController:(ATLConversationViewController *)conversationViewController attributedStringForDisplayOfRecipientStatus:(NSDictionary *)recipientStatus {
//    NSMutableDictionary *mutableRecipientStatus = [recipientStatus mutableCopy];
//    if ([mutableRecipientStatus valueForKey:LayerHelper.defaultLyrClient.authenticatedUserID]) {
//        [mutableRecipientStatus removeObjectForKey:LayerHelper.defaultLyrClient.authenticatedUserID];
//    }
//    
//    NSString *statusString = [NSString new];
//    if (mutableRecipientStatus.count > 1) {
//        __block NSUInteger readCount = 0;
//        __block BOOL delivered = NO;
//        __block BOOL sent = NO;
//        __block BOOL pending = NO;
//        [mutableRecipientStatus enumerateKeysAndObjectsUsingBlock:^(NSString *userID, NSNumber *statusNumber, BOOL *stop) {
//            LYRRecipientStatus status = statusNumber.integerValue;
//            switch (status) {
//                case LYRRecipientStatusInvalid:
//                    break;
//                case LYRRecipientStatusPending:
//                    pending = YES;
//                    break;
//                case LYRRecipientStatusSent:
//                    sent = YES;
//                    break;
//                case LYRRecipientStatusDelivered:
//                    delivered = YES;
//                    break;
//                case LYRRecipientStatusRead:
//                    NSLog(@"Read");
//                    readCount += 1;
//                    break;
//            }
//        }];
//        if (readCount) {
//            NSString *participantString = readCount > 1 ? @"Participants" : @"Participant";
//            statusString = [NSString stringWithFormat:@"Read by %lu %@", (unsigned long)readCount, participantString];
//        } else if (pending) {
//            statusString = @"Pending";
//        }else if (delivered) {
//            statusString = @"Delivered";
//        } else if (sent) {
//            statusString = @"Sent";
//        }
//    } else {
//        __block NSString *blockStatusString = [NSString new];
//        [mutableRecipientStatus enumerateKeysAndObjectsUsingBlock:^(NSString *userID, NSNumber *statusNumber, BOOL *stop) {
//            if ([userID isEqualToString:LayerHelper.defaultLyrClient.authenticatedUserID]) return;
//            LYRRecipientStatus status = statusNumber.integerValue;
//            switch (status) {
//                case LYRRecipientStatusInvalid:
//                    blockStatusString = @"Not Sent";
//                    break;
//                case LYRRecipientStatusPending:
//                    blockStatusString = @"Pending";
//                    break;
//                case LYRRecipientStatusSent:
//                    blockStatusString = @"Sent";
//                    break;
//                case LYRRecipientStatusDelivered:
//                    blockStatusString = @"Delivered";
//                    break;
//                case LYRRecipientStatusRead:
//                    blockStatusString = @"Read";
//                    break;
//            }
//        }];
//        statusString = blockStatusString;
//    }
//    return [[NSAttributedString alloc] initWithString:statusString attributes:@{NSFontAttributeName : [UIFont boldSystemFontOfSize:11]}];
//}


@end