//
//  MainViewController.swift
//  KeepItCool
//
//  Created by Kasra Rahjerdi on 5/30/15.
//  Copyright (c) 2015 Kasra Rahjerdi. All rights reserved.
//

import UIKit
import AddressBookUI
import AdSupport
import APAddressBook
import CryptoSwift

class MainViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, ABPeoplePickerNavigationControllerDelegate {
    private let reuseIdentifier: String = "mainContactsCell"
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var countLabel: UILabel!
    
    private var addressBook = APAddressBook()
    private var contacts = [APContact]()
    private var crypto: Crypto!;
    
    private var protectedRecordIds: [NSNumber] = [];
        
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
        addressBook.fieldsMask = [APContactField.Default, APContactField.RecordID, APContactField.CompositeName, APContactField.Note]
        addressBook.sortDescriptors = [NSSortDescriptor(key: "firstName", ascending: true),
            NSSortDescriptor(key: "lastName", ascending: true)]
        
//        addressBook.filterBlock = {(contact: APContact!) -> Bool in
//            contact.note != nil && contact.note.rangeOfString("ORIG") != nil
//        }
    }

    private func setup() {
        let adHash = ASIdentifierManager.sharedManager().advertisingIdentifier.UUIDString.md5()
        crypto = Crypto(hash: adHash!)
            
        openAddressBook()
        let protectedIds = NSUserDefaults.standardUserDefaults().arrayForKey("protected") as? [NSNumber]
        if (protectedIds != nil) {
            self.protectedRecordIds = protectedIds!
        }
        addressBook.loadContacts(
            { (apContacts: [AnyObject]!, error: NSError!) in
                if (apContacts != nil) {
                    self.onDataLoaded(apContacts as! [APContact])
                }
                else if (error != nil) {
                    let alert = UIAlertView(title: "Error loading contacts", message: error.localizedDescription,
                        delegate: nil, cancelButtonTitle: "OK")
                    alert.show()
                }
        })
    }
    
    private func onDataLoaded(data: [APContact]) {
        var addedCount = 0
        for contact in data {
            if (protectedRecordIds.contains(contact.recordID)) {
                self.contacts.append(contact);
                addedCount += 1
            }
        }
        updateCountLabel()
        
        let insertedIndexPathRange = 0..<addedCount
        let insertedIndexPaths = insertedIndexPathRange.map { NSIndexPath(forRow: $0, inSection: 0) }
        collectionView.performBatchUpdates({self.collectionView.insertItemsAtIndexPaths(insertedIndexPaths)}, completion: nil)
    }
    
    private func updateCountLabel() {
        countLabel.text =  "\(contacts.count) protected contacts"
    }
    
    private func appendContact(contact: APContact) {
        protectedRecordIds.append(contact.recordID)
        NSUserDefaults.standardUserDefaults().setValue(protectedRecordIds, forKey: "protected")
        
        self.contacts.append(contact)
        updateCountLabel()
        self.collectionView.insertItemsAtIndexPaths([NSIndexPath(forRow: self.contacts.count - 1, inSection: 0)])
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
        let contact = contacts[indexPath.indexAtPosition(1)]
        protectedRecordIds.removeAtIndex(protectedRecordIds.indexOf(contact.recordID)!)
        NSUserDefaults.standardUserDefaults().setValue(protectedRecordIds, forKey: "protected")
        
        self.contacts.removeAtIndex(indexPath.indexAtPosition((1)))
        updateCountLabel()
        self.collectionView.deleteItemsAtIndexPaths([indexPath])
    }
    
    func peoplePickerNavigationController(peoplePicker: ABPeoplePickerNavigationController, didSelectPerson person: ABRecordRef) {
        appendContact(self.addressBook.getContactByRecordID(NSNumber(int: ABRecordGetRecordID(person))))
    }
    
    func peoplePickerNavigationController(peoplePicker: ABPeoplePickerNavigationController, shouldContinueAfterSelectingPerson person: ABRecordRef) -> Bool {
        
        peoplePickerNavigationController(peoplePicker, didSelectPerson: person)
        
        peoplePicker.dismissViewControllerAnimated(true, completion: nil)
        
        return false;
    }

    func peoplePickerNavigationControllerDidCancel(peoplePicker: ABPeoplePickerNavigationController) {
        peoplePicker.dismissViewControllerAnimated(true, completion: nil)
    }    
}

