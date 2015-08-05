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
        sender.enabled = false;
        let addressBook = APAddressBook()
        
        addressBook.loadContacts(
            { (apContacts: [AnyObject]!, error: NSError!) in
                if (apContacts != nil) {
                    let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
                    
                    SubZeroClient.register(UIDevice.currentDevice().identifierForVendor!.UUIDString, deviceToken: delegate.deviceToken)
                        .responseString { request, response, data in
                            if (response?.statusCode == 200) {
                                self.performSegueWithIdentifier("loginTriggersSegue", sender: self)
                            }
                            else {
                                print("Unable to register APN device token:")
                                print(data);
                                let alert = UIAlertView(title: "Error", message: response?.description,
                                    delegate: nil, cancelButtonTitle: "OK")
                                alert.show()
                            }
                    }
                }
                else if (error != nil) {
                    let alert = UIAlertView(title: "Error", message: error.localizedDescription,
                        delegate: nil, cancelButtonTitle: "OK")
                    alert.show()
                }
        })
    }
}
