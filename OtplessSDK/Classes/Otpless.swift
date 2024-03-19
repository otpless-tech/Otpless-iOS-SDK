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
    weak var fabButton: FabButton?
    var floatingButtonHidden = false
    var initialParams: [String : Any]?
    var isLoginPage = false
    @objc public static let sharedInstance: Otpless = {
        let instance = Otpless()
        DeviceInfoUtils.shared.initialise()
        return instance
    }()
    var loader : OtplessLoader? = nil
    private override init(){}
    
    @objc public weak var headlessDelegate: onHeadlessResponseDelegate?
    @objc weak var otplessView: OtplessView?
    private var otplessViewHeight: CGFloat = 0.1
    private var appId = ""
    private var isOneTapEnabled: Bool = true
    
    @objc public func startHeadless(vc: UIViewController, headlessRequest: HeadlessRequest, isOneTapEnabled: Bool = true) {
        merchantVC = vc
        self.appId = headlessRequest.getAppId()
        self.isOneTapEnabled = isOneTapEnabled
        addOtplessViewToVC(headlessRequest: headlessRequest, isOneTapEnabled: isOneTapEnabled)
    }
    
    @objc public func initialise(vc : UIViewController){
        merchantVC = vc
    }
    
    @objc public func start(vc : UIViewController){
        initiateVC(vc: vc, params: nil, hideNetworkUi: hideNetworkFailureUserInterface, loginPage: false, hideIndicator: hideActivityIndicator)
    }
    
    @objc public func startwithParams(vc: UIViewController,params: [String : Any]?){
        
        initiateVC(vc: vc, params: params, hideNetworkUi: hideNetworkFailureUserInterface, loginPage: false , hideIndicator: hideActivityIndicator)
    }
    
    @objc public func showOtplessLoginPage(vc : UIViewController){
        initiateVC(vc: vc, params: nil, hideNetworkUi: hideNetworkFailureUserInterface, loginPage: true , hideIndicator: hideActivityIndicator)
    }
    
    @objc public func showOtplessLoginPageWithParams(vc: UIViewController,params: [String : Any]?){
        
        initiateVC(vc: vc, params: params, hideNetworkUi: hideNetworkFailureUserInterface, loginPage: true , hideIndicator: hideActivityIndicator)
    }
    
    func initiateVC (vc: UIViewController,params: [String : Any]?,hideNetworkUi : Bool, loginPage : Bool, hideIndicator : Bool){
        merchantVC = vc
        isLoginPage = loginPage
        let oVC = OtplessVC()
        oVC.isLoginPage = isLoginPage
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
    
    @objc public func shouldHideButton(hide: Bool){
        floatingButtonHidden = hide
    }
    
    public func addButtonToVC(){
        if floatingButtonHidden {
            if fabButton != nil {
                fabButton?.removeFromSuperview()
                fabButton = nil
            }
        } else {
            if (merchantVC != nil && merchantVC?.view != nil) {
                if fabButton == nil || fabButton?.superview == nil {
                    let vcView = merchantVC?.view
                    DispatchQueue.main.async {
                        if vcView != nil {
                            let button = FabButton(frame: CGRectZero)
                            self.fabButton = button
                            if let view = vcView {
                                if let lastSubview = view.subviews.last {
                                    view.insertSubview(button, aboveSubview: lastSubview)
                                } else {
                                    view.addSubview(button)
                                }
                            }
                            if #available(iOS 11.0, *) {
                                button.translatesAutoresizingMaskIntoConstraints = false
                                NSLayoutConstraint.activate([
                                    button.widthAnchor.constraint(equalToConstant: 100),
                                    button.heightAnchor.constraint(equalToConstant: 40),
                                    button.trailingAnchor.constraint(equalTo: vcView!.safeAreaLayoutGuide.trailingAnchor, constant: -20),
                                    button.bottomAnchor.constraint(equalTo: vcView!.safeAreaLayoutGuide.bottomAnchor, constant: -20)
                                ])
                            } else {
                                let button = FabButton(frame: CGRect(x: (vcView!.frame.width - 100 - 20), y: (vcView!.frame.height - 40 - 40), width: 100, height: 40))
                                self.fabButton = button
                                vcView!.insertSubview(button, aboveSubview: (vcView?.subviews.last)!)
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
    
    @objc public func start(){
        if self.merchantVC != nil {
            let oVC = OtplessVC()
            oVC.isLoginPage = isLoginPage
            otplessVC = oVC
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                self.merchantVC?.present(oVC, animated: true) {
                }
            }
        }
    }
    
    public func signInButtonClicked(){
        if initialParams != nil {
            if self.merchantVC != nil {
                let oVC = OtplessVC()
                oVC.isLoginPage = isLoginPage
                oVC.initialParams = initialParams
                otplessVC = oVC
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.merchantVC?.present(oVC, animated: true) {
                    }
                }
            }
        } else {
            start()
        }
    }
    
    @objc public func processOtplessDeeplink(url : URL) {
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: true), let host = components.host {
            switch host {
            case "otpless":
                if otplessVC != nil {
                    otplessVC?.onDeeplinkRecieved(deeplink: url)
                } else if otplessView != nil {
                    otplessView?.onDeeplinkRecieved(deeplink: url)
                }
                OtplessHelper.sendEvent(event: "intent_redirect_in")
            default:
                break
            }
        }
    }
    
    @objc public func onSignedInComplete(){
        if fabButton != nil {
            fabButton?.removeFromSuperview()
            fabButton = nil
        }
    }
    
    // Call this function to start headless request
    func addOtplessViewToVC(headlessRequest: HeadlessRequest, isOneTapEnabled: Bool) {
        if (merchantVC != nil && merchantVC?.view != nil) {
            if otplessView == nil || otplessView?.superview == nil {
                let vcView = merchantVC?.view
                DispatchQueue.main.async {
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
            self.otplessViewHeight = UIScreen.main.bounds.height
        } else {
            self.otplessViewHeight = (CGFloat(heightPercent) * UIScreen.main.bounds.height) / 100
        }
        
        if otplessView != nil {
            otplessView!.constraints.forEach { (constraint) in
                if constraint.firstAttribute == .height {
                    constraint.constant = self.otplessViewHeight
                }
            }
        }
    }
    
    private func setHeadlessViewConstraints() {
        if let headlessView = otplessView, let vcView = merchantVC?.view {
            headlessView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                headlessView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width),
                headlessView.heightAnchor.constraint(equalToConstant: self.otplessViewHeight),
                headlessView.centerXAnchor.constraint(equalTo: vcView.centerXAnchor),
                headlessView.centerYAnchor.constraint(equalTo: vcView.centerYAnchor)
            ])
        }
    }
    
    @objc public func verifyOTP(otp: String, headlessRequest: HeadlessRequest?) {
        guard let request = headlessRequest else {
            return
        }
        
        request.setOtp(otp: otp)
        addOtplessViewToVC(headlessRequest: request, isOneTapEnabled: isOneTapEnabled)
    }

    @objc public func verifyCode(code: String, headlessRequest: HeadlessRequest?) {
        guard let request = headlessRequest else {
            return
        }
        
        request.setCode(code: code)
        addOtplessViewToVC(headlessRequest: request, isOneTapEnabled: isOneTapEnabled)
    }
    
    @objc public func stopHeadless() {
        self.headlessDelegate = nil
        self.otplessView?.stopHeadless()
        self.otplessView = nil
    }
    
    func sendHeadlessResponse(response: HeadlessResponse, closeView: Bool) {
        self.headlessDelegate?.onHeadlessResponse(response: response)
        if closeView && self.otplessView != nil {
            self.otplessView?.removeFromSuperview()
            self.otplessView = nil
        }
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
