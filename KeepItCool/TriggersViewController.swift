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
    private var connectedUntappd: Bool = false
    private var connectedSwarm: Bool = false
    
    private var untappdToken: String = ""
    
    private let UNTAPPD_CLIENT_ID: String = "ED87E42E18D62956176090E9F84F3539EF16B315"
    private let UNTAPPD_REDIRECT_URL: String = "https://kasra-subzero.herokuapp.com/untappd_callback"
    
    @IBOutlet weak var untappdButton: UIButton!
    @IBOutlet weak var swarmButton: UIButton!
    
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
        if (connectedUntappd) {
            untappdToken = ""
            connectedUntappd = false
            self.untappdButton.setTitle("Connect to Untappd", forState: UIControlState.Normal)
            
            print("Disconnect Untappd")
        } else {
            var url = "https://untappd.com/oauth/authenticate/?"
            url += "client_id=\(UNTAPPD_CLIENT_ID)&response_type=code&redirect_url=\(UNTAPPD_REDIRECT_URL)"
            
            UIApplication.sharedApplication().openURL(NSURL(string: url)!)
        }
    }
    
    @IBAction func swarmHit(sender: UIButton) {
        print("Toggle Swarm")
    }
    
    @IBAction func doneButtonHit(sender: UIButton) {
        saveUserSettings()
    }
    
    private func saveUserSettings() {
        SubZeroClient.saveSettings(UIDevice.currentDevice().identifierForVendor!.UUIDString, useUntappd: connectedUntappd, useSwarm: connectedSwarm)
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
        }
    }
    
    func untappdConnected(token: String) {
        untappdToken = token;
        connectedUntappd = true;
        self.untappdButton.setTitle("Connected to Untappd", forState: UIControlState.Normal)
        
        SubZeroClient.setUntappdToken(UIDevice.currentDevice().identifierForVendor!.UUIDString, untappdToken: untappdToken)
            .responseString { request, response, data in
                if (response?.statusCode == 200) {
                    print("Untappd token saved")
                }
                else {
                    print(data);
                    let alert = UIAlertView(title: "Unable to save Untappd access", message: response?.description,
                        delegate: nil, cancelButtonTitle: "OK")
                    alert.show()
                    
                    self.untappdToken = "";
                    self.connectedUntappd = false;
                    self.untappdButton.setTitle("Connect to Untappd", forState: UIControlState.Normal)
                }
        }
    }

}
