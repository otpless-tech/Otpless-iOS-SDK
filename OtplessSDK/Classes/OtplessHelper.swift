//
//  OtplessHelper.swift
//  OtplessSDK
//
//  Created by Otpless on 06/02/23.
//

import Foundation
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
    
    
    public static func sendEvent(event: String){
        var params = [String: String]()
        params["event_name"]=event
        params["platform"]="iOS"
        params["sdk_version"]="2.1.8"
        let tsid = DeviceInfoUtils.shared.getTrackingSessionId()
        let inid = DeviceInfoUtils.shared.getInstallationId()
        
        if tsid != nil {
            params["tsid"] = tsid
        }
        if inid != nil {
            params["inid"] = inid
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: DeviceInfoUtils.shared.getAppInfo(), options: .prettyPrinted)
            if let jsonStr = String(data: jsonData, encoding: .utf8) as String? {
                params["event_params"] = jsonStr
            }
        } catch {
           
        }
        OtplessNetworkHelper.shared.fetchDataWithGET(apiRoute: "https://mtkikwb8yc.execute-api.ap-south-1.amazonaws.com/prod/appevent",params: params) { (data, response, error) in}
    }
}
