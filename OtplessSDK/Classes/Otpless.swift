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
    private var appId: String = ""
    @objc public weak var headlessDelegate: onHeadlessResponseDelegate?
    @objc weak var otplessView: OtplessView?
    private var isOneTapEnabled: Bool = true
    private var userAgent = "otplesssdk"
    private weak var loggerDelegate: OtplessLoggerDelegate?
    private var loginUri: String?
    
    /// Initializes `Otpless` for Headless support
    ///
    /// - parameter vc: Instance of your `UIViewController`
    /// - parameter appId: Your `APP_ID` from `Otpless`
    /// - parameter loginUri: Optional String to override the default `loginUri` when a custom deeplink is needed. Ensure the `url scheme` in `info.plist` matches. `Host` of the `loginUri` must  be `otpless`. Eg. "yourscheme://otpless"
    @objc public func initialise(vc : UIViewController, appId: String!, loginUri: String? = nil){
        merchantVC = vc
        self.appId = appId
        self.loginUri = loginUri
        
        let initHeadlessRequest = HeadlessRequest()
        initHeadlessRequest.setChannelType("")
        addHeadlessViewToMerchantVC(headlessRequest: initHeadlessRequest)
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
        self.headlessDelegate?.onHeadlessResponse(response: response)
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
    
    @available(*, deprecated, message: "To toggle the floater, visit https://otpless.com/dashboard/customer/customization/floater")
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
    
    // Added to provide user agent when forcefully making request over mobile data instead of wifi.
    func getUserAgent() -> String {
        return self.userAgent
    } 
    
    func setUserAgent(_ agent: String) {
        self.userAgent = agent
    }
    
    /// Determines whether the device is simulator.
    ///
    /// - returns: Boolean indicating whether device is simulator or not. Returns true if the device is simulator, else false.
    @objc public func isDeviceSimulator() -> Bool {
        return DeviceInfoUtils.shared.isDeviceSimulator()
    }
    
    /// Return's the application's WindowScene.
    ///
    /// - returns: An instance of `UIWindowScene?`.
    @available(iOS 15, *)
    func getWindowScene() -> UIWindowScene? {
        let window = UIApplication
            .shared
            .connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .last
        
        var windowScene = window?.windowScene
        
        if windowScene != nil {
            return windowScene
        }
        
        windowScene = merchantVC?.view.window?.windowScene
        
        return windowScene
    }
    
    /// Fetches the `loginUri` set by merchant. For internal use only.
    ///
    /// - returns: Nullable String `loginUri`
    func getLoginUri() -> String? {
        return self.loginUri
    }
}


extension Otpless {
    
    @objc public func setLoggerDelegate(delegate: OtplessLoggerDelegate) {
        self.loggerDelegate = delegate
    }
    
    @objc public func getLoggerDelegate() -> OtplessLoggerDelegate? {
        return self.loggerDelegate
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
