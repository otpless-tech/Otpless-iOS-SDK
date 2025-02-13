//
//  NativeWebBridge.swift
//  OTPless
//
//  Created by Anubhav Mathur on 15/05/23.
//

import Foundation
import UIKit
import WebKit
import SafariServices


@objc class NativeWebBridge: NSObject {
    internal var webView: WKWebView! = nil
    public weak var delegate: BridgeDelegate?
    public var headlessRequest: HeadlessRequest? = nil
    var otplessWebAuthn: OtplessWebAuthn?
    internal var otplessSFSafariVC: SFSafariViewController?
    
    func parseScriptMessage(message: WKScriptMessage, webview : WKWebView){
        webView = webview
        
        if let jsonStringFromWeb = message.body as? String {
            let dataDict = Utils.convertToDictionary(text: jsonStringFromWeb)
            var nativeKey = 0
            if let key = dataDict?["key"] as? String {
                nativeKey = Int(key)!
            } else {
                if let key = dataDict?["key"] as? Int {
                    nativeKey = key
                }
            }
            
            OtplessLogger.log(dictionary: dataDict ?? [:], type: "Data from web")
            
            switch nativeKey {
            case 1:
                //show loader
                self.showLoader(usingDelegate: delegate)
                break
            case 2:
                // hide loader
                self.hideLoader(usingDelegate: delegate)
                break
            case 3:
                // back button subscribe
                break
            case 4:
                // save string
                if let key = dataDict?["infoKey"] as? String{
                    if let value =  dataDict?["infoValue"] as? String{
                        self.saveString(forKey: key, value: value)
                    }
                }
                break
            case 5:
                // get string
                if let key = dataDict?["infoKey"] as? String{
                    self.getString(forKey: key)
                }
                break
            case 7:
                // open deeplink
                if let url = dataDict?["deeplink"] as? String {
                    self.openDeepLink(url)
                }
                break
            case 8:
                // get app info
                self.getAppInfo()
                break
            case 11:
                // verification status call key 11
                if let response = dataDict?["response"] as? [String: Any] {
                    self.responseVerificationStatus(forResponse: response, delegate: delegate)
                }
                break
            case 12:
                // change the height of web view
                if let heightPercent = dataDict?["heightPercent"] as? Int {
                    self.changeWebViewHeight(withHeightPercent: heightPercent)
                }
                break
            case 13:
                // extra params
                self.getExtraParams(from: self.headlessRequest)
                break
            case 14:
                // close
                self.onCloseWebView()
                break
            case 15:
                // send event
                break

            case 20:
                // send headless request to web
                self.sendHeadlessRequestToWeb(self.headlessRequest, withCode: "")
                break
            case 21:
                // send headless response
                guard let dataDict = dataDict else {
                    return
                }
                self.sendHeadlessResponse(dataDict)
                break
            case 26:
                // initialize WebAuthn registration
                let webAuthnRequest = dataDict?["request"] as? [String: Any]
                self.initiateWebAuthnRegistration(withRequest: webAuthnRequest)
                break
            case 27:
                // initialize WebAuthn sign in
                let webAuthnRequest = dataDict?["request"] as? [String: Any]
                self.initiateWebAuthnSignIn(withRequest: webAuthnRequest)
                break
            case 28:
                // check WebAuthn availability
                self.checkWebAuthnAvailability()
                break
            case 42:
                // perform silent auth
                let url = dataDict?["url"] as? String ?? ""
                let connectionUrl = URL(string: url)
                self.performSilentAuth(withConnectionUrl: connectionUrl)
                break
                
            case 43:
                let urls = dataDict?["urls"] as? [String] ?? []
                self.warmupURLCache(forURLs: urls)
                break
                
            case 56:
                // Perform google/fb sdk login
                let req = dataDict?["request"] as? [String: Any]
                let channel = req?["channel"] as? String ?? ""
                let data = req?["data"] as? [String: Any] ?? [:]
                self.useNativeSDKToAuthenticateUser(channel: channel, data: data)
                break
            case 57:
                let req = dataDict?["request"] as? [String: Any]
                let channel = req?["channel"] as? String ?? ""
                self.logoutUserFromSDK(channel: channel)
            default:
                return
            }
        }
    }
}


extension NativeWebBridge {
    func setHeadlessRequest(headlessRequest: HeadlessRequest?, webview: WKWebView) {
        self.headlessRequest = headlessRequest
        if self.webView == nil {
            self.webView = webview
        }
    }
    
    func sendHeadlessRequestToWeb(withCode code: String = "") {
        OtplessHelper.sendEvent(event: EventConstants.HEADLESS_REQUEST_QUERY_WEB)
        if !code.isEmpty {
            // Send only code in request to verify it and get details
            self.sendHeadlessRequestToWeb(nil, withCode: code)
        } else if let request = headlessRequest {
            self.sendHeadlessRequestToWeb(request, withCode: "")
        }
    }
}

extension NativeWebBridge: SFSafariViewControllerDelegate, UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        otplessSFSafariVC = nil
      }
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        otplessSFSafariVC = nil
    }
    
    func dismissOtplessSFSafariVC() {
        if otplessSFSafariVC != nil {
            otplessSFSafariVC?.dismiss(animated: true) { [weak self] in
                self?.otplessSFSafariVC = nil
            }
        }
    }
}

// Implement this protocol to recieve waid in your view controller class when using WhatsappLoginButton
public protocol BridgeDelegate: AnyObject {
    func showLoader()
    func hideLoader()
    func dismissView()
}

protocol GoogleAuthProtocol {
    func signIn(
        vc: UIViewController,
        withHint hint: String?,
        shouldAddAdditionalScopes additionalScopes: [String]?,
        withNonce nonce: String?,
        onSignIn: @escaping ([String: Any]) -> Void
    )
    
    func isGIDDeeplink(url: URL) -> Bool
}

protocol FacebookAuthProtocol {
    func startFBSignIn(
        withNonce nonce: String,
        withPermissions permissions: [String],
        onSignIn: @escaping ([String: Any]) -> Void
    )
    
    func logoutFBUser()
    
    func register(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any]
    )
    
    @available(iOS 13.0, *)
    func register(
        openURLContexts URLContexts: Set<UIOpenURLContext>
    )
    
    func register(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    )
}
