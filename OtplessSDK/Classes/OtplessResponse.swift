//
//  OtplessResponse.swift
//  OtplessSDK
//
//  Created by Anubhav Mathur on 09/06/23.
//

import Foundation

public class OtplessResponse {
   public var errorString: String?
   public var responseData: [String: Any]?

    init(responseString: String?, responseData: [String: Any]?) {
        self.errorString = responseString
        self.responseData = responseData
    }
}

