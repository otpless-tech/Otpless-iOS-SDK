//
//  HeadlessResponse.swift
//  OtplessSDK
//
//  Created by Sparsh on 28/03/24.
//

import Foundation

@objc public class HeadlessResponse: NSObject {
    @objc public var responseType: String
    @objc public var responseData: [String: Any]?
    @objc public var statusCode: Int
    
    @objc public init(responseType: String, responseData: [String : Any]? = nil, statusCode: Int = 0) {
        self.responseType = responseType
        self.responseData = responseData
        self.statusCode = statusCode
    }
    
    @objc public func toString() -> String {
        let responseDataString = responseData?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "nil"
        return "{responseType: \(responseType), responseData: [\(responseDataString)], statusCode: \(statusCode)}"
    }
}
