//
//  DeviceInfoUtils.swift
//  OTPless
//
//  Created by Anubhav Mathur on 22/05/23.
//

import Foundation
import UIKit
import Foundation
import CommonCrypto

class DeviceInfoUtils {
    static let shared: DeviceInfoUtils = {
        let instance = DeviceInfoUtils()
        return instance
    }()
    public var isIntialised = false
    public var hasWhatsApp : Bool = false
    public var hasGmailInstalled : Bool = false
    public var hasOTPLESSInstalled : Bool = false
    public var appHash = ""
    private var inid: String?
    private var tsid: String?
    
    func initialise () {
        if (!isIntialised){
            hasWhatsApp = isWhatsappInstalled()
            hasGmailInstalled = isGmailInstalled()
            hasOTPLESSInstalled = isOTPLESSInstalled()
            appHash = getAppHash() ?? "noapphash"
            isIntialised = true
            generateTrackingId()
        }
    }

    func getAppHash() -> String? {
        if let executablePath = Bundle.main.executablePath {
            let fileURL = URL(fileURLWithPath: executablePath)
            if let fileData = try? Data(contentsOf: fileURL) {
                var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
                fileData.withUnsafeBytes {
                    _ = CC_SHA256($0.baseAddress, CC_LONG(fileData.count), &hash)
                }
                let hashData = Data(hash)
                let hashString = hashData.map { String(format: "%02hhx", $0) }.joined()
                return hashString
            }
        }
        return nil
    }

    func isWhatsappInstalled() -> Bool{
        if UIApplication.shared.canOpenURL(URL(string: "whatsapp://")! as URL) {
            return true
        } else {
            return false
        }
    }
    
    func isGmailInstalled() -> Bool{
        if UIApplication.shared.canOpenURL(URL(string: "googlegmail://")! as URL) {
            return true
        } else {
            return false
        }
    }
    func isOTPLESSInstalled() -> Bool{
        if (UIApplication.shared.canOpenURL(URL(string: "com.otpless.ios.app.otpless://")! as URL)){
            return true
        } else {
            return false
        }
    }
    
    func getAppInfo() -> [String: String] {
        initialise()
        var udid : String!
        var appVersion : String!
        var manufacturer : String!
        var model : String!
        var params = [String: String]()
        
        model = UIDevice.modelName
        manufacturer = "Apple"
        if let app_version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            appVersion = app_version
        }
        if let _udid = UIDevice.current.identifierForVendor?.uuidString as String? {
            udid = _udid
        }
        let os = ProcessInfo().operatingSystemVersion
        
        if udid != nil{
            params["deviceId"] = udid
        }
        if appVersion != nil{
            params["appVersion"] = appVersion
        }
        if manufacturer != nil{
            params["manufacturer"] = manufacturer
        }
        if model != nil {
            params["model"] = model
        }
        if inid != nil {
            params["inid"] = inid
        }
        if tsid != nil {
            params["tsid"] = tsid
        }
        params["osVersion"] = os.majorVersion.description + "." + os.minorVersion.description
        params["hasWhatsapp"] = hasWhatsApp.description
        params["hasOtplessApp"] = hasOTPLESSInstalled.description
        params["hasGmailApp"] = hasGmailInstalled.description
        
        if #available(iOS 12.0, *) {
            params["isSilentAuthSupported"] = "true"
        } 
        
        if #available(iOS 16.0, *) {
            params["isWebAuthnSupported"] = "true"
        }
        
        params["isDeviceSimulator"] = "\(isDeviceSimulator())"
        
        return params
    }
    
    func generateTrackingId() {
        if OtplessHelper.checkValueExists(forKey: "otpless_inid") {
            inid = getInstallationId()
        } else {
            inid = generateId(withTimeStamp: true)
            OtplessHelper.setValue(value: inid, forKey: "otpless_inid")
        }
        
        if tsid == nil {
            tsid = generateId(withTimeStamp: true)
        }
    }
    
    private func generateId(withTimeStamp: Bool) -> String {
        let uuid = UUID().uuidString
        if !withTimeStamp {
            return uuid
        }
        let timestamp = Int(Date().timeIntervalSince1970)
        let uniqueString = "\(uuid)-\(timestamp)"
        return uniqueString
    }
    
    func getInstallationId() -> String? {
        if inid != nil {
            return inid
        }
        return OtplessHelper.getValue(forKey: "otpless_inid")
    }
    
    func getTrackingSessionId() -> String? {
        return tsid
    }
    
    
    /// Determines whether the device is simulator.
    ///
    /// - returns: Boolean indicating whether device is simulator or not. Returns true if the device is simulator, else false.
    func isDeviceSimulator() -> Bool {
        #if swift(>=4.1)
            #if targetEnvironment(simulator)
                return true
            #else
                return false
            #endif
        #else
            #if (arch(i386) || arch(x86_64)) && os(iOS)
                return true
            #else
                return false
            #endif
        #endif
    }
}

public extension UIDevice {
    static let modelName: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        func mapToDevice(identifier: String) -> String {
            #if os(iOS)
            switch identifier {
            case "iPod5,1":                                 return "iPod Touch 5"
            case "iPod7,1":                                 return "iPod Touch 6"
            case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
            case "iPhone4,1":                               return "iPhone 4s"
            case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
            case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
            case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
            case "iPhone7,2":                               return "iPhone 6"
            case "iPhone7,1":                               return "iPhone 6 Plus"
            case "iPhone8,1":                               return "iPhone 6s"
            case "iPhone8,2":                               return "iPhone 6s Plus"
            case "iPhone9,1", "iPhone9,3":                  return "iPhone 7"
            case "iPhone9,2", "iPhone9,4":                  return "iPhone 7 Plus"
            case "iPhone8,4":                               return "iPhone SE"
            case "iPhone10,1", "iPhone10,4":                return "iPhone 8"
            case "iPhone10,2", "iPhone10,5":                return "iPhone 8 Plus"
            case "iPhone10,3", "iPhone10,6":                return "iPhone X"
            case "iPhone11,2":                              return "iPhone XS"
            case "iPhone11,4", "iPhone11,6":                return "iPhone XS Max"
            case "iPhone11,8":                              return "iPhone XR"
            case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
            case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
            case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
            case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
            case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
            case "iPad6,11", "iPad6,12":                    return "iPad 5"
            case "iPad7,5", "iPad7,6":                      return "iPad 6"
            case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
            case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
            case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
            case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
            case "iPad6,3", "iPad6,4":                      return "iPad Pro (9.7-inch)"
            case "iPad6,7", "iPad6,8":                      return "iPad Pro (12.9-inch)"
            case "iPad7,1", "iPad7,2":                      return "iPad Pro (12.9-inch) (2nd generation)"
            case "iPad7,3", "iPad7,4":                      return "iPad Pro (10.5-inch)"
            case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4":return "iPad Pro (11-inch)"
            case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8":return "iPad Pro (12.9-inch) (3rd generation)"
            case "AppleTV5,3":                              return "Apple TV"
            case "AppleTV6,2":                              return "Apple TV 4K"
            case "AudioAccessory1,1":                       return "HomePod"
            case "i386", "x86_64":                          return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "iOS"))"
            default:                                        return identifier
            }
            #elseif os(tvOS)
            switch identifier {
            case "AppleTV5,3": return "Apple TV 4"
            case "AppleTV6,2": return "Apple TV 4K"
            case "i386", "x86_64": return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "tvOS"))"
            default: return identifier
            }
            #endif
        }
        
        return mapToDevice(identifier: identifier)
    }()
}
