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
    private static let API_BASE = "http://kasra-subzero.herokuapp.com/"

    static func register(uid: String, deviceToken: NSData) -> Request {
        return Alamofire.request(.POST, URLString: API_BASE + "register", parameters: ["uid": uid, "deviceToken": deviceToken])
    }
}
