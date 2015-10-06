//
//  AppDelegate.swift
//  KeepItCool
//
//  Created by Kasra Rahjerdi on 5/30/15.
//  Copyright (c) 2015 Kasra Rahjerdi. All rights reserved.
//

import UIKit
import AdSupport

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var deviceToken: String = "";

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        application.setStatusBarStyle(UIStatusBarStyle.LightContent, animated: false)
        
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.

        application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: UIUserNotificationType.None, categories: nil))
        application.registerForRemoteNotifications()
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        self.deviceToken = deviceToken.description
            .stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "<>"))
            .stringByReplacingOccurrencesOfString(" ", withString: "")
        print("Registered device token: " + self.deviceToken)
    }

    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print("Couldn't register: \(error)")
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler handler: (UIBackgroundFetchResult) -> Void) {
        print("Received remote notification: " + userInfo.description)
        
        let shouldQuarantine = (userInfo["quarantine"] != nil)
        if (shouldQuarantine) {
            let adHash = ASIdentifierManager.sharedManager().advertisingIdentifier.UUIDString.md5()
            ContactTransformer.encryptAll(Crypto(hash: adHash!))
        }
        
        let navController = window?.rootViewController as? MainNavigationViewController
        if (navController != nil) {
            let mainController = navController?.topViewController as? MainViewController
            if (mainController != nil) {
                mainController!.reloadData()
            }
        }
        
        handler(UIBackgroundFetchResult.NewData);

        application.applicationIconBadgeNumber = 0
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        if (url.scheme != "keepitcool") {
            return false;
        }
        
        var untappdToken: String;
        
        if (url.host == "untappd") {
            untappdToken = url.fragment!
            let navController = window?.rootViewController as? MainNavigationViewController
            if (navController != nil) {
                let triggersController = navController?.topViewController as? TriggersViewController
                if (triggersController != nil) {
                    triggersController!.untappdConnected(untappdToken)
                }
            }
        }
        
        return true;
    }

}

