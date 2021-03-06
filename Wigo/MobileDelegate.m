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

+ (NSArray *)mobileKeys {
    return @[@"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M", @"N", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z"];
}

+ (void)getSeparatedMobileContacts:(MobileDictionary)mobileDict {
    [MobileDelegate getMobileContacts:^(NSArray *mobileArray) {
        NSMutableDictionary *mutDict =  [NSMutableDictionary new];
        NSArray *keys = [MobileDelegate mobileKeys];
        for (NSString *key in keys) {
            [mutDict setObject:[NSMutableArray new] forKey:key];
        }
        for (int i = 0; i < mobileArray.count; i++) {
            ABRecordRef contactPerson;
            contactPerson = (__bridge ABRecordRef)([mobileArray objectAtIndex:i]);
            NSString *firstName = StringOrEmpty((__bridge NSString *)ABRecordCopyValue(contactPerson, kABPersonFirstNameProperty));
            NSString *lastName =  StringOrEmpty((__bridge NSString *)ABRecordCopyValue(contactPerson, kABPersonLastNameProperty));
            if (lastName.length == 0) {
                NSString *charStr = [firstName substringWithRange:NSMakeRange(0, 1)].capitalizedString;
                NSMutableArray *mutArray = [mutDict objectForKey:charStr];
                [mutArray addObject:(__bridge id)(contactPerson)];
            }
            else {
                NSString *charStr = [lastName substringWithRange:NSMakeRange(0, 1)].capitalizedString;
                NSMutableArray *mutArray = [mutDict objectForKey:charStr];
                [mutArray addObject:(__bridge id)(contactPerson)];
            }
        }
        mobileDict(mutDict);
    }];
}

+ (void) getMobileContacts:(MobileArray)mobileArray {
    CFErrorRef error = NULL;
    NSMutableArray *mutableMobileArray = [NSMutableArray new];
    
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, &error);
    ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error) {
        if (granted && addressBookRef) {
            
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
                              (void *)(unsigned long)ABPersonGetSortOrdering()
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
        } else {
            
            mobileArray([NSArray new]);
        }
    });
}

+ (void)sendChosenPeople:(NSArray *)chosenPeople forContactList:(NSArray *)peopleContactList {
    NSMutableArray *numbers = [[NSMutableArray alloc] init];
    for (CFIndex i = 0; i < [chosenPeople count]; i++) {
        NSString *recordIDString = [chosenPeople objectAtIndex:i];
        for (int j = 0; j < [peopleContactList count]; j++) {
            ABRecordRef contactPerson = (__bridge ABRecordRef)([peopleContactList objectAtIndex:j]);
            ABRecordID newRecordID = ABRecordGetRecordID(contactPerson);
            NSString *newRecordIDString = [NSString stringWithFormat:@"%d",newRecordID];
            if ([recordIDString isEqualToString:newRecordIDString]) {
                ABMultiValueRef multiPhones = ABRecordCopyValue(contactPerson, kABPersonPhoneProperty);
                for(CFIndex i = 0; i < ABMultiValueGetCount(multiPhones); i++) {
                    
                    NSString* phoneLabel = (__bridge NSString*) ABMultiValueCopyLabelAtIndex(multiPhones, i);
                    NSString* phoneNumber = (__bridge NSString*) ABMultiValueCopyValueAtIndex(multiPhones, i);
                    //for example
                    if([phoneLabel isEqualToString:(NSString *)kABPersonPhoneIPhoneLabel]) {
                        [numbers addObject:@{@"phone":phoneNumber}];
                        break;
                    }
                    else if (([phoneLabel isEqualToString:(NSString *)kABPersonPhoneMobileLabel])) {
                        [numbers addObject:@{@"phone":phoneNumber}];
                        break;
                    }
                    else if (([phoneLabel isEqualToString:(NSString *)kABPersonPhoneMainLabel])) {
                        [numbers addObject:@{@"phone":phoneNumber}];
                        break;
                    }
                    else {
                        [numbers addObject:@{@"phone":phoneNumber}];
                        break;
                    }
                }
                ABMutableMultiValueRef multi = ABRecordCopyValue(contactPerson, kABPersonEmailProperty);
                if (ABMultiValueGetCount(multi) > 0) {
                    CFStringRef emailRef = ABMultiValueCopyValueAtIndex(multi, 0);
                    NSMutableDictionary *newNumber = [NSMutableDictionary dictionaryWithDictionary:[numbers lastObject]];
                    [newNumber addEntriesFromDictionary:@{@"email": (__bridge NSString *)emailRef}];
                    unsigned long lastIndex = numbers.count - 1;
                    [numbers replaceObjectAtIndex:lastIndex withObject:[NSDictionary dictionaryWithDictionary:newNumber]];
                }
            }
        }
    }
    if ([numbers count] > 0) {
        [[WGProfile currentUser] sendInvites:numbers withHandler:^(BOOL success, NSError *error) {
            if (error) {
                [[WGError sharedInstance] logError:error forAction:WGActionPost];
            }
        }];
    }
}

+ (int)changeTag:(int)tag fromArray:(NSArray *)partArray toArray:(NSArray *)totalArray {
    ABRecordRef contactPerson = (__bridge ABRecordRef)([partArray objectAtIndex:tag]);
    ABRecordID recordID = ABRecordGetRecordID(contactPerson);
    int newTag = 0;
    for (int i = 0 ; i < [totalArray count] ; i++ ) {
        ABRecordRef newContactPerson = (__bridge ABRecordRef)([totalArray objectAtIndex:i]);
        ABRecordID newRecordID = ABRecordGetRecordID(newContactPerson);
        if (recordID == newRecordID) {
            newTag = i;
        }
    }
    return newTag;
}

+ (NSArray *)filterArray:(NSArray *)array withText:(NSString *)searchText {
    NSMutableArray *filteredPeopleContactList = [[NSMutableArray alloc] init];
    
    NSArray *searchArray = [searchText componentsSeparatedByString:@" "];
    if ([searchArray count] > 1 && [searchArray[1] length] > 0) {
        for (int i = 0 ; i < [array count]; i++) {
            ABRecordRef contactPerson = (__bridge ABRecordRef)([array objectAtIndex:i]);
            NSString *firstName = StringOrEmpty((__bridge NSString *)ABRecordCopyValue(contactPerson, kABPersonFirstNameProperty));
            NSString *lastName =  StringOrEmpty((__bridge NSString *)ABRecordCopyValue(contactPerson, kABPersonLastNameProperty));
            
            NSRange nameRange = [firstName rangeOfString:searchArray[0] options:NSCaseInsensitiveSearch];
            NSRange descriptionRange = [lastName rangeOfString:searchArray[1] options:NSCaseInsensitiveSearch];
            if(nameRange.location != NSNotFound && descriptionRange.location != NSNotFound)
            {
                [filteredPeopleContactList addObject:(__bridge id)(contactPerson)];
            }
        }
    } else {
        for (int i = 0 ; i < [array count]; i++) {
            ABRecordRef contactPerson = (__bridge ABRecordRef)([array objectAtIndex:i]);
            NSString *firstName = StringOrEmpty((__bridge NSString *)ABRecordCopyValue(contactPerson, kABPersonFirstNameProperty));
            NSString *lastName =  StringOrEmpty((__bridge NSString *)ABRecordCopyValue(contactPerson, kABPersonLastNameProperty));
            
            NSRange nameRange = [firstName rangeOfString:searchText options:NSCaseInsensitiveSearch];
            NSRange descriptionRange = [lastName rangeOfString:searchText options:NSCaseInsensitiveSearch];
            if(nameRange.location != NSNotFound || descriptionRange.location != NSNotFound)
            {
                [filteredPeopleContactList addObject:(__bridge id)(contactPerson)];
            }
        }
    }
    return [NSArray arrayWithArray:filteredPeopleContactList];
}

@end
