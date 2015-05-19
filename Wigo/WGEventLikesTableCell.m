//
//  WGEventLikesTableCell.m
//  Wigo
//
//  Created by Gabriel Mahoney on 5/19/15.
//  Copyright (c) 2015 Gabriel Mahoney. All rights reserved.
//

#import "WGEventLikesTableCell.h"
#import "FontProperties.h"
#import "UIImageView+ImageArea.h"


@interface WGEventLikesTableCell ()

@property (nonatomic,strong) UIView *bottomBorderView;

@end


@implementation WGEventLikesTableCell

+ (CGFloat)rowHeight {
    return 70.0f;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    
    self.backgroundColor = [UIColor clearColor];
    
    self.profileImageView = [[UIImageView alloc] init];
    self.profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.profileImageView.clipsToBounds = YES;
    self.profileImageView.layer.borderWidth = 1.0f;
    self.profileImageView.layer.borderColor = UIColor.clearColor.CGColor;
    [self.contentView addSubview:self.profileImageView];
    
    self.fullNameLabel = [[UILabel alloc] init];
    self.fullNameLabel.font = [FontProperties getSubtitleFont];
    self.fullNameLabel.textColor = [UIColor whiteColor];
    
    [self.contentView addSubview:self.fullNameLabel];
    
    self.bottomBorderView = [[UIView alloc] init];
    self.bottomBorderView.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.5];
    [self.contentView addSubview:self.bottomBorderView];
}

- (void)setUser:(WGUser *)user {
    [self.profileImageView setSmallImageForUser:user completed:nil];
    self.fullNameLabel.text = user.fullName;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect contentFrame = self.contentView.frame;
    
    self.profileImageView.frame = CGRectMake(0,0, 60, 60);
    self.profileImageView.center = CGPointMake(self.profileImageView.frame.size.width/2.0+15.0,
                                               contentFrame.size.height/2.0);
    self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.width/2;
    
    CGFloat leftMargin = CGRectGetMaxX(self.profileImageView.frame)+15.0;
    CGFloat rightMargin = 30.0;
    
    self.fullNameLabel.frame = CGRectMake(leftMargin,
                                          0,
                                          contentFrame.size.width-leftMargin-rightMargin,
                                          20.0);
    self.fullNameLabel.center = CGPointMake(self.fullNameLabel.center.x,
                                            contentFrame.size.height/2.0);
    
    
    CGFloat borderMargin = 10.0;
    self.bottomBorderView.frame = CGRectMake(borderMargin,
                                             contentFrame.size.height-0.5,
                                             contentFrame.size.width-2*borderMargin,
                                             0.5);
    
}


@end
