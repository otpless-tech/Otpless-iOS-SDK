//
//  HeadlessRequest.swift
//  OtplessSDK
//
//  Created by Sparsh on 08/02/24.
//

import Foundation

@objc public class HeadlessRequest: NSObject {
    
    private var channel: String = HeadlessChannel.PHONE
    private var phoneNumber: String?
    private var email: String?
    private var otp: String?
    private var code: String?
    private var channelType: String?
    private var appId: String?
    private var countryCode: String?
    
    @objc public func setPhoneNumber(number: String, withCountryCode countryCode: String) {
        self.phoneNumber = number
        self.countryCode = countryCode
        channel = HeadlessChannel.PHONE
        channelType = nil
        email = nil
    }
    
    @objc public func setEmail(_ email: String) {
        self.email = email
        channel = HeadlessChannel.EMAIL
        phoneNumber = nil
        channelType = nil
    }
    
    @objc public func setChannelType(_ channelType: String) {
        self.channelType = channelType
        channel = HeadlessChannel.OAUTH
        phoneNumber = nil
        email = nil
    }
    
    @objc public func setAppId(appId: String) {
        self.appId = appId
    }
    
    public func getAppId() -> String {
        guard let appId else {
            return ""
        }
        
        return appId
    }
    
    func setOtp(otp: String) {
        self.otp = otp
    }
    
    func setCode(code: String) {
        self.code = code
    }
    
    func hasCodeOrOtp() -> Bool {
        return (code != nil) || (otp != nil)
    }
    
    func makeJson() -> [String: String] {
        var requestJson = [String: String]()
        requestJson["channel"] = channel
        
        if let phoneNumber = phoneNumber {
            requestJson["phone"] = phoneNumber
        }
        
        switch channel {
        case HeadlessChannel.PHONE:
            if let phoneNumber = phoneNumber,
               let countryCode = countryCode 
            {
                requestJson["phone"] = phoneNumber
                requestJson["countryCode"] = countryCode
            }
            break
            
        case HeadlessChannel.EMAIL:
            if let email = email {
                requestJson["email"] = email
            }
            break
            
        case HeadlessChannel.OAUTH:
            if let channelType = channelType {
                requestJson["channelType"] = channelType
            }
            break
            
        default:
            break
        }
        
        if let otp = otp {
            requestJson["otp"] = otp
        }
        
        if let code = code {
            requestJson["code"] = code
        }
        
        return requestJson
    }
    
}
