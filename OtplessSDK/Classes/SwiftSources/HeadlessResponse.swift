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
    
    @objc public func toDict() -> [String: String] {
        return [
            "responseType": responseType,
            "responseData": Utils.convertDictionaryToString(responseData ?? [:]),
            "statusCode": String(statusCode)
        ]
    }
    
    internal func toEventDict(onDictCreate: @escaping (([String: String], _ musId: String, _ requestId: String) -> Void)) {
        var requestId = ""
        var musId = ""
        var eventResponse: [String: String] = [:]
        eventResponse["statusCode"] = String(self.statusCode)
        eventResponse["responseType"] = self.responseType
        
        if self.statusCode != 200 {
            if let responseData = self.responseData {
                eventResponse["response"] = Utils.convertDictionaryToString(responseData)
            } else {
                eventResponse["response"] = "{}"
            }
        } else {
            if let responseData = self.responseData {
                requestId = responseData["token"] as? String ?? ""
                musId = responseData["userId"] as? String ?? ""
            } else {
                eventResponse["response"] = "{}"
            }
        }
        
        onDictCreate(eventResponse, musId, requestId)
    }
}
