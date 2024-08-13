//
//  OtplessLogger.swift
//  OtplessSDK
//
//  Created by Sparsh on 26/07/24.
//

import Foundation

@objc public protocol OtplessLoggerDelegate: AnyObject {
    @objc func otplessLog(string: String, type: String)
}

class OtplessLogger {
    static func log(string: String, type: String) {
        #if DEBUG
            Otpless.sharedInstance.getLoggerDelegate()?.otplessLog(string: string, type: type)
        #endif
    }
    
    static func log(dictionary: [String: Any], type: String) {
        let str = Utils.convertDictionaryToString(dictionary)
        log(string: str, type: type)
    }
}
