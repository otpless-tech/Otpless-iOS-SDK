//
//  Otpless.swift
//  OtplessSDK
//
//  Created by Otpless on 05/02/23.
//

import Foundation


@objc final public class Otpless:NSObject {
    
    @objc public weak var delegate: onResponseDelegate?
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
    
    @objc public func initialise(vc : UIViewController){
        merchantVC = vc
    }
    
    @objc public func start(vc : UIViewController){
        merchantVC = vc
        isLoginPage = false
        let oVC = OtplessVC()
        oVC.isLoginPage = isLoginPage
        otplessVC = oVC
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            vc.present(oVC, animated: true) {
            }
        }
    }
    
    @objc public func startwithParams(vc: UIViewController,params: [String : Any]?){
        
        merchantVC = vc
        isLoginPage = false
        let oVC = OtplessVC()
        oVC.isLoginPage = isLoginPage
        initialParams = params
        oVC.initialParams = params
        otplessVC = oVC
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            vc.present(oVC, animated: true) {
            }
        }
    }
    
    @objc public func showOtplessLoginPage(vc : UIViewController){
        merchantVC = vc
        isLoginPage = true
        let oVC = OtplessVC()
        oVC.isLoginPage = isLoginPage
        otplessVC = oVC
        oVC.isLoginPage = isLoginPage
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            vc.present(oVC, animated: true) {
            }
        }
    }
    
    @objc public func showOtplessLoginPageWithParams(vc: UIViewController,params: [String : Any]?){
        
        merchantVC = vc
        let oVC = OtplessVC()
        initialParams = params
        oVC.initialParams = params
        oVC.isLoginPage = isLoginPage
        otplessVC = oVC
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            vc.present(oVC, animated: true) {
            }
        }
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
                            vcView!.insertSubview(button, aboveSubview: (vcView?.subviews.last)!)
                            // Set constraints to position your view inside the safe area layout guide
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
                    OtplessHelper.sendEvent(event: "intent_redirect_in")
                }
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
}


@objc public protocol onResponseDelegate: AnyObject {
    @objc func onResponse(response: OtplessResponse?)
}

