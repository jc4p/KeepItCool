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
        
        for record in protectedIds! {
            let contact = addressBook.getContactByRecordID(record)
            print("Need to encrypt " + contact.firstName + " " + contact.lastName)
        }
    }
    
    static func encryptContact(crypto: Crypto, contact: APContact) {
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
        print("Changed number? \(success)")
        success = ABRecordSetValue(abRecord, kABPersonNoteProperty, note, &err)
        print("Set note? \(success)")
        success = ABAddressBookSave(abBook, &err)
        print("Saving addressbook successful? \(success)")
    }
    
    static func decryptContact(crypto: Crypto, contact: APContact) {
        let note = contact.note;
        
        let ourRange = Range(start: advance(note.rangeOfString("\n;ORIG:")!.startIndex, 7), end: note.endIndex)
        
        let numberEncryptedAndHexed = note.substringWithRange(ourRange)
        
        let oldNote = note.substringToIndex(advance(ourRange.startIndex, -7))
        
        let phoneNumber = crypto.decryptString(numberEncryptedAndHexed)
        
        var err : Unmanaged<CFError>? = nil
        let abBook: ABAddressBook = ABAddressBookCreateWithOptions(nil, &err).takeRetainedValue()
        
        let abRecord: ABRecord = ABAddressBookGetPersonWithRecordID(abBook, contact.recordID.intValue).takeUnretainedValue()
        
        let phoneMultiValueRef: ABMutableMultiValueRef = getPhonesMultiValueRef(abRecord)
        ABMultiValueReplaceValueAtIndex(phoneMultiValueRef, phoneNumber, 0 as CFIndex)
        var success = ABRecordSetValue(abRecord, kABPersonPhoneProperty, phoneMultiValueRef, &err);
        print("Changed number? \(success)", appendNewline: false)
        success = ABRecordSetValue(abRecord, kABPersonNoteProperty, oldNote, &err)
        print("Reset note? \(success)", appendNewline: false)
        success = ABAddressBookSave(abBook, &err)
        print("Saving addressbook successful? \(success)", appendNewline: false)
    }
    
    static func getPhonesMultiValueRef(person: ABRecordRef) -> ABMutableMultiValueRef {
        let phoneMultiValueRef: ABMultiValueRef = Unmanaged.fromOpaque(ABRecordCopyValue(person, kABPersonPhoneProperty).toOpaque()).takeUnretainedValue() as NSObject as ABMultiValueRef
        return ABMultiValueCreateMutableCopy(phoneMultiValueRef).takeUnretainedValue()
    }
}