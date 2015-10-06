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

class MainViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, ABPeoplePickerNavigationControllerDelegate {
    private let reuseIdentifier: String = "mainContactsCell"
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var countLabel: UILabel!
    
    private var addressBook = APAddressBook()
    private var contacts = [APContact]()
    private var crypto: Crypto!;
    
    private var protectedRecordIds: [NSNumber] = [];
    private var lockedRecordIds: [NSNumber] = [];
        
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("contactCell") as! KRContactViewCell
        
        if (indexPath.indexAtPosition(1) % 2 == 0) {
            cell.contentView.backgroundColor = UIColor(red:0.40, green:0.73, blue:0.42, alpha:1.0)
        } else {
            cell.contentView.backgroundColor = UIColor(red:0.93, green:0.25, blue:0.48, alpha:1.0)
        }
        
        let contact = contacts[indexPath.indexAtPosition(1)]
        
        if (lockedRecordIds.contains(contact.recordID)) {
            cell.iconView.hidden = false
        } else {
            cell.iconView.hidden = true
        }
        
        cell.nameLabel.text = contact.compositeName
        
        return cell
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        // nothin
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let contact = self.contacts[indexPath.indexAtPosition(1)]
        
        if (lockedRecordIds.contains(contact.recordID)) {
            let unlockAction = UITableViewRowAction(style: .Normal, title: "Unlock", handler: { (_, path: NSIndexPath) -> Void
                in
                self.unlockContactAtIndex(path)
            });
            
            return [unlockAction]
        }
        
        let deleteAction = UITableViewRowAction(style: .Destructive, title: "Remove", handler: { (_, path: NSIndexPath) -> Void in
            self.removeContactAtIndex(path)
        });
        
        return [deleteAction]
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
    
    func reloadData() {
        self.tableView.reloadData()
        let lockedIds = NSUserDefaults.standardUserDefaults().arrayForKey("locked") as? [NSNumber]
        if (lockedIds != nil) {
            self.lockedRecordIds = lockedIds!
        } else {
            self.lockedRecordIds = [NSNumber]()
        }
    }

    private func setup() {
        let adHash = ASIdentifierManager.sharedManager().advertisingIdentifier.UUIDString.md5()
        crypto = Crypto(hash: adHash!)
        
        tableView.backgroundColor = UIColor.clearColor()
        tableView.separatorStyle = .None
        tableView.tableFooterView = UIView(frame: CGRectZero)
        
        openAddressBook()
        let protectedIds = NSUserDefaults.standardUserDefaults().arrayForKey("protected") as? [NSNumber]
        if (protectedIds != nil) {
            self.protectedRecordIds = protectedIds!
        }
        
        let lockedIds = NSUserDefaults.standardUserDefaults().arrayForKey("locked") as? [NSNumber]
        if (lockedIds != nil) {
            self.lockedRecordIds = lockedIds!
        } else {
            self.lockedRecordIds = [NSNumber]()
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
        // Double loop to perserve ordering of contacts
        for recordId in protectedRecordIds {
            for contact in data {
                if (recordId == contact.recordID) {
                    self.contacts.append(contact)
                    addedCount += 1
                    break;
                }
            }
        }
        updateCountLabel()
        
        let insertedIndexPathRange = 0..<addedCount
        let insertedIndexPaths = insertedIndexPathRange.map { NSIndexPath(forRow: $0, inSection: 0) }
        tableView.insertRowsAtIndexPaths(insertedIndexPaths, withRowAnimation: .Automatic)
    }
    
    private func updateCountLabel() {
        countLabel.text =  "\(contacts.count) protected contacts"
    }
    
    private func appendContact(contact: APContact) {
        protectedRecordIds.append(contact.recordID)
        NSUserDefaults.standardUserDefaults().setValue(protectedRecordIds, forKey: "protected")
        
        self.contacts.append(contact)
        updateCountLabel()
        tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: self.contacts.count - 1, inSection: 0)], withRowAnimation: .Automatic)
    }
    
    @IBAction func addContactPressed(sender: UIButton) {
        let picker = ABPeoplePickerNavigationController()
        picker.peoplePickerDelegate = self
        
        if picker.respondsToSelector(Selector("predicateForEnablingPerson")) {
            picker.predicateForEnablingPerson = NSPredicate(format: "\(ABPersonPhoneNumbersProperty).@count > 0")
        }
        
        presentViewController(picker, animated: true, completion: nil)
    }
    
    func unlockContactAtIndex(indexPath: NSIndexPath) {
        let contact = contacts[indexPath.indexAtPosition(1)]
        
        if (ContactTransformer.decryptContact(crypto, contact: contact)) {
            lockedRecordIds.removeAtIndex(lockedRecordIds.indexOf(contact.recordID)!)
            NSUserDefaults.standardUserDefaults().setValue(lockedRecordIds, forKey: "locked")
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        } else {
            print("Unable to decrypt " + contact.compositeName)
        }
    }
    
    func removeContactAtIndex(indexPath: NSIndexPath) {
        let contact = contacts[indexPath.indexAtPosition(1)]
        protectedRecordIds.removeAtIndex(protectedRecordIds.indexOf(contact.recordID)!)
        NSUserDefaults.standardUserDefaults().setValue(protectedRecordIds, forKey: "protected")

        self.contacts.removeAtIndex(indexPath.indexAtPosition((1)))
        updateCountLabel()
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
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

