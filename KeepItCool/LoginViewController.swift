//
//  LoginViewController.swift
//  KeepItCool
//
//  Created by Kasra Rahjerdi on 7/18/15.
//  Copyright © 2015 Kasra Rahjerdi. All rights reserved.
//

import Foundation
import UIKit
import APAddressBook

class LoginViewController: UIViewController {
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let defaults = NSUserDefaults.standardUserDefaults()
        if (defaults.boolForKey("registered")) {
            self.performSegueWithIdentifier("loginMainSegue", sender: self)
        }
    }
    
    @IBAction func getStartedButtonPressed(sender: UIButton) {
        let addressBook = APAddressBook()
        
        addressBook.loadContacts(
            { (apContacts: [AnyObject]!, error: NSError!) in
                if (apContacts != nil) {
                    self.performSegueWithIdentifier("loginTriggersSegue", sender: sender)
                }
                else if (error != nil) {
                    let alert = UIAlertView(title: "Error", message: error.localizedDescription,
                        delegate: nil, cancelButtonTitle: "OK")
                    alert.show()
                }
        })
    }
}
