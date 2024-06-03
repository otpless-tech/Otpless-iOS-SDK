//
//  DeviceInfoModel.swift
//  OTPless
//
//  Created by Anubhav Mathur on 22/05/23.
//

import Foundation
import UIKit

class DeviceInfoModel: NSObject {
    var udid : String!
    var appVersion : String!
    var manufacturer : String!
    var model : String!
    
    override init() {
        model = UIDevice.modelName
        manufacturer = "Apple"
        if let app_version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            appVersion = app_version
        }
        if let _udid = UIDevice.current.identifierForVendor?.uuidString as String? {
            udid = _udid
        }

    }
    
    func toDictionary() -> [String:Any]
    {
        var dictionary = [String:Any]()
        if udid != nil{
            dictionary["deviceId"] = udid
        }
        if appVersion != nil{
            dictionary["app_version"] = appVersion
        }
        if manufacturer != nil{
            dictionary["manufacturer"] = manufacturer
        }
        if model != nil {
            dictionary["model"] = model
        }
        
        return dictionary
    }
}
