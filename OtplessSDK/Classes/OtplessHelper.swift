//
//  OtplessHelper.swift
//  OtplessSDK
//
//  Created by Otpless on 06/02/23.
//

import Foundation
class OtplessHelper {
   public static let waidDefaultKey = "otpless_waId"
   public static let userMobileDefaultKey = "otpless_user_mobile"
    private static let link = "https://*.authlink.me"
    
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
        params["sdk_version"]="1.1.5"
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: DeviceInfoUtils.shared.getAppInfo(), options: .prettyPrinted)
            if let jsonStr = String(data: jsonData, encoding: .utf8) as String? {
                params["event_params"] = jsonStr
            }
        } catch {
            print(error.localizedDescription)
        }
        OtplessNetworkHelper.shared.fetchDataWithGET(apiRoute: "https://mtkikwb8yc.execute-api.ap-south-1.amazonaws.com/prod/appevent",params: params) { (data, response, error) in}
    }
    
    public static func getCompleteUrl() -> String? {
        if let urlTypes = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]] {
            for urlType in urlTypes {
                if let urlSchemes = urlType["CFBundleURLSchemes"] as? [String], let identifier = urlType["CFBundleURLName"] as? String {
                    if urlSchemes.count > 0  {
                        var hostUri = ""
                        for url in urlSchemes {
                            if (url.contains("otpless") && identifier.contains("otpless")){
                                hostUri = url
                                break
                            }
                        }
                        if hostUri == "" {
                            continue
                        }
                        let scheme = hostUri
                        let urlScheme = String(scheme).replacingOccurrences(of: "otpless", with: "")
                        let domainUrl = String(link).replacingOccurrences(of: "*", with:urlScheme)
                        let completeUrl = domainUrl + "?redirectUri=" + scheme + "://" + identifier
                        return completeUrl
                      }
                }
            }
        }
        return nil
    }
}
