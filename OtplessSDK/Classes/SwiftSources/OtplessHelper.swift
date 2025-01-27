//
//  OtplessHelper.swift
//  OtplessSDK
//
//  Created by Otpless on 06/02/23.
//

import Foundation
import UIKit

class OtplessHelper {
    
  public static func checkValueExists(forKey key: String) -> Bool {
        return UserDefaults.standard.object(forKey: key) != nil
    }

    public static func getValue<T>(forKey key: String) -> T? {
        return UserDefaults.standard.object(forKey: key) as? T
    }
    
    public static func setValue<T>(value: T?, forKey key: String) {
            UserDefaults.standard.set(value, forKey: key)
        }
    
    public static func removeValue(forKey key: String) {
        UserDefaults.standard.removeObject(forKey: key)
    }
    
    public static func UIColorFromRGB(rgbValue: UInt) -> UIColor {
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    
    public static func sendEvent(event: String, extras: [String: String] = [:], musId: String = "", requestId: String = ""){
        var params = [String: String]()
        params["event_name"] = event
        params["platform"] = "iOS"
        params["sdk_version"] = "2.2.8"
        params["mid"] = Otpless.sharedInstance.getAppId()
        params["event_timestamp"] = Utils.formatCurrentTimeToDateString()
        let tsid = DeviceInfoUtils.shared.getTrackingSessionId()
        let inid = DeviceInfoUtils.shared.getInstallationId()
        
        if let request = Otpless.sharedInstance.merchantHeadlessRequest {
            params["request"] = Utils.convertDictionaryToString(request.makeJson())
        }
        
        if tsid != nil {
            params["tsid"] = tsid
        }
        if inid != nil {
            params["inid"] = inid
        }
        
        var eventParams = [String: String]()
        for (key, value) in extras {
            eventParams[key] = value
        }
        
        if !requestId.isEmpty {
            params["token"] = requestId
        }
        
        if !musId.isEmpty {
            params["musid"] = musId
        }
        
        eventParams["device_info"] = DeviceInfoUtils.shared.getDeviceInfoString()
        
        params["event_params"] = Utils.convertDictionaryToString(eventParams)
        
        OtplessLogger.log(dictionary: params, type: "EVENT")
        
        OtplessNetworkHelper.shared.fetchDataWithGET(
            apiRoute: "https://mtkikwb8yc.execute-api.ap-south-1.amazonaws.com/prod/appevent",
            params: params
        ) { _, _, _ in
        }
    }
}
