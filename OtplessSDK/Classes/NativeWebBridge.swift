//
//  NativeWebBridge.swift
//  OTPless
//
//  Created by Anubhav Mathur on 15/05/23.
//

import Foundation
import UIKit
import WebKit


class NativeWebBridge {
    private var webView: WKWebView! = nil
    public weak var delegate: BridgeDelegate?
    public weak var headlessRequest: HeadlessRequest? = nil
    private var otplessWebManager: OtplessWebListener?
    
    func parseScriptMessage(message: WKScriptMessage, webview : WKWebView){
        otplessWebManager = OtplessWebListenerImpl(webView: webview)
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
            
            guard let otplessWebManager = otplessWebManager else {
                return
            }
            
            switch nativeKey {
            case 1:
                //show loader
                otplessWebManager.showLoader(usingDelegate: delegate)
                break
            case 2:
                // hide loader
                otplessWebManager.hideLoader(usingDelegate: delegate)
                break
            case 3:
                // back button subscribe
                break
            case 4:
                // save string
                if let key = dataDict?["infoKey"] as? String{
                    if let value =  dataDict?["infoValue"] as? String{
                        otplessWebManager.saveString(forKey: key, value: value)
                    }
                }
                break
            case 5:
                // get string
                if let key = dataDict?["infoKey"] as? String{
                    otplessWebManager.getString(forKey: key)
                }
                break
            case 7:
                // open deeplink
                if let url = dataDict?["deeplink"] as? String {
                    otplessWebManager.openDeepLink(url)
                }
                break
            case 8:
                // get app info
                otplessWebManager.getAppInfo()
                break
            case 11:
                // verification status call key 11
                if let response = dataDict?["response"] as? [String: Any] {
                    otplessWebManager.responseVerificationStatus(forResponse: response, delegate: delegate)
                }
                break
            case 12:
                // change the height of web view
                if let heightPercent = dataDict?["heightPercent"] as? Int {
                    otplessWebManager.changeWebViewHeight(withHeightPercent: heightPercent)
                }
                break
            case 13:
                // extra params
                otplessWebManager.getExtraParams(fromHeadlessRequest: self.headlessRequest)
                break
            case 14:
                // close
                otplessWebManager.onCloseWebView(delegate: delegate)
                break
            case 15:
                // send event
                break

            case 20:
                // send headless request to web
                otplessWebManager.sendHeadlessRequestToWeb(self.headlessRequest, withCode: "")
                break
            case 21:
                // send headless response
                guard let dataDict = dataDict else {
                    return
                }
                otplessWebManager.sendHeadlessResponse(dataDict)
                break
            case 26:
                // initialize WebAuthn registration
                let webAuthnRequest = dataDict?["request"] as? [String: Any]
                otplessWebManager.initiateWebAuthnRegistration(withRequest: webAuthnRequest)
                break
            case 27:
                // initialize WebAuthn sign in
                let webAuthnRequest = dataDict?["request"] as? [String: Any]
                otplessWebManager.initiateWebAuthnSignIn(withRequest: webAuthnRequest)
                break
            case 28:
                // check WebAuthn availability
                otplessWebManager.checkWebAuthnAvailability()
                break
            case 42:
                // perform silent auth
                let url = dataDict?["url"] as? String ?? ""
                let connectionUrl = URL(string: url)
                otplessWebManager.performSilentAuth(withConnectionUrl: connectionUrl)
                break

            default:
                return
            }
        }
    }
    
    func setHeadlessRequest(headlessRequest: HeadlessRequest?, webview: WKWebView) {
        self.headlessRequest = headlessRequest
        if self.webView == nil {
            self.webView = webview
        }
    }
    
    func sendHeadlessRequestToWeb(withCode code: String = "") {
        if !code.isEmpty {
            // Send only code in request to verify it and get details
            self.otplessWebManager?.sendHeadlessRequestToWeb(nil, withCode: code)
        } else if let request = headlessRequest {
            self.otplessWebManager?.sendHeadlessRequestToWeb(request, withCode: "")
        }
    }
}

// Implement this protocol to recieve waid in your view controller class when using WhatsappLoginButton
public protocol BridgeDelegate: AnyObject {
    func showLoader()
    func hideLoader()
    func dismissView()
}
