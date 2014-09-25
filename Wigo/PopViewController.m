//
//  PopViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 9/24/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "PopViewController.h"
#import "Globals.h"


NSDictionary *dailyDictionary;

@implementation PopViewController

- (id)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        dailyDictionary = dict;
        self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background"]];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([[dailyDictionary allKeys] containsObject:@"emoji"]) [self initializeEmojiLabel];
    if ([[dailyDictionary allKeys] containsObject:@"heading"]) [self initializeTitleLabel];
    if ([[dailyDictionary allKeys] containsObject:@"action"]) [self initializeButton];
}

- (void)initializeEmojiLabel {
    UILabel *emojiLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 60, self.view.frame.size.width - 30, 140)];
    NSString *str = [dailyDictionary objectForKey:@"emoji"];
    NSData *data = [str dataUsingEncoding:NSNonLossyASCIIStringEncoding];
    NSString *valueUnicode = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    NSData *dataa = [valueUnicode dataUsingEncoding:NSUTF8StringEncoding];
    NSString *valueEmoj = [[NSString alloc] initWithData:dataa encoding:NSNonLossyASCIIStringEncoding];
    emojiLabel.text = valueEmoj;
    emojiLabel.textAlignment = NSTextAlignmentCenter;
    emojiLabel.font = [FontProperties mediumFont:120.0f];
    [self.view addSubview:emojiLabel];
}

- (void)initializeTitleLabel {
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 220, self.view.frame.size.width - 30, 40)];
    NSMutableAttributedString * attString = [[NSMutableAttributedString alloc]
                                             initWithString:(NSString *)[dailyDictionary objectForKey:@"heading"]];
    [attString addAttribute:NSFontAttributeName
                      value:[FontProperties mediumFont:30.0f]
                      range:NSMakeRange(0, attString.string.length)];
    [attString addAttribute:NSForegroundColorAttributeName
                      value:[FontProperties getOrangeColor]
                      range:NSMakeRange(4, attString.string.length - 4)];
    titleLabel.attributedText = [[NSAttributedString alloc] initWithAttributedString:attString];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:titleLabel];
    
    UILabel *subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 280, self.view.frame.size.width - 30, 40)];
    subtitleLabel.textAlignment = NSTextAlignmentCenter;
    subtitleLabel.text = [dailyDictionary objectForKey:@"sub_heading"];
    subtitleLabel.font = [FontProperties mediumFont:22.0f];
    [self.view addSubview:subtitleLabel];
}

- (void)initializeButton {
    UIButton *acceptButton = [[UIButton alloc] initWithFrame:CGRectMake(30, 380, self.view.frame.size.width - 60, 60)];
    acceptButton.layer.borderColor = [UIColor clearColor].CGColor;
    acceptButton.layer.borderWidth = 2.0f;
    acceptButton.layer.cornerRadius = 15.0f;
    acceptButton.backgroundColor = [FontProperties getOrangeColor];
    [acceptButton setTitle:[[dailyDictionary objectForKey:@"action"] objectForKey:@"text"] forState:UIControlStateNormal];
    [acceptButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [acceptButton addTarget:self action:@selector(acceptGoingOut) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:acceptButton];
    
    UIButton *notSureYetButton = [[UIButton alloc] initWithFrame:CGRectMake(15, self.view.frame.size.height - 30 - 40, self.view.frame.size.width - 30, 30)];
    [notSureYetButton setTitle:[dailyDictionary objectForKey:@"close_text"] forState:UIControlStateNormal];
    [notSureYetButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    notSureYetButton.titleLabel.font = [FontProperties lightFont:20.0f];
    [notSureYetButton addTarget:self action:@selector(dimissView) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:notSureYetButton];
}

- (void)acceptGoingOut {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dimissView {
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
