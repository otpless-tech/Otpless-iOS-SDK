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
    var appId: String = ""
    @objc public weak var headlessDelegate: onHeadlessResponseDelegate?
    @objc weak var otplessView: OtplessView?
    private var headlessViewHeight: CGFloat = 0.1
    private var headlessViewWidth: CGFloat = 0.1
    private var isOneTapEnabled: Bool = true
    
    @objc public func initialise(vc : UIViewController){
        merchantVC = vc
    }
    
    @objc public func showOtplessLoginPageWithParams(appId: String!, vc: UIViewController,params: [String : Any]?){
        generateTrackingId()
        initiateLoginPageView(vc: vc, params: params, hideNetworkUi: hideNetworkFailureUserInterface, loginPage: true, hideIndicator: hideActivityIndicator, appid: appId)
    }
    
    @objc public func startHeadless(vc: UIViewController, headlessRequest: HeadlessRequest, isOneTapEnabled: Bool = true) {
        generateTrackingId()
        merchantVC = vc
        self.appId = headlessRequest.getAppId()
        self.isOneTapEnabled = isOneTapEnabled
        addHeadlessViewToMerchantVC(headlessRequest: headlessRequest, isOneTapEnabled: isOneTapEnabled)
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if vcView != nil {
                        let loginPage = OtplessView(appId: appId, isLoginPage: true)
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
                            self.setLoginPageConstraints()
                        }
                    }
                }
            }
        }
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
                if otplessView != nil {
                    otplessView?.onDeeplinkRecieved(deeplink: url)
                    OtplessHelper.sendEvent(event: "intent_redirect_in")
                }
            default:
                break
            }
        }
    }
    
    private func generateTrackingId() {
        DeviceInfoUtils.shared.generateTrackingId()
    }
    
    func addHeadlessViewToMerchantVC(headlessRequest: HeadlessRequest, isOneTapEnabled: Bool) {
        if (merchantVC != nil && merchantVC?.view != nil) {
            if otplessView == nil || otplessView?.superview == nil {
                let vcView = merchantVC?.view
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if vcView != nil {
                        
                        var headlessView: OtplessView
                        headlessView = OtplessView(headlessRequest: headlessRequest, isOneTapEnabled: isOneTapEnabled)
                        self.otplessView = headlessView
                        
                        if let view = vcView {
                            if let lastSubview = view.subviews.last {
                                view.insertSubview(headlessView, aboveSubview: lastSubview)
                            } else {
                                view.addSubview(headlessView)
                            }
                        }
                        
                        if #available(iOS 11.0, *) {
                            self.setHeadlessViewConstraints()
                        }
                    }
                }
            } else {
                self.otplessView?.sendHeadlessRequestToWeb(request: headlessRequest)
            }
        }
    }
    
    func setOtplessViewHeight(heightPercent: Int) {
        if heightPercent < 0 || heightPercent > 100 {
            self.headlessViewHeight = UIScreen.main.bounds.height
        } else {
            self.headlessViewHeight = (CGFloat(heightPercent) * UIScreen.main.bounds.height) / 100
        }
        
        self.headlessViewWidth = UIScreen.main.bounds.width
        
        if otplessView != nil {
            otplessView!.constraints.forEach { (constraint) in
                if constraint.firstAttribute == .height {
                    constraint.constant = self.headlessViewHeight
                }
                if constraint.firstAttribute == .width {
                    constraint.constant = self.headlessViewWidth
                }
            }
        }
    }
    
    private func setHeadlessViewConstraints() {
        if let headlessView = otplessView, let vcView = merchantVC?.view {
            headlessView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                headlessView.widthAnchor.constraint(equalToConstant: self.headlessViewHeight),
                headlessView.heightAnchor.constraint(equalToConstant: self.headlessViewHeight),
                headlessView.centerXAnchor.constraint(equalTo: vcView.centerXAnchor),
                headlessView.centerYAnchor.constraint(equalTo: vcView.centerYAnchor)
            ])
        }
    }
    
    private func setLoginPageConstraints() {
        if let loginPage = otplessView,
           let vcView = merchantVC?.view {
            loginPage.translatesAutoresizingMaskIntoConstraints = false
            
            let layoutGuide = vcView.safeAreaLayoutGuide
            NSLayoutConstraint.activate([
                loginPage.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor),
                loginPage.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor),
                loginPage.heightAnchor.constraint(equalToConstant: vcView.bounds.height),
                loginPage.bottomAnchor.constraint(equalTo: layoutGuide.bottomAnchor)
            ])
        }
    }
    
    func sendHeadlessResponse(response: HeadlessResponse, closeView: Bool) {
        self.headlessDelegate?.onHeadlessResponse(response: response)
        if closeView && self.otplessView != nil {
            self.otplessView?.removeFromSuperview()
            self.otplessView = nil
        }
    }
    
    @objc public func dismissOtplessView() {
        self.headlessDelegate = nil
        self.otplessView?.stopOtpless()
        self.otplessView = nil
    }
    
    @objc public func verifyOTP(otp: String, headlessRequest: HeadlessRequest?) {
        guard let request = headlessRequest else {
            return
        }
        
        request.setOtp(otp: otp)
        otplessView?.sendHeadlessRequestToWeb(request: request)
    }

    @objc public func verifyCode(code: String, headlessRequest: HeadlessRequest?) {
        guard let request = headlessRequest else {
            return
        }
        
        request.setCode(code: code)
        otplessView?.sendHeadlessRequestToWeb(request: request)
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
