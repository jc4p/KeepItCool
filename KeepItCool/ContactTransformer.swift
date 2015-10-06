//
//  ContactTransformer.swift
//  KeepItCool
//
//  Created by Kasra Rahjerdi on 7/20/15.
//  Copyright © 2015 Kasra Rahjerdi. All rights reserved.
//

import Foundation
import APAddressBook

class ContactTransformer {
    private static let ICECOLD_NUMBER = "443-203-4242"
    
    static func encryptAll(crypto: Crypto) {
        let protectedIds = NSUserDefaults.standardUserDefaults().arrayForKey("protected") as? [NSNumber]
        if (protectedIds == nil) {
            print("No one to encrypt")
            return
        }
        
        let addressBook = APAddressBook()
        addressBook.fieldsMask = [APContactField.Default, APContactField.RecordID, APContactField.CompositeName, APContactField.Note]
        
        var lockedIds = NSUserDefaults.standardUserDefaults().arrayForKey("locked") as? [NSNumber]
        if (lockedIds == nil) {
            lockedIds = [NSNumber]();
        }

        for record in protectedIds! {
            if lockedIds!.contains(record) {
                continue
            }
            
            let contact = addressBook.getContactByRecordID(record)
            print("Encrypting " + contact.firstName + " " + contact.lastName)
            let success = encryptContact(crypto, contact: contact)
            if (success) {
                lockedIds!.append(record);
            }
        }
        
        NSUserDefaults.standardUserDefaults().setValue(lockedIds!, forKey: "locked");
        
        
    }
    
    static func encryptContact(crypto: Crypto, contact: APContact) -> Bool {
        let phoneNumber = contact.phones[0] as! String
        var originalNote = contact.note
        var note = ""
        
        if (originalNote != nil && !originalNote.isEmpty) {
            let ourRange = originalNote.rangeOfString("\n;ORIG:")
            if (ourRange != nil) {
                // Shouldn't happen outside of testing
                originalNote.removeRange(ourRange!)
            }
            note = originalNote
        }
        note += "\n;ORIG:"
        
        note += crypto.encryptString(phoneNumber).stringByReplacingOccurrencesOfString(" ", withString: "")
        
        var err : Unmanaged<CFError>? = nil
        let abBook: ABAddressBook = ABAddressBookCreateWithOptions(nil, &err).takeRetainedValue()
        
        let abRecord: ABRecord = ABAddressBookGetPersonWithRecordID(abBook, contact.recordID.intValue).takeUnretainedValue()
        
        let phoneMultiValueRef: ABMutableMultiValueRef = getPhonesMultiValueRef(abRecord)
        ABMultiValueReplaceValueAtIndex(phoneMultiValueRef, ICECOLD_NUMBER, 0 as CFIndex)
        var success = ABRecordSetValue(abRecord, kABPersonPhoneProperty, phoneMultiValueRef, &err);
        success = ABRecordSetValue(abRecord, kABPersonNoteProperty, note, &err)
        success = ABAddressBookSave(abBook, &err)
        
        return success;
    }
    
    static func decryptContact(crypto: Crypto, contact: APContact) -> Bool {
        let note = contact.note;
        
        let ourRange = Range(start: note.rangeOfString("\n;ORIG:")!.startIndex.advancedBy(7), end: note.endIndex)
        
        let numberEncryptedAndHexed = note.substringWithRange(ourRange)
        
        let oldNote = note.substringToIndex(ourRange.startIndex.advancedBy(-7))
        
        let phoneNumber = crypto.decryptString(numberEncryptedAndHexed)
        
        var err : Unmanaged<CFError>? = nil
        let abBook: ABAddressBook = ABAddressBookCreateWithOptions(nil, &err).takeRetainedValue()
        
        let abRecord: ABRecord = ABAddressBookGetPersonWithRecordID(abBook, contact.recordID.intValue).takeUnretainedValue()
        
        let phoneMultiValueRef: ABMutableMultiValueRef = getPhonesMultiValueRef(abRecord)
        ABMultiValueReplaceValueAtIndex(phoneMultiValueRef, phoneNumber, 0 as CFIndex)
        var success = ABRecordSetValue(abRecord, kABPersonPhoneProperty, phoneMultiValueRef, &err);
        success = ABRecordSetValue(abRecord, kABPersonNoteProperty, oldNote, &err)
        success = ABAddressBookSave(abBook, &err)
        return success
    }
    
    static func getPhonesMultiValueRef(person: ABRecordRef) -> ABMutableMultiValueRef {
        let phoneMultiValueRef: ABMultiValueRef = Unmanaged.fromOpaque(ABRecordCopyValue(person, kABPersonPhoneProperty).toOpaque()).takeUnretainedValue() as NSObject as ABMultiValueRef
        return ABMultiValueCreateMutableCopy(phoneMultiValueRef).takeUnretainedValue()
    }
}