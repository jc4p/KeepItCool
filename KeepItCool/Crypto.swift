//
//  Crypto.swift
//  KeepItCool
//
//  Created by Kasra Rahjerdi on 6/4/15.
//  Copyright (c) 2015 Kasra Rahjerdi. All rights reserved.
//

import Foundation
import CryptoSwift

public class Crypto: NSObject {
    static let keyBytes = [0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00] as [UInt8]
    static let ivBytes = [0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00] as [UInt8]

    static func hexByteStringToByteArray(input: String) -> [UInt8] {
        let charArray = Array(input)
        
        var intArray = [UInt8]()
        var inputCount = count(input)
        
        for var i = 0; i < inputCount; i += 2 {
            var hexCode: String = ""
            hexCode.append(charArray[i])
            hexCode.append(charArray[i + 1])
            let num = UInt8(strtoul(hexCode, nil, 16))
            intArray.append(num)
        }
        
        return intArray
    }
    
    static func encryptString(input: String) -> String {
        let inputData = input.dataUsingEncoding(NSUTF8StringEncoding)!.arrayOfBytes()
        let bytes = AES(key: keyBytes, iv: ivBytes, blockMode: CipherBlockMode.CBC)!.encrypt(inputData, padding: PKCS7())!
        return NSData.withBytes(bytes).hexString
    }
    
    static func decryptString(input: String) -> String {
        let inputData = hexByteStringToByteArray(input)
        let decryptedBytes = AES(key: keyBytes, iv: ivBytes, blockMode: CipherBlockMode.CBC)!.decrypt(inputData, padding: PKCS7())
        
        var result = ""
        for asciiCode in decryptedBytes! {
            result.append(UnicodeScalar(asciiCode))
        }
        
        return result
    }

}
