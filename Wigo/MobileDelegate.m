//
//  MobileDelegate.m
//  Wigo
//
//  Created by Giuliano Giacaglia on 10/23/14.
//  Copyright (c) 2014 Giuliano Giacaglia. All rights reserved.
//

#import "MobileDelegate.h"
#import "Globals.h"

@implementation MobileDelegate

+ (void) getMobileContacts:(MobileArray)mobileArray {
    CFErrorRef error = NULL;
    NSMutableArray *mutableMobileArray = [NSMutableArray new];
    
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, &error);
    ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error) {
        if (granted && addressBookRef) {
            [EventAnalytics tagEvent:@"Accepted Apple Contacts"];
            
            
            CFArrayRef all = ABAddressBookCopyArrayOfAllPeople(addressBookRef);
            CFIndex n = ABAddressBookGetPersonCount(addressBookRef);
            
            CFMutableArrayRef peopleMutable = CFArrayCreateMutableCopy(
                                                                       kCFAllocatorDefault,
                                                                       CFArrayGetCount(all),
                                                                       all
                                                                       );
            
            CFArraySortValues(
                              peopleMutable,
                              CFRangeMake(0, n),
                              (CFComparatorFunction) ABPersonComparePeopleByName,
                              (void*) ABPersonGetSortOrdering()
                              );
            NSMutableArray* data = [NSMutableArray arrayWithArray: (__bridge NSArray*) peopleMutable];
            
            
            for( int i = 0 ; i < n ; i++ )
            {
                ABRecordRef ref = (__bridge ABRecordRef)([data objectAtIndex:i]);
                NSString *firstName = StringOrEmpty((__bridge NSString *)ABRecordCopyValue(ref, kABPersonFirstNameProperty));
                NSString *lastName =  StringOrEmpty((__bridge NSString *)ABRecordCopyValue(ref, kABPersonLastNameProperty));
                ABMultiValueRef phones = ABRecordCopyValue(ref, kABPersonPhoneProperty);
                if ( ABMultiValueGetCount(phones) > 0 &&
                    (![firstName isEqualToString:@""] || ![lastName isEqualToString:@""]) ) {
                    [mutableMobileArray addObject:(__bridge id)(ref)];
                }
            }
            mobileArray([NSArray arrayWithArray:mutableMobileArray]);
        }
        else {
            
            [EventAnalytics tagEvent:@"Decline Apple Contacts"];
            mobileArray([NSArray new]);
        }
    });

}

@end
