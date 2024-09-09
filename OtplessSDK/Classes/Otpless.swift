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
    
    
    /// Initializes the Otpless SDK with the specified app identifier provided by Otpless.
    /// This method must be called from `application(_:didFinishLaunchingWithOptions:)` in the AppDelegate or `scene(_:willConnectTo:options:)` in the SceneDelegate, depending on the app's configuration.
    ///
    /// - Parameter appId: The unique application identifier provided by Otpless.
    ///  Get your appId from https://otpless.com/dashboard/customer/dev-settings/apiKeys
    ///
    /// - Important: This method should be called as early as possible in the app lifecycle to ensure all SDK functionalities are ready when needed.
    @objc public func initialise(appId: String!) {
        self.appId = appId
        
        if #available(iOS 12, *) {
            OtplessSimStateAnalyzer.shared.performAnalysis()
        }
    }
    
    @available(*, deprecated, renamed: "initialiseHeadless(vc:)")
    @objc public func initialise(vc: UIViewController, appId: String) {
        initialiseHeadless(vc: vc)
    }
    
    /// Initializes `OtplessView` with an initializing `HeadlessRequest`.
    /// - Parameter vc: Your `UIViewController` in which you will be implementing Otpless' Headless SDK.
    /// - Important: This function must be called in `viewDidLoad()` of your ViewController for optimized and seamless login experience.
    @objc public func initialiseHeadless(vc: UIViewController) {
        merchantVC = vc
        addHeadlessViewToMerchantVC(headlessRequest: HeadlessRequest.getInitHeadlessRequest())
    }
    
    @available(*, deprecated, renamed: "showOtplessLoginPageWithParams(vc:params:)")
    @objc public func showOtplessLoginPageWithParams(appId: String, vc: UIViewController, params: [String : Any]?){
        showOtplessLoginPageWithParams(vc: vc, params: params)
    }
    
    /// Displays the Otpless' Login Page. To configure your authentication channels or customize Login page, checkout https://otpless.com/dashboard
    /// - Parameters:
    ///   - vc: Your `UIViewController` in which you will be implementing Otpless' Login Page.
    ///   - params: A dictionary containing any additional parameters required for the login process.
    /// - Important: This function requires you to call the `initialize(appId:)` function beforehand to display Login Page correctly.
    @objc public func showOtplessLoginPageWithParams(vc: UIViewController, params: [String : Any]?){
        merchantVC = vc
        initiateLoginPageView(vc: vc, params: params, hideNetworkUi: hideNetworkFailureUserInterface, loginPage: true, hideIndicator: hideActivityIndicator, appid: appId)
    }
    
    /// Starts the Otpless Headless authentication process. To configure your authentication channels, checkout https://otpless.com/dashboard/customer/channels
    /// - Parameter headlessRequest: An object containing the necessary data to initiate the headless authentication.
    /// - Important: This function requires you to call the `initialize(appId:)` and `initializeHeadless(vc:)` beforehand for seamless authentication.
    @objc public func startHeadless(headlessRequest: HeadlessRequest) {
        addHeadlessViewToMerchantVC(headlessRequest: headlessRequest)
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
    
    @objc public func getAppId() -> String {
        return self.appId
    }
    
    /// Determines whether the device is simulator.
    ///
    /// - returns: Boolean indicating whether device is simulator or not. Returns true if the device is simulator, else false.
    @objc public func isDeviceSimulator() -> Bool {
        return DeviceInfoUtils.shared.isDeviceSimulator()
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
    
    public func onResponse(response : OtplessResponse){
        if((Otpless.sharedInstance.delegate) != nil){
            Otpless.sharedInstance.delegate?.onResponse(response: response)
        }
    }
    
    func sendHeadlessResponse(response: HeadlessResponse, closeView: Bool) {
        self.headlessDelegate?.onHeadlessResponse(response: response)
        if closeView && self.otplessView != nil {
            self.otplessView?.removeFromSuperview()
            self.otplessView = nil
        }
    }
    
    // Added to provide user agent when forcefully making request over mobile data instead of wifi.
    func getUserAgent() -> String {
        return self.userAgent
    } 
    
    func setUserAgent(_ agent: String) {
        self.userAgent = agent
    }
    
    internal func isOneTapEnabledForHeadless() -> Bool {
        return self.isOneTapEnabled
    }
    
    func setOtplessViewHeight(heightPercent: Int) {
        otplessView?.setHeight(forHeightPercent: heightPercent)
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
