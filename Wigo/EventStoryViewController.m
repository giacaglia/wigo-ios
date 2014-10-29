//
//  EventStoryViewController.m
//  Wigo
//
//  Created by Alex Grinman on 10/24/14.
//  Copyright (c) 2014 Alex Grinman. All rights reserved.
//

#import "EventStoryViewController.h"
#import "EventConversationViewController.h"
#import "EventPeopleScrollView.h"

@implementation EventStoryViewController

#pragma mark - UIViewController Delegate
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.event.name;
  
    [self loadEventDetails];
    [self loadMessages];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [FontProperties getBlueColor], NSFontAttributeName:[FontProperties getTitleFont]};
    
    self.navigationController.navigationBar.tintColor = [FontProperties getBlueColor];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Loading Messages

- (void)loadEventDetails {
    EventPeopleScrollView *eventScrollView = [[EventPeopleScrollView alloc] initWithEvent:self.event];
    [self.view addSubview:eventScrollView];
}

- (void)loadMessages {
}

- (IBAction)showEventConversation:(id)sender {
    EventConversationViewController *conversationController = [self.storyboard instantiateViewControllerWithIdentifier: @"EventConversationViewController"];
    conversationController.event = self.event;
    conversationController.eventMessages = self.eventMessages;
    
    [self presentViewController: conversationController animated: YES completion: nil];
}


@end
