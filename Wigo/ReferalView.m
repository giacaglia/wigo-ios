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

@interface ReferalView () <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>
@end

@implementation ReferalView

-(id) init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

-(void) setup {
    UIView *window = [UIApplication sharedApplication].delegate.window;
    
    self.topView = [[UIView alloc] initWithFrame:window.frame];
    [window addSubview:self.topView];
   
    UIView *blackOverlayView = [[UIView alloc] initWithFrame:window.frame];
    blackOverlayView.backgroundColor = RGBAlpha(0, 0, 0, 0.5f);
    [self.topView addSubview:blackOverlayView];
    
    self.aroundSkipButton = [[UIButton alloc] initWithFrame:CGRectMake(window.frame.size.width - 70, 0, 70, 68)];
    [self.aroundSkipButton addTarget:self action:@selector(aroundSkipPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.topView addSubview:self.aroundSkipButton];
    
    self.skipLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 32, 55, 20)];
    self.skipLabel.text = @"Skip";
    self.skipLabel.textColor = UIColor.whiteColor;
    self.skipLabel.textAlignment = NSTextAlignmentRight;
    self.skipLabel.font = [FontProperties mediumFont:18.0f];
    [self.aroundSkipButton addSubview:self.skipLabel];
    
    self.beforeWeStartLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, window.frame.size.height/2 - 170, window.frame.size.width, 30)];
    self.beforeWeStartLabel.text = @"Before we start...";
    self.beforeWeStartLabel.textColor = UIColor.whiteColor;
    self.beforeWeStartLabel.textAlignment = NSTextAlignmentCenter;
    self.beforeWeStartLabel.font = [FontProperties mediumFont:20.0f];
    [self.topView addSubview:self.beforeWeStartLabel];

    self.didReferLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, window.frame.size.height/2 - 140, window.frame.size.width, 30)];
    self.didReferLabel.text = @"Did anyone refer the app to you?";
    self.didReferLabel.textColor = UIColor.whiteColor;
    self.didReferLabel.textAlignment = NSTextAlignmentCenter;
    self.didReferLabel.font = [FontProperties lightFont:18.0f];
    [self.topView addSubview:self.didReferLabel];
    
    self.aroundTypeNameView = [[UIView alloc] initWithFrame:CGRectMake(0, window.frame.size.height/2 - 34, window.frame.size.width, 64 + 4)];
    self.aroundTypeNameView.backgroundColor = RGB(113, 113, 113);
    [self.topView addSubview:self.aroundTypeNameView];
    
    self.typeNameField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, window.frame.size.width - 15, 64 + 4)];
    self.typeNameField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Type Name" attributes:@{NSForegroundColorAttributeName:RGB(177, 177, 177)}];
    self.typeNameField.textAlignment = NSTextAlignmentCenter;
    self.typeNameField.textColor = UIColor.whiteColor;
    [self.typeNameField becomeFirstResponder];
    self.typeNameField.delegate = self;
    [self.aroundTypeNameView addSubview:self.typeNameField];
    
    self.referalTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 70, window.frame.size.width, window.frame.size.height)];
    self.referalTableView.dataSource = self;
    self.referalTableView.delegate = self;
    self.referalTableView.hidden = YES;
    self.referalTableView.backgroundColor = UIColor.clearColor;
    [self.referalTableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    [self.referalTableView registerClass:[ReferalCell class] forCellReuseIdentifier:kReferalCellName];
    self.referalTableView.separatorColor = RGB(151, 151, 151);
    [self.topView addSubview:self.referalTableView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    
    [self fetchReferals];
}

-(void) aroundSkipPressed {
    [self.typeNameField resignFirstResponder];
    [UIView animateWithDuration:0.5f animations:^{
        self.topView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        self.topView.hidden = YES;
    }];
}

-(BOOL) textField:(UITextField *)textField
shouldChangeCharactersInRange:(NSRange)range
replacementString:(NSString *)string {
    if (string.length > 0) {
        UIView *window = [UIApplication sharedApplication].delegate.window;
        if (self.aroundTypeNameView.frame.origin.y != 0) {
            self.typeNameField.textAlignment = NSTextAlignmentLeft;
            self.skipLabel.font = [FontProperties lightFont:18.0f];
            self.typeNameField.frame = CGRectMake(15, 27, window.frame.size.width - 15, 30);
            [UIView animateWithDuration:0.15f animations:^{
                self.didReferLabel.hidden = YES;
                self.beforeWeStartLabel.hidden = YES;
                self.aroundTypeNameView.frame = CGRectMake(0, 0, window.frame.size.width, 64 + 4);
            } completion:^(BOOL finished) {
                self.referalTableView.hidden = NO;
                self.skipLabel.textColor = RGB(193, 193, 193);
            }];
            [self.topView bringSubviewToFront:self.aroundSkipButton];
         
        }
    }
    if(textField.text.length != 0) {
        [self performBlock:^(void){[self searchTableList:textField.text];}
                afterDelay:0.3
     cancelPreviousRequest:YES];
    }
    return YES;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ReferalCell *cell = [tableView dequeueReusableCellWithIdentifier:kReferalCellName forIndexPath:indexPath];
    cell.faceImageView.image = nil;
    cell.nameLabel.text = @"";
    if (self.presentedUsers.count == 0) return cell;
    WGUser *user = (WGUser *)[self.presentedUsers objectAtIndex:(int)indexPath.item];
    cell.user = user;
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

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.skipLabel.text = @"Select";
    self.skipLabel.font = [FontProperties mediumFont:18.0f];
    self.skipLabel.textColor = UIColor.whiteColor;
}


- (void)keyboardDidShow:(NSNotification *)notification {
    NSDictionary* keyboardInfo = [notification userInfo];
    CGRect kbFrame = [[keyboardInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    self.aroundTypeNameView.frame = CGRectMake(self.aroundTypeNameView.frame.origin.x, (kbFrame.origin.y + self.didReferLabel.frame.origin.y + self.didReferLabel.frame.size.height)/2 - self.aroundTypeNameView.frame.size.height/2, self.aroundTypeNameView.frame.size.width, self.aroundTypeNameView.frame.size.height);
    self.referalTableView.frame = CGRectMake(self.referalTableView.frame.origin.x, self.referalTableView.frame.origin.y, self.referalTableView.frame.size.width, kbFrame.origin.y - self.referalTableView.frame.origin.y);
}

#pragma mark - Network function

-(void) searchTableList:(NSString *)oldString {
    NSString *searchString = [oldString urlEncodeUsingEncoding:NSUTF8StringEncoding];
    __weak typeof(self) weakSelf = self;
    [WGUser searchUsers:searchString withHandler:^(NSURL *url, WGCollection *collection, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (error) {
                [[WGError sharedInstance] logError:error forAction:WGActionLoad];
                return;
            }
            NSArray *separateArray = [url.absoluteString componentsSeparatedByString:@"="];
            NSString *searchedString = (NSString *)separateArray.lastObject;
            if ([searchedString isEqual:strongSelf.typeNameField.text]) {
                strongSelf.presentedUsers = collection;
                [strongSelf.referalTableView reloadData];
            }
        });
    }];
}

-(void) fetchReferals {
    __weak typeof(self) weakSelf = self;
    [WGUser getReferals:^(WGCollection *collection, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        dispatch_async(dispatch_get_main_queue(), ^(void) {
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
    return 65.0f;
}

-(id) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}

-(void) setup {
    self.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [ReferalCell height]);
    self.contentView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [ReferalCell height]);
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.backgroundColor = UIColor.clearColor;
    self.faceImageView = [[UIImageView alloc] initWithFrame:CGRectMake(15, 0, 50, 50)];
    self.faceImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.faceImageView.clipsToBounds = YES;
    self.faceImageView.center = CGPointMake(self.faceImageView.center.x, self.center.y);
    self.faceImageView.layer.borderColor = UIColor.clearColor.CGColor;
    self.faceImageView.layer.borderWidth = 1.0f;
    self.faceImageView.layer.cornerRadius = self.faceImageView.frame.size.width/2;
    [self.contentView addSubview:self.faceImageView];
    
    self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(65 + 10, 0, [UIScreen mainScreen].bounds.size.width - 55 - 10 - 15, [ReferalCell height])];
    self.nameLabel.center = CGPointMake(self.nameLabel.center.x, self.center.y);
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

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    if (selected) {
        self.nameLabel.textColor = [FontProperties getBlueColor];
        self.nameLabel.font = [FontProperties mediumFont:20.0f];
        self.backgroundColor = UIColor.whiteColor;
    }
    else {
        self.nameLabel.textColor = UIColor.whiteColor;
        self.nameLabel.font = [FontProperties lightFont:20.0f];
        self.backgroundColor = UIColor.clearColor;
    }
}

@end