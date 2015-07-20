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
    var key: String;
    var iv: String;
    
    init(hash: String) {
        key = hash.substringWithRange(Range<String.Index>(start: hash.startIndex, end: advance(hash.startIndex, 16)))
        iv = hash.substringWithRange(Range<String.Index>(start: advance(hash.startIndex, 16), end: hash.endIndex))
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
        var bytes: [UInt8];
        do {
            bytes = try AES(key: key, iv: iv)!.encrypt(inputData)
        } catch {
            return "";
        }
        return NSData.withBytes(bytes).hexString
    }
    
    func decryptString(input: String) -> String {
        let inputData = hexByteStringToByteArray(input)
        var decryptedBytes: [UInt8];
        do {
            decryptedBytes = try AES(key: key, iv: iv)!.decrypt(inputData)
        } catch {
            return ""
        }
        
        var result = ""
        for asciiCode in decryptedBytes {
            result.append(UnicodeScalar(asciiCode))
        }
        
        return result
    }

}
