//
//  UserTestCase.m
//  Wigo
//
//  Created by Dennis Doughty on 12/1/14.
//  Copyright (c) 2014 Dennis Doughty. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "WGUser.h"

@interface UserTestCase : XCTestCase
@property WGUser *katniss;
@property WGUser *peeta;

@end

@implementation UserTestCase

- (void) setUp {
    [super setUp];
    // this might be a stupid way of setting up the users here.
    NSDictionary *kdict = [[NSDictionary alloc] initWithObjectsAndKeys:@1234, @"id", nil];
    NSDictionary *pdict = [[NSDictionary alloc] initWithObjectsAndKeys:@4321, @"id", nil];
    self.katniss = [WGUser serialize:kdict];
    self.peeta = [WGUser serialize:pdict];
}

- (void) tearDown {
    self.katniss = nil;
    self.peeta = nil;
    [super tearDown];
}

- (void) testExample {
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}

- (void) testUserEqualToOtherUser {
    XCTAssert(![self.katniss isEqual:self.peeta], @"Pass");
}

@end
