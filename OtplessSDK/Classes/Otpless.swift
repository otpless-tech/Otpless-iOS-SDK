//
//  Otpless.swift
//  OtplessSDK
//
//  Created by Otpless on 05/02/23.
//

import Foundation
import SwiftUI

@objc final public class Otpless:NSObject {
    
    @objc public weak var delegate: onResponseDelegate?
    @objc public weak var eventDelegate: onEventCallback?
    @objc public var hideNetworkFailureUserInterface: Bool = false
    @objc public var hideActivityIndicator: Bool = false
    @objc public var webviewInspectable: Bool = false
    weak var merchantVC: UIViewController?
    var initialParams: [String : Any]?
    @objc public static let sharedInstance: Otpless = {
        let instance = Otpless()
        DeviceInfoUtils.shared.initialise()
        return instance
    }()
    var loader : OtplessLoader? = nil
    private override init(){}
    public var appId: String = ""
    @objc public weak var headlessDelegate: onHeadlessResponseDelegate?
    @objc weak var otplessView: OtplessView?
    private var isOneTapEnabled: Bool = true
    var responseCallback: ((OtplessResponse?) -> Void)?
    var isSwiftUI = false
    var headlessResponseCallback: ((HeadlessResponse?) -> Void)?
    
    @objc public func initialise(vc : UIViewController, appId: String!){
        merchantVC = vc
        self.appId = appId
        
        if isOneTapEnabled {
            let oneTapReq = HeadlessRequest()
            oneTapReq.setChannelType("")
            addHeadlessViewToMerchantVC(headlessRequest: oneTapReq)
        }
    }
    
    @objc public func showOtplessLoginPageWithParams(appId: String!, vc: UIViewController,params: [String : Any]?){
        initiateLoginPageView(vc: vc, params: params, hideNetworkUi: hideNetworkFailureUserInterface, loginPage: true, hideIndicator: hideActivityIndicator, appid: appId)
    }
    
    @objc public func startHeadless(headlessRequest: HeadlessRequest) {
        addHeadlessViewToMerchantVC(headlessRequest: headlessRequest)
    }
    
    private func initiateLoginPageView(vc: UIViewController, params: [String : Any]?, hideNetworkUi : Bool, loginPage : Bool, hideIndicator : Bool, appid: String) {
        appId = appid
        merchantVC = vc
        initialParams = params
        addLoginPageToMerchantVC(appId: appid, hideNetworkUi: hideNetworkUi, hideIndicator: hideIndicator)
    }
    
    private func addLoginPageToMerchantVC(appId: String, hideNetworkUi: Bool, hideIndicator: Bool) {
        if (merchantVC != nil && merchantVC?.view != nil) {
            if otplessView == nil || otplessView?.superview == nil {
                let vcView = merchantVC?.view
                DispatchQueue.main.async {
                    if vcView != nil {
                        let loginPage = OtplessView(isLoginPage: true)
                        loginPage.setLoginPageAttributes(
                            networkUIHidden: hideNetworkUi,
                            hideActivityIndicator: hideIndicator,
                            initialParams: self.initialParams
                        )
                        
                        self.otplessView = loginPage
                        
                        if let view = vcView {
                            if let lastSubview = view.subviews.last {
                                view.insertSubview(loginPage, aboveSubview: lastSubview)
                            } else {
                                view.addSubview(loginPage)
                            }
                        }
                        
                        if #available(iOS 11.0, *) {
                            if let loginPage = self.otplessView,
                               let vcView = self.merchantVC?.view {
                                
                                let layoutGuide = vcView.safeAreaLayoutGuide
                                loginPage.setConstraints([
                                    loginPage.centerXAnchor.constraint(equalTo: layoutGuide.centerXAnchor),
                                    loginPage.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height),
                                    loginPage.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width),
                                    loginPage.bottomAnchor.constraint(equalTo: layoutGuide.bottomAnchor)
                                ])
                            }
                        }
                    }
                }
            }
        }
    }
    
    public func onResponse(response : OtplessResponse){
        if isSwiftUI {
            if #available(iOS 13.0, *) {
                SwiftUISupport.sharedInstance.setResponseInCallback(response)
            }
        } else {
            if((Otpless.sharedInstance.delegate) != nil){
                Otpless.sharedInstance.delegate?.onResponse(response: response)
            }
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
                if otplessView != nil {
                    otplessView?.onDeeplinkRecieved(deeplink: url)
                    OtplessHelper.sendEvent(event: "intent_redirect_in")
                }
            default:
                break
            }
        }
    }
    
    func addHeadlessViewToMerchantVC(headlessRequest: HeadlessRequest) {
        if (merchantVC != nil && merchantVC?.view != nil) {
            if otplessView == nil || otplessView?.superview == nil {
                let vcView = merchantVC?.view
                DispatchQueue.main.async {
                    if vcView != nil {
                        
                        var headlessView: OtplessView
                        headlessView = OtplessView(headlessRequest: headlessRequest)
                        self.otplessView = headlessView
                        
                        if let view = vcView {
                            if let lastSubview = view.subviews.last {
                                view.insertSubview(headlessView, aboveSubview: lastSubview)
                            } else {
                                view.addSubview(headlessView)
                            }
                        }
                        
                        if #available(iOS 11.0, *) {
                            if let headlessView = self.otplessView,
                               let vcView = self.merchantVC?.view {
                                
                                headlessView.setConstraints([
                                    headlessView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width),
                                    headlessView.heightAnchor.constraint(equalToConstant: headlessView.getViewHeight()),
                                    headlessView.centerXAnchor.constraint(equalTo: vcView.centerXAnchor),
                                    headlessView.bottomAnchor.constraint(equalTo: vcView.bottomAnchor)
                                ])
                            }
                        }
                    }
                }
            } else {
                self.otplessView?.sendHeadlessRequestToWeb(request: headlessRequest)
            }
        }
    }
    
    func sendHeadlessResponse(response: HeadlessResponse, closeView: Bool) {
        if isSwiftUI {
            if #available(iOS 13.0, *) {
                SwiftUISupport.sharedInstance.setHeadlessResponseInCallback(response)
            }
        } else {
            self.headlessDelegate?.onHeadlessResponse(response: response)
        }
      
        if closeView && self.otplessView != nil {
            self.otplessView?.removeFromSuperview()
            self.otplessView = nil
        }
    }
    
    @objc public func dismissOtplessView() {
        self.otplessView?.stopOtpless(dueToNoInternet: false)
        self.otplessView = nil
    }
    
    @objc public func verifyOTP(otp: String, headlessRequest: HeadlessRequest?) {
        guard let request = headlessRequest else {
            return
        }
        
        request.setOtp(otp: otp)
        otplessView?.sendHeadlessRequestToWeb(request: request)
    }
    
    @objc public func setOneTapEnabled(_ isOneTapEnabled: Bool) {
        self.isOneTapEnabled = isOneTapEnabled
    }
    
    func isOneTapEnabledForHeadless() -> Bool {
        return self.isOneTapEnabled
    }
    
    @objc public func getAppId() -> String {
        return self.appId
    }
    
    func setOtplessViewHeight(heightPercent: Int) {
        otplessView?.setHeight(forHeightPercent: heightPercent)
    }
    
    private func getHeightFromHeightPercent(_ heightPercent: Int) -> Double {
        if heightPercent < 0 || heightPercent > 100 {
            return UIScreen.main.bounds.height
        } else {
            return ((CGFloat(heightPercent) * UIScreen.main.bounds.height) / 100 )
        }
    }
    
    @available(iOS 13.0, *)
    public func swiftUILoginPage(
        appId: String!,
        onResponse: @escaping (OtplessResponse?) -> Void
    ) -> some View {
        self.appId = appId
        self.isSwiftUI = true
        return SwiftUISupport.sharedInstance.initializeLoginPage(data: onResponse)
    }
    
    @available(iOS 13.0, *)
    public func swiftUIHeadlessView(
        appId: String!,
        headlessRequest: HeadlessRequest,
        onResponse: @escaping (HeadlessResponse?) -> Void
    ) -> some View {
        self.appId = appId
        self.isSwiftUI = true
        return SwiftUISupport.sharedInstance.startHeadlessSwiftUI(headlessRequest: headlessRequest, data: onResponse)
    }
}


@objc public protocol onResponseDelegate: AnyObject {
    @objc func onResponse(response: OtplessResponse?)
}

@objc public protocol onEventCallback: AnyObject {
    @objc func onEvent(eventCallback: OtplessEventResponse?)
}

@objc public protocol onHeadlessResponseDelegate: AnyObject {
    @objc func onHeadlessResponse(response: HeadlessResponse?)
}
