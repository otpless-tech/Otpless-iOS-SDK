//
//  OtplessResponse.swift
//  OtplessSDK
//
//  Created by Anubhav Mathur on 09/06/23.
//

import Foundation

@objc public class OtplessResponse:NSObject {
    @objc public var errorString: String?
    @objc public var responseData: [String: Any]?

    init(responseString: String?, responseData: [String: Any]?) {
        self.errorString = responseString
        self.responseData = responseData
    }
}

