//
//  ViewController.swift
//  KeepItCool
//
//  Created by Kasra Rahjerdi on 5/30/15.
//  Copyright (c) 2015 Kasra Rahjerdi. All rights reserved.
//

import UIKit
import AddressBookUI
import APAddressBook
import CryptoSwift

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, ABPeoplePickerNavigationControllerDelegate {
    private let reuseIdentifier: String = "mainContactsCell"
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var countLabel: UILabel!
    
    private var addressBook = APAddressBook()
    private var contacts = [APContact]()
        
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.registerNib(UINib(nibName: "KRCollectionViewItem", bundle: nil), forCellWithReuseIdentifier: reuseIdentifier)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return contacts.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath:indexPath) as! KRCollectionViewItem
        
        cell.setText(contacts[indexPath.indexAtPosition(1)].compositeName)
        
        return cell
    }
    
    private func openAddressBook() {
        addressBook = APAddressBook()
        addressBook.fieldsMask = APContactField.Default | APContactField.RecordID | APContactField.CompositeName | APContactField.Note
        addressBook.sortDescriptors = [NSSortDescriptor(key: "firstName", ascending: true),
            NSSortDescriptor(key: "lastName", ascending: true)]
        
        addressBook.filterBlock = {(contact: APContact!) -> Bool in
            contact.note != nil && contact.note.rangeOfString("ORIG") != nil
        }
    }

    private func setup() {
        openAddressBook()
        
        addressBook.loadContacts(
            { (apContacts: [AnyObject]!, error: NSError!) in
                if (apContacts != nil) {
                    self.onDataLoaded(apContacts as! [APContact])
                }
                else if (error != nil) {
                    let alert = UIAlertView(title: "Error", message: error.localizedDescription,
                        delegate: nil, cancelButtonTitle: "OK")
                    alert.show()
                }
        })
    }
    
    private func onDataLoaded(data: [APContact]) {
        self.contacts.extend(data)
        updateCountLabel()
        
        let insertedIndexPathRange = 0..<data.count
        var insertedIndexPaths = insertedIndexPathRange.map { NSIndexPath(forRow: $0, inSection: 0) }
        collectionView.performBatchUpdates({self.collectionView.insertItemsAtIndexPaths(insertedIndexPaths)}, completion: nil)
    }
    
    private func updateCountLabel() {
        countLabel.text =  "\(contacts.count) protected contacts"
    }
    
    private func appendContact(contact: APContact) {
        scrambleContact(contact)
        openAddressBook()
        var modifiedContact = addressBook.getContactByRecordID(contact.recordID)
        self.contacts.append(modifiedContact)
        updateCountLabel()
        self.collectionView.insertItemsAtIndexPaths([NSIndexPath(forRow: self.contacts.count - 1, inSection: 0)])
    }
    
    private func scrambleContact(contact: APContact) {
        var phoneNumber = contact.phones[0] as! String
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
        
        note += Crypto.encryptString(phoneNumber).stringByReplacingOccurrencesOfString(" ", withString: "")
        
        var err : Unmanaged<CFError>? = nil
        var abBook: ABAddressBook = ABAddressBookCreateWithOptions(nil, &err).takeRetainedValue()
        
        var abRecord: ABRecord = ABAddressBookGetPersonWithRecordID(abBook, contact.recordID.intValue).takeUnretainedValue()
        
        let phoneMultiValueRef: ABMutableMultiValueRef = getPhonesMultiValueRef(abRecord)
        ABMultiValueReplaceValueAtIndex(phoneMultiValueRef, "443-203-4242", 0 as CFIndex)
        var success = ABRecordSetValue(abRecord, kABPersonPhoneProperty, phoneMultiValueRef, &err);
        println("Changed number? \(success)")
        success = ABRecordSetValue(abRecord, kABPersonNoteProperty, note, &err)
        println("Set note? \(success)")
        success = ABAddressBookSave(abBook, &err)
        println("Saving addressbook successful? \(success)")
    }
    
    private func unscrambleContact(contact: APContact) {
        let note = contact.note;
        
        let ourRange = Range(start: advance(note.rangeOfString("\n;ORIG:")!.startIndex, 7), end: note.endIndex)
        
        let numberEncryptedAndHexed = note.substringWithRange(ourRange)
        
        var oldNote = note.substringToIndex(advance(ourRange.startIndex, -7))
        
        let phoneNumber = Crypto.decryptString(numberEncryptedAndHexed)
        
        var err : Unmanaged<CFError>? = nil
        var abBook: ABAddressBook = ABAddressBookCreateWithOptions(nil, &err).takeRetainedValue()
        
        var abRecord: ABRecord = ABAddressBookGetPersonWithRecordID(abBook, contact.recordID.intValue).takeUnretainedValue()
        
        let phoneMultiValueRef: ABMutableMultiValueRef = getPhonesMultiValueRef(abRecord)
        ABMultiValueReplaceValueAtIndex(phoneMultiValueRef, phoneNumber, 0 as CFIndex)
        var success = ABRecordSetValue(abRecord, kABPersonPhoneProperty, phoneMultiValueRef, &err);
        println("Changed number? \(success)")
        success = ABRecordSetValue(abRecord, kABPersonNoteProperty, oldNote, &err)
        println("Reset note? \(success)")
        success = ABAddressBookSave(abBook, &err)
        println("Saving addressbook successful? \(success)")

    }

    @IBAction func addContactPressed(sender: UIButton) {
        let picker = ABPeoplePickerNavigationController()
        picker.peoplePickerDelegate = self
        
        if picker.respondsToSelector(Selector("predicateForEnablingPerson")) {
            picker.predicateForEnablingPerson = NSPredicate(format: "\(ABPersonPhoneNumbersProperty).@count > 0")
        }
        
        presentViewController(picker, animated: true, completion: nil)
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        var contact = contacts[indexPath.indexAtPosition(1)]
        unscrambleContact(contact)
        
        openAddressBook()
        var modifiedContact = addressBook.getContactByRecordID(contact.recordID)
        self.contacts.removeAtIndex(indexPath.indexAtPosition((1)))
        updateCountLabel()
        self.collectionView.deleteItemsAtIndexPaths([indexPath])
    }
    
    func peoplePickerNavigationController(peoplePicker: ABPeoplePickerNavigationController!, didSelectPerson person: ABRecordRef!) {
        appendContact(self.addressBook.getContactByRecordID(NSNumber(int: ABRecordGetRecordID(person))))
    }
    
    func peoplePickerNavigationController(peoplePicker: ABPeoplePickerNavigationController!, shouldContinueAfterSelectingPerson person: ABRecordRef!) -> Bool {
        
        peoplePickerNavigationController(peoplePicker, didSelectPerson: person)
        
        peoplePicker.dismissViewControllerAnimated(true, completion: nil)
        
        return false;
    }

    func peoplePickerNavigationControllerDidCancel(peoplePicker: ABPeoplePickerNavigationController!) {
        peoplePicker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func getPhonesMultiValueRef(person: ABRecordRef) -> ABMutableMultiValueRef {
        let phoneMultiValueRef: ABMultiValueRef = Unmanaged.fromOpaque(ABRecordCopyValue(person, kABPersonPhoneProperty).toOpaque()).takeUnretainedValue() as NSObject as ABMultiValueRef
        return ABMultiValueCreateMutableCopy(phoneMultiValueRef).takeUnretainedValue()
    }
}

