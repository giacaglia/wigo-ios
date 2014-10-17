//
//  EventConversationViewController.m
//  Wigo
//
//  Created by Alex Grinman on 10/17/14.
//  Copyright (c) 2014 Alex Grinman. All rights reserved.
//

#import "EventConversationViewController.h"
#import "FontProperties.h"

@interface EventConversationViewController ()
@property (nonatomic, strong) Event *event;
@end

@implementation EventConversationViewController


#pragma mark - ViewController Delegate

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [FontProperties getBlueColor], NSFontAttributeName:[FontProperties getTitleFont]};
    
    self.navigationController.navigationBar.tintColor = [FontProperties getBlueColor];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Inititialization

- (id)initWithEvent: (Event *)event
{
    self = [super init];
    if (self) {
        self.event = event;
        self.title = event.name;
        self.view.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

#pragma mark




@end
