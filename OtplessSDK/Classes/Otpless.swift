//
//  Otpless.swift
//  OtplessSDK
//
//  Created by Otpless on 05/02/23.
//

import Foundation


public class Otpless {
    
    public weak var delegate: onResponseDelegate?
    public weak var delegateOnVerify: onVerifyWaidDelegate?
    public static let sharedInstance: Otpless = {
        let instance = Otpless()
        return instance
    }()
    private var loader : OtplessLoader? = nil
    private init(){}
        
     func continueToWhatsapp(url: String){
        UIApplication.shared.open(URL(string: url)!)
    }
    
    public func continueToWhatsapp(){
        if let completeUrl = OtplessHelper.getCompleteUrl() {
            OtplessNetworkHelper.shared.setBaseUrl(url: completeUrl)
            continueToWhatsapp(url: OtplessHelper.addEventDetails(url: completeUrl))
            loader = OtplessLoader()
            loader?.show()
        }
    }
    
    public func isOtplessDeeplink(url : URL) -> Bool{
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: true), let host = components.host {
            switch host {
            case "otpless":
                return true
            default:
                return false
                break
            }
        }
        return false
    }
    
    public func processOtplessDeeplink(url : URL) {
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: true), let host = components.host {
            switch host {
            case "otpless":
                if let itemId = components.queryItems?.first(where: { $0.name == "waId" })?.value {
                    verifywaID(waId: itemId)
                } else {
                    
                }
            default:
                break
            }
        }
    }
    
    private func verifywaID(waId : String){
            let headers = ["Content-Type": "application/json","Accept":"application/json"]
            let bodyParams = ["userId": waId, "api": "getUserDetail"]
            OtplessNetworkHelper.shared.fetchData(from: "metaverse", method: "POST", headers: headers, bodyParams:bodyParams) { (data, response, error) in
              guard let data = data else {
                // handle error
                  if (error != nil) {
                      OtplessHelper.removeUserMobileAndWaid()
                  }
                  DispatchQueue.main.async { [self] in
                      if((self.delegateOnVerify) != nil){
                          delegateOnVerify?.onVerifyWaid(mobile: nil, waId: nil, message: "error", error: "Error in verify waid :" + waId)
                      } else {
                          loader?.hide()
                          if((self.delegate) != nil){
                              delegate?.onResponse(waId: nil, message: "error", error: "Error in verify waid :" + waId)
                          }
                      }
                      
                  }
                return
              }
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    // process the JSON data
                    let jsonDictionary = json as? [String: Any]
                     if let jsonData = jsonDictionary?["data"] as? [String: Any]{
                         if let mobile = jsonData["userMobile"] as? String,
                        let waid = jsonData["waId"] as? String {
                         OtplessHelper.saveUserMobileAndWaid(waId: waid, userMobile: mobile)
                             DispatchQueue.main.async { [self] in
                                 if((self.delegateOnVerify) != nil){
                                     delegateOnVerify?.onVerifyWaid(mobile: mobile, waId: waid, message: "success", error: nil)
                                 } else {
                                     loader?.hide()
                                     if((self.delegate) != nil){
                                         delegate?.onResponse(waId: waid, message: "success", error: nil)
                                     }
                                 }
                                 
                             }
                     }
                  }
                    
                  } catch {
                      DispatchQueue.main.async { [self] in
                          if((self.delegateOnVerify) != nil){
                              delegateOnVerify?.onVerifyWaid(mobile: nil, waId: nil, message: "error", error: "Exception occured verifying waid :" + waId)
                          } else {
                              loader?.hide()
                              if((self.delegate) != nil){
                                  delegate?.onResponse(waId: nil, message: "error", error: "Exception occured verifying waid :" + waId)
                              }
                          }
                          
                      }
                  }
            }
    }
}
// used for internal purpose by WhatsappLoginButton
public protocol onVerifyWaidDelegate: AnyObject {
    func onVerifyWaid(mobile : String?, waId : String?,message: String?, error : String?)
}

// When you want to do direct integration in which you will not be using WhatsappLoginButton
public protocol onResponseDelegate: AnyObject {
    func onResponse(waId : String?, message: String?, error : String?)
}

