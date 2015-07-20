//
//  TriggersViewController.swift
//  KeepItCool
//
//  Created by Kasra Rahjerdi on 7/19/15.
//  Copyright © 2015 Kasra Rahjerdi. All rights reserved.
//

import Foundation
import UIKit

class TriggersViewController: UIViewController {
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup();
    }
    
    private func setup() {
        
    }
    
    @IBAction func untappdHit(sender: UIButton) {
        print("Toggle Untappd")
    }
    
    @IBAction func swarmHit(sender: UIButton) {
        print("Toggle Swarm")
    }
    
    @IBAction func doneButtonHit(sender: UIButton) {
        registerUser()
    }
    
    private func registerUser() {
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        SubZeroClient.register(UIDevice.currentDevice().identifierForVendor!.UUIDString, deviceToken: delegate.deviceToken)
            .response { request, response, data, error in
                if (error == nil) {
                    let defaults = NSUserDefaults.standardUserDefaults()
                    defaults.setBool(true, forKey: "registered")
                    self.performSegueWithIdentifier("triggersMainSegue", sender: self)
                }
                else {
                    print(error);
                    let alert = UIAlertView(title: "Error", message: error?.localizedDescription,
                        delegate: nil, cancelButtonTitle: "OK")
                    alert.show()
                    
                }
        };
    }

}
