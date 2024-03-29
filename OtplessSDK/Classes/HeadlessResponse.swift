//
//  HeadlessResponse.swift
//  OtplessSDK
//
//  Created by Sparsh on 28/03/24.
//

import Foundation

@objc public class HeadlessResponse: NSObject {
    @objc public var request: String
    @objc public var responseData: [String: Any]?
    @objc public var errorString: String?
    
    @objc public init(request: String, responseData: [String : Any]? = nil, errorString: String? = nil) {
        self.request = request
        self.responseData = responseData
        self.errorString = errorString
    }
}
