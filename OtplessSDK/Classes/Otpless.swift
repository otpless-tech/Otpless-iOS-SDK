//
//  Otpless.swift
//  OtplessSDK
//
//  Created by Otpless on 05/02/23.
//

import Foundation


public class Otpless {
    
    public weak var delegate: onResponseDelegate?
    weak var otplessVC: OtplessVC?
    weak var merchantVC: UIViewController?
    weak var fabButton: FabButton?
    var floatingButtonHidden = false
    public static let sharedInstance: Otpless = {
        let instance = Otpless()
        return instance
    }()
    var loader : OtplessLoader? = nil
    private init(){}
    
    public func initialise(vc : UIViewController){
        merchantVC = vc
    }
    
    public func start(vc : UIViewController){
        merchantVC = vc
        let oVC = OtplessVC()
        otplessVC = oVC
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            vc.present(oVC, animated: true) {
            }
        }
    }
    
    public func shouldHideButton(hide: Bool){
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
    
    public func onResponse(response: [String:String]){
        if((Otpless.sharedInstance.delegate) != nil){
            Otpless.sharedInstance.delegate?.onResponse(response: response)
        }
    }
    
    public func isWhatsappInstalled() -> Bool{
        if UIApplication.shared.canOpenURL(URL(string: "whatsapp://app")! as URL) {
            return true
        } else {
            return false
        }
    }
    
    public func isOtplessDeeplink(url : URL) -> Bool{
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
    
    public func start(){
        if self.merchantVC != nil {
            let oVC = OtplessVC()
            otplessVC = oVC
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                self.merchantVC?.present(oVC, animated: true) {
                }
            }
        }
    }
    
    public func processOtplessDeeplink(url : URL) {
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

// When you want to do direct integration in which you will not be using WhatsappLoginButton
public protocol onResponseDelegate: AnyObject {
    func onResponse(response: [String: Any]?)
}

