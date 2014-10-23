//
//  MobileDelegate.h
//  Wigo
//
//  Created by Giuliano Giacaglia on 10/23/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>

typedef void (^MobileArray)(NSArray *mobileArray);

@interface MobileDelegate : NSObject

+ (void)getMobileContacts:(MobileArray)mobileArray;

@end
