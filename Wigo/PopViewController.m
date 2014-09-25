//
//  PopViewController.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 9/24/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "PopViewController.h"
#import "Globals.h"

@interface PopViewController ()

@end

@implementation PopViewController

- (id)init {
    self = [super init];
    if (self) {
        self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background"]];
//        self.view.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initializeEmojiLabel];
    [self initializeTitleLabel];
    [self initializeButton];
    // Do any additional setup after loading the view.
}

- (void)initializeEmojiLabel {
    UILabel *emojiLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 60, self.view.frame.size.width - 30, 140)];
//    NSString *str = @"It's Monday \U0001F60F";
//    NSString *str = @"Its Tuesday Boozeday \U0001F37A";
//    NSString *str = @"It's Hump Day \U0001F42B";
//    NSString *str = @"It's Thirsty Thursday \U0001F378";
//    NSString *str = @"It's Finally Friday \U0001F389";
//    NSString *str = @"It's Saturday \U0001F380";
//    NSString *str = @"It's Sunday Funday \U0001F60E";
    NSString *str = @"\U0001F60E";
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
                                             initWithString:[NSString stringWithFormat:@"It's Sunday Funday!"]];
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
    subtitleLabel.text = @"The weekend's not over yet!";
    subtitleLabel.font = [FontProperties mediumFont:22.0f];
    [self.view addSubview:subtitleLabel];
}

- (void)initializeButton {
    UIButton *acceptButton = [[UIButton alloc] initWithFrame:CGRectMake(30, 380, self.view.frame.size.width - 60, 60)];
    acceptButton.layer.borderColor = [UIColor clearColor].CGColor;
    acceptButton.layer.borderWidth = 2.0f;
    acceptButton.layer.cornerRadius = 15.0f;
    acceptButton.backgroundColor = [FontProperties getOrangeColor];
    [acceptButton setTitle:@"Yes, I am going out" forState:UIControlStateNormal];
    [acceptButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [acceptButton addTarget:self action:@selector(acceptGoingOut) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:acceptButton];
    
    UIButton *notSureYetButton = [[UIButton alloc] initWithFrame:CGRectMake(15, self.view.frame.size.height - 30 - 40, self.view.frame.size.width - 30, 30)];
    [notSureYetButton setTitle:@"Not sure yet" forState:UIControlStateNormal];
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
