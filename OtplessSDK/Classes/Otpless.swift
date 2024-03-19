//
//  Otpless.swift
//  OtplessSDK
//
//  Created by Otpless on 05/02/23.
//

import Foundation


@objc final public class Otpless:NSObject {
    
    @objc public weak var delegate: onResponseDelegate?
    @objc public weak var eventDelegate: onEventCallback?
    @objc public var hideNetworkFailureUserInterface: Bool = false
    @objc public var hideActivityIndicator: Bool = false
    weak var otplessVC: OtplessVC?
    weak var merchantVC: UIViewController?
    var initialParams: [String : Any]?
    @objc public static let sharedInstance: Otpless = {
        let instance = Otpless()
        DeviceInfoUtils.shared.initialise()
        return instance
    }()
    var loader : OtplessLoader? = nil
    private override init(){}
    var appId: String = ""
    
    @objc public func initialise(vc : UIViewController){
        merchantVC = vc
    }
    
    @objc public func showOtplessLoginPageWithParams(appId: String!, vc: UIViewController,params: [String : Any]?){
        
        initiateVC(vc: vc, params: params, hideNetworkUi: hideNetworkFailureUserInterface, loginPage: true , hideIndicator: hideActivityIndicator, appid: appId)
    }
    
    func initiateVC (vc: UIViewController,params: [String : Any]?,hideNetworkUi : Bool, loginPage : Bool, hideIndicator : Bool, appid: String){
        appId = appid
        merchantVC = vc
        let oVC = OtplessVC()
        oVC.appId = appid
        oVC.networkUIHidden = hideNetworkUi
        oVC.hideActivityIndicator = hideIndicator
        initialParams = params
        oVC.initialParams = params
        otplessVC = oVC
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            vc.present(oVC, animated: true) {
            }
        }
    }
    
    @objc public func dismissVC(animated : Bool){
        otplessVC?.merchantDismissVc(animated: animated)
    }
    
    public func onResponse(response : OtplessResponse){
        if((Otpless.sharedInstance.delegate) != nil){
            Otpless.sharedInstance.delegate?.onResponse(response: response)
        }
    }
    
    @objc public func isWhatsappInstalled() -> Bool{
        if UIApplication.shared.canOpenURL(URL(string: "whatsapp://")! as URL) {
            return true
        } else {
            return false
        }
    }
    
    @objc public func isOtplessDeeplink(url : URL) -> Bool{
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: true), let host = components.host {
            switch host {
            case "otpless":
                return true
            default:
                break
            }
        }
        return false
    }
    
    
    @objc public func processOtplessDeeplink(url : URL) {
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: true), let host = components.host {
            switch host {
            case "otpless":
                if otplessVC != nil {
                    otplessVC?.onDeeplinkRecieved(deeplink: url)
                    OtplessHelper.sendEvent(event: "intent_redirect_in")
                }
            default:
                break
            }
        }
    }
    
}


@objc public protocol onResponseDelegate: AnyObject {
    @objc func onResponse(response: OtplessResponse?)
}

@objc public protocol onEventCallback: AnyObject {
    @objc func onEvent(eventCallback: OtplessEventResponse?)
}

