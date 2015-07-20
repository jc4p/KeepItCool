//
//  SubZeroClient.swift
//  KeepItCool
//
//  Created by Kasra Rahjerdi on 7/19/15.
//  Copyright © 2015 Kasra Rahjerdi. All rights reserved.
//

import Foundation
import Alamofire

class SubZeroClient {
    private static let API_BASE = "https://kasra-subzero.herokuapp.com/"

    static func register(uid: String, deviceToken: String) -> Request {
        return Alamofire.request(.POST, URLString: API_BASE + "register", parameters: ["uid": uid, "deviceToken": deviceToken])
    }
    
    static func setUntappdToken(uid: String, untappdToken: String) -> Request {
        return Alamofire.request(.POST, URLString: API_BASE + "tokens/untappd", parameters: ["uid": uid, "untappdToken": untappdToken])
    }
    
    static func saveSettings(uid: String, useUntappd: Bool, useSwarm: Bool) -> Request {
        return Alamofire.request(.POST, URLString: API_BASE + "settings", parameters: ["uid": uid, "useUntappd": useUntappd, "useSwarm": useSwarm])
    }
}
