//
//  Otpless.swift
//  OtplessSDK
//
//  Created by Otpless on 05/02/23.
//

import Foundation
import UIKit


@objc final public class Otpless:NSObject {
    
    @objc internal weak var delegate: onResponseDelegate?
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
    @objc internal weak var headlessDelegate: onHeadlessResponseDelegate?
    @objc weak var otplessView: OtplessView?
    private var userAgent = "otplesssdk"
    private weak var loggerDelegate: OtplessLoggerDelegate?
    private var loginUri: String?
    internal var merchantHeadlessRequest: HeadlessRequest?
    private var timeoutInterval: Double = 30.0
    
    /// Initializes `Otpless` for Headless support
    ///
    /// - parameter vc: Instance of your `UIViewController`
    /// - parameter appId: Your `APP_ID` from `Otpless`
    /// - parameter loginUri: Optional String to override the default `loginUri` when a custom deeplink is needed. Ensure the `url scheme` in `info.plist` matches. `Host` of the `loginUri` must  be `otpless`. Eg. "yourscheme://otpless"
    /// - parameter timeoutInterval: It is the request timeout. Once timeout is over, `TIMEOUT` response is sent. Default value is 30 seconds.
    @objc public func initialise(vc : UIViewController, appId: String!, loginUri: String? = nil, timeoutInterval: Double = 30.0){
        merchantVC = vc
        self.appId = appId
        self.loginUri = loginUri
        self.timeoutInterval = timeoutInterval
        
        let initHeadlessRequest = HeadlessRequest()
        initHeadlessRequest.setChannelType("")
        addHeadlessViewToMerchantVC(headlessRequest: initHeadlessRequest)
        
        OtplessHelper.sendEvent(event: EventConstants.INIT_HEADLESS)
    }
    
    @objc public func showOtplessLoginPageWithParams(appId: String!, vc: UIViewController,params: [String : Any]?){
        initiateLoginPageView(vc: vc, params: params, hideNetworkUi: hideNetworkFailureUserInterface, loginPage: true, hideIndicator: hideActivityIndicator, appid: appId)
    }
    
    @objc public func startHeadless(headlessRequest: HeadlessRequest) {
        OtplessHelper.sendEvent(event: EventConstants.START_HEADLESS)
        addHeadlessViewToMerchantVC(headlessRequest: headlessRequest)
    }
    
    private func initiateLoginPageView(vc: UIViewController, params: [String : Any]?, hideNetworkUi : Bool, loginPage : Bool, hideIndicator : Bool, appid: String) {
        appId = appid
        merchantVC = vc
        initialParams = params
        addLoginPageToMerchantVC(appId: appid, hideNetworkUi: hideNetworkUi, hideIndicator: hideIndicator)
        OtplessHelper.sendEvent(event: EventConstants.SHOW_LOGIN_PAGE)
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
    
    @objc public func isWhatsappInstalled() -> Bool{
        if UIApplication.shared.canOpenURL(URL(string: "whatsapp://")! as URL) {
            return true
        } else {
            return false
        }
    }
    
    @objc public func isOtplessDeeplink(url : URL) -> Bool{
        if let GoogleAuthClass = NSClassFromString("OtplessSDK.OtplessGIDSignIn") as? NSObject.Type {
            let googleAuthHandler = GoogleAuthClass.init()
            if let handler = googleAuthHandler as? GoogleAuthProtocol {
                let isGIDDeeplink = handler.isGIDDeeplink(url: url)
                if isGIDDeeplink {
                    return true
                }
            }
        }
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
        self.merchantHeadlessRequest = headlessRequest
        if (merchantVC != nil && merchantVC?.view != nil) {
            if otplessView == nil || otplessView?.superview == nil {
                let vcView = merchantVC?.view
                DispatchQueue.main.async {
                    if vcView != nil {
                        
                        var headlessView: OtplessView
                        headlessView = OtplessView(headlessRequest: headlessRequest)
                        self.otplessView = headlessView
                        
                        OtplessHelper.sendEvent(event: EventConstants.REQUEST_PUSHED_WEB)
                        
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
                self.otplessView?.sendHeadlessRequestToWeb(request: headlessRequest, startTimer: {
                    RequestTimer.shared.startTimer(interval: self.timeoutInterval, onTimeout: {
                        self.stopOtplessAndSendTimeoutError()
                    })
                })
                OtplessHelper.sendEvent(event: EventConstants.REQUEST_PUSHED_WEB)
            }
        }
    }
    
    func sendHeadlessResponse(response: HeadlessResponse, closeView: Bool, sendWebResponseEvent: Bool) {
        RequestTimer.shared.cancelTimer()
        if sendWebResponseEvent {
            response.toEventDict(onDictCreate: { dict, musId, requestId in
                OtplessHelper.sendEvent(event: EventConstants.HEADLESS_RESPONSE_WEB, extras: dict, musId: musId, requestId: requestId)
            })
        }
        self.headlessDelegate?.onHeadlessResponse(response: response)
        if closeView && self.otplessView != nil {
            OtplessHelper.sendEvent(event: EventConstants.CLOSE_VIEW)
            self.otplessView?.removeFromSuperview()
            self.otplessView = nil
        }
    }
    
    @objc public func dismissOtplessView() {
        self.otplessView?.stopOtpless(dueToNoInternet: false)
        self.otplessView = nil
    }
    
    @available(*, deprecated, message: "This method will be removed in a future version of SDK. To verify OTP, use 'HeadlessRequest.setOtp()' method (make sure phone number and country code are also set) and pass the instance in 'Otpless.startHeadless()' method. For more information, please check the iOS integration documentation at https://otpless.com/docs/frontend-sdks/app-sdks/ios/headless.")
    @objc public func verifyOTP(otp: String, headlessRequest: HeadlessRequest?) {
        guard let request = headlessRequest else {
            return
        }
        
        request.setOtp(otp: otp)
        otplessView?.sendHeadlessRequestToWeb(request: request, startTimer: {
            RequestTimer.shared.startTimer(interval: self.timeoutInterval, onTimeout: {
                self.stopOtplessAndSendTimeoutError()
            })
        })
        OtplessHelper.sendEvent(event: EventConstants.START_HEADLESS)
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
    
    /// Registers the application to use Facebook Login.
    @objc public func registerFBApp(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) {
        if let FacebookAuthClass = NSClassFromString("OtplessSDK.OtplessFBSignIn") as? NSObject.Type {
            let facebookAuthHandler = FacebookAuthClass.init()
            if let handler = facebookAuthHandler as? FacebookAuthProtocol {
                handler.register(application, didFinishLaunchingWithOptions: launchOptions)
            }
        }
    }
    
    /// Registers the application to use Facebook Login. To be called from `AppDelegate`
    @objc public func registerFBApp(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) {
        if let FacebookAuthClass = NSClassFromString("OtplessSDK.OtplessFBSignIn") as? NSObject.Type {
            let facebookAuthHandler = FacebookAuthClass.init()
            if let handler = facebookAuthHandler as? FacebookAuthProtocol {
                handler.register(app, open: url, options: options)
            }
        }
    }
    
    /// Registers the application to use Facebook Login. To be called from `SceneDelegate`
    @available(iOS 13.0, *)
    @objc public func registerFBApp(
        openURLContexts URLContexts: Set<UIOpenURLContext>
    ) {
        if let FacebookAuthClass = NSClassFromString("OtplessSDK.OtplessFBSignIn") as? NSObject.Type {
            let facebookAuthHandler = FacebookAuthClass.init()
            if let handler = facebookAuthHandler as? FacebookAuthProtocol {
                handler.register(openURLContexts: URLContexts)
            }
        }
    }
    
    @objc public func setLoginPageDelegate(_ delegate: onResponseDelegate) {
        self.delegate = delegate
        OtplessHelper.sendEvent(event: EventConstants.SET_LOGIN_PAGE_CALLBACK)
    }
    
    @objc public func setHeadlessResponseDelegate(_ headlessResponseDelegate: onHeadlessResponseDelegate) {
        self.headlessDelegate = headlessResponseDelegate
        OtplessHelper.sendEvent(event: EventConstants.SET_HEADLESS_CALLBACK)
    }
    
    @objc public func commitHeadlessResponse(headlessResponse: HeadlessResponse?) {
        var eventParams: [String: String] = [:]
        
        if let response = headlessResponse {
            response.toEventDict(onDictCreate: { response, musId, requestId in
                eventParams["response"] = Utils.convertDictionaryToString(response)
                OtplessHelper.sendEvent(
                    event: EventConstants.HEADLESS_MERCHANT_COMMIT,
                    extras: response,
                    musId: musId,
                    requestId: requestId
                )
            })
        } else {
            OtplessHelper.sendEvent(event: EventConstants.HEADLESS_MERCHANT_COMMIT, extras: [:], musId: "", requestId: "")
        }
    }
    
    internal func stopOtplessAndSendTimeoutError(shouldSendEvent: Bool = true) {
        var responseType = "INITIATE"
        if merchantHeadlessRequest?.isVerifyRequest() == true {
            responseType = "VERIFY"
        }
        let errorCode = 5005
        let errorMessage = "Request timeout"
        
        sendHeadlessResponse(
            response: HeadlessResponse(
                responseType: responseType,
                responseData: [
                    "errorMessage": errorMessage,
                    "errorCode": String(errorCode)
                ],
                statusCode: errorCode
            ),
            closeView: true,
            sendWebResponseEvent: false
        )
        
        if shouldSendEvent {
            OtplessHelper.sendEvent(event: EventConstants.HEADLESS_TIMEOUT)
        }
    }
    
    internal func stopOtplessAndSendEmptyResponseError() {
        var responseType = "INITIATE"
        if merchantHeadlessRequest?.isVerifyRequest() == true {
            responseType = "VERIFY"
        }
        let errorCode = 5006
        let errorMessage = "Failed to fetch response"
        
        sendHeadlessResponse(
            response: HeadlessResponse(
                responseType: responseType,
                responseData: [
                    "errorMessage": errorMessage,
                    "errorCode": String(errorCode)
                ],
                statusCode: errorCode
            ),
            closeView: true,
            sendWebResponseEvent: false
        )
        
        OtplessHelper.sendEvent(event: EventConstants.HEADLESS_EMPTY_RESPONSE_WEB)
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
