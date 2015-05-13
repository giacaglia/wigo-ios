//
//  ReferalView.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 5/7/15.
//  Copyright (c) 2015 Giuliano Giacaglia. All rights reserved.
//

#import "ReferalView.h"
#import "Globals.h"

#define kReferalCellName @"referalCellName"

@interface ReferalView () <UITextFieldDelegate, UITableViewDataSource>
@end

@implementation ReferalView

-(id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

-(id) init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

-(void) setup {
    UIView *window = [UIApplication sharedApplication].delegate.window;
    UIView *blackOverlayView = [[UIView alloc] initWithFrame:window.frame];
    blackOverlayView.backgroundColor = RGBAlpha(0, 0, 0, 0.5f);
    [window addSubview:blackOverlayView];
    
    UIButton *aroundSkipButton = [[UIButton alloc] initWithFrame:CGRectMake(window.frame.size.width - 100, 0, 100, 100)];
    [window addSubview:aroundSkipButton];
    
    UILabel *skipLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    skipLabel.text = @"Skip";
    skipLabel.textColor = UIColor.whiteColor;
    skipLabel.textAlignment = NSTextAlignmentLeft;
    skipLabel.font = [FontProperties lightFont:18.0f];
    [aroundSkipButton addSubview:skipLabel];
    
    UILabel *beforeWeStartLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, window.frame.size.height/2 - 200, window.frame.size.width, 100)];
    beforeWeStartLabel.text = @"Before we start...";
    beforeWeStartLabel.textColor = UIColor.whiteColor;
    beforeWeStartLabel.textAlignment = NSTextAlignmentCenter;
    beforeWeStartLabel.font = [FontProperties mediumFont:20.0f];
    [window addSubview:beforeWeStartLabel];

    UILabel *didReferLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, window.frame.size.height/2 - 100, window.frame.size.width, 100)];
    didReferLabel.text = @"Did anyone refer the app to you?";
    didReferLabel.textColor = UIColor.whiteColor;
    didReferLabel.textAlignment = NSTextAlignmentCenter;
    didReferLabel.font = [FontProperties lightFont:18.0f];
    [window addSubview:didReferLabel];
    
    self.typeNameField = [[UITextField alloc] initWithFrame:CGRectMake(0, window.frame.size.height/2 - 35, window.frame.size.width, 70)];
    self.typeNameField.placeholder = @"Type Name";
    self.typeNameField.backgroundColor = RGBAlpha(113, 113, 113, 0.5f);
    self.typeNameField.textColor = UIColor.whiteColor;
    [self.typeNameField becomeFirstResponder];
    self.typeNameField.delegate = self;
    [window addSubview:self.typeNameField];
    
    self.referalTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 70, window.frame.size.width, window.frame.size.height)];
    self.referalTableView.dataSource = self;
    self.referalTableView.hidden = YES;
    [self.referalTableView registerClass:[ReferalCell class] forCellReuseIdentifier:kReferalCellName];
    [window addSubview:self.referalTableView];
    [self fetchReferals];
}

- (BOOL)textField:(UITextField *)textField
shouldChangeCharactersInRange:(NSRange)range
replacementString:(NSString *)string {
    if (string.length > 0) {
        UIView *window = [UIApplication sharedApplication].delegate.window;
        self.typeNameField.frame = CGRectMake(0, 0, window.frame.size.width, 70);
    }
    return YES;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ReferalCell *cell = [tableView dequeueReusableCellWithIdentifier:kReferalCellName forIndexPath:indexPath];
    cell.faceImageView.image = nil;
    cell.nameLabel.text = @"";
    if (self.presentedUsers.count == 0) return cell;
    WGUser *user = (WGUser *)[self.presentedUsers objectAtIndex:(int)indexPath.item];
    [cell.faceImageView setSmallImageForUser:user completed:nil];
    cell.nameLabel.text = user.fullName;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [ReferalCell height];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.presentedUsers.count;
}

#pragma mark - Network function

-(void) fetchReferals {
    [WGSpinnerView addDancingGToCenterView:self];
    __weak typeof(self) weakSelf = self;
    [WGUser getReferals:^(WGCollection *collection, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [WGSpinnerView removeDancingGFromCenterView: strongSelf];
            if (error) {
                [[WGError sharedInstance] logError:error forAction:WGActionLoad];
                return;
            }
            strongSelf.presentedUsers = collection;
            [strongSelf.referalTableView reloadData];
        });
    }];
}

@end


@implementation ReferalCell

+(CGFloat) height {
    return 50.0f;
}

-(id) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}

-(void) setup {
    self.faceImageView = [[UIImageView alloc] initWithFrame:CGRectMake(15, 0, 50, [ReferalCell height])];
    self.faceImageView.center = self.center;
    self.faceImageView.layer.borderColor = UIColor.clearColor.CGColor;
    self.faceImageView.layer.borderWidth = 1.0f;
    self.faceImageView.layer.cornerRadius = self.faceImageView.frame.size.width/2;
    [self.contentView addSubview:self.faceImageView];
    
    self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 0, 150, [ReferalCell height])];
    self.nameLabel.textColor = UIColor.whiteColor;
    self.nameLabel.textAlignment = NSTextAlignmentLeft;
    self.nameLabel.font = [FontProperties lightFont:20.0f];
    [self.contentView addSubview:self.nameLabel];
}

-(void) setUser:(WGUser *)user {
    _user = user;
    [self.faceImageView setSmallImageForUser:user completed:nil];
    self.nameLabel.text = user.fullName;
}

@end