//
//  OtplessEventResponse.swift
//  OtplessSDK
//
//  Created by Anubhav Mathur on 12/12/23.
//

import Foundation

@objc public enum EventCode: Int {
    case networkFailure = 0
    case userDismissed = 1
    // Add more cases if needed
}

@objc public class OtplessEventResponse: NSObject {
    @objc public var responseString: String?
    @objc public var responseData: NSDictionary?
    @objc public var eventCode: EventCode

    @objc public init(responseString: String?, responseData: [String: Any]?, eventCode: EventCode) {
        self.responseString = responseString
        self.responseData = responseData as NSDictionary? // Convert Swift Dictionary to NSDictionary
        self.eventCode = eventCode
    }
}


