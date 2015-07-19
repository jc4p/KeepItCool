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
    var keyBytes = [0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00] as [UInt8]
    var ivBytes = [0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00] as [UInt8]
    
    init(hash: String) {
        keyBytes = [UInt8](hash.substringWithRange(Range<String.Index>(start: hash.startIndex, end: advance(hash.startIndex, 16))).utf8)
        ivBytes = [UInt8](hash.substringWithRange(Range<String.Index>(start: advance(hash.startIndex, 16), end: hash.endIndex)).utf8)
    }
    
    private func hexByteStringToByteArray(input: String) -> [UInt8] {
        let charArray = Array(input.characters)
        
        var intArray = [UInt8]()
        let inputCount = input.characters.count
        
        for var i = 0; i < inputCount; i += 2 {
            var hexCode: String = ""
            hexCode.append(charArray[i])
            hexCode.append(charArray[i + 1])
            let num = UInt8(strtoul(hexCode, nil, 16))
            intArray.append(num)
        }
        
        return intArray
    }
    
    func encryptString(input: String) -> String {
        let inputData = input.dataUsingEncoding(NSUTF8StringEncoding)!.arrayOfBytes()
        let bytes = AES(key: keyBytes, iv: ivBytes, blockMode: CipherBlockMode.CBC)!.encrypt(inputData, padding: PKCS7())!
        return NSData.withBytes(bytes).hexString
    }
    
    func decryptString(input: String) -> String {
        let inputData = hexByteStringToByteArray(input)
        let decryptedBytes = AES(key: keyBytes, iv: ivBytes, blockMode: CipherBlockMode.CBC)!.decrypt(inputData, padding: PKCS7())
        
        var result = ""
        for asciiCode in decryptedBytes! {
            result.append(UnicodeScalar(asciiCode))
        }
        
        return result
    }

}
