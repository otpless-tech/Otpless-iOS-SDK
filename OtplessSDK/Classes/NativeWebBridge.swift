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
    
    private  var deeplink = ""
    private var JAVASCRIPT_SCR = "javascript: "
    private var webView: WKWebView! = nil
    private var navController: UINavigationController! = nil
    private weak var mVC: UIViewController?
    public weak var delegate: BridgeDelegate?
    
    
    func parseScriptMessage(message: WKScriptMessage,webview : WKWebView){
        if webview != nil {
            webView = webview
        } else {
            return
        }
        if let jsonStringFromWeb = message.body as? String {
            print("CALLBACK ------> \(jsonStringFromWeb)")
            let dataDict = Utils.convertToDictionary(text: jsonStringFromWeb)
            var nativeKey = 0
            if let key = dataDict?["key"] as? String {
                nativeKey = Int(key)!
            } else {
                if let key = dataDict?["key"] as? Int {
                    nativeKey = key
                }
            }
            
            switch nativeKey {
            case 1:
                //show loader
                if delegate != nil {
                    delegate?.showLoader()
                }
                break
            case 2:
                // hide loader
                if delegate != nil {
                    delegate?.hideLoader()
                }
                break
            case 3:
                // back button subscribe
                break
            case 4:
                // save string
                break
            case 5:
                // get string
                break
            case 7:
                // open deeplink
                if let url = dataDict?["deeplink"] as? String {
                    OtplessHelper.sendEvent(event: "intent_redirect_out")
                    let urlWithOutDecoding = url.removingPercentEncoding
                    if let link = URL(string: (urlWithOutDecoding!.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed))!) {
                        UIApplication.shared.open(link, options: [:], completionHandler: nil)
                    }
                }
                break
            case 8:
                // get app info
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: DeviceInfoUtils.shared.getAppInfo(), options: .prettyPrinted)
                    if let jsonStr = String(data: jsonData, encoding: .utf8) as String? {
                        let tempScript = "onAppInfoResult(" + jsonStr + ")"
                        let script = tempScript.replacingOccurrences(of: "\n", with: "")
                        callJs(webview: webView, script: script)
                    }
                } catch {
                    print(error.localizedDescription)
                }
                break
            case 11:
                // verification status call key 11
                if let response = dataDict?["response"] as? [String: Any] {
                    Otpless.sharedInstance.delegate?.onResponse(response: response)
                    delegate?.dismissVC()
                    OtplessHelper.sendEvent(event: "auth_completed")
                }
                break
            case 12:
                // change the height of web view
                break
            case 13:
                // extra params
                break
            case 14:
                // close
                if delegate != nil {
                    delegate?.dismissVC()
                    OtplessHelper.sendEvent(event: "user_abort")
                }
                break
            case 15:
                // send event
                break
            default:
                return
            }
        }
    }
    
    func callJs(webview: WKWebView, script: String) {
        DispatchQueue.main.async {
            webview.evaluateJavaScript(script, completionHandler: nil)
        }
    }
    
    func setVC(vc:UIViewController){
        mVC = vc
    }
}

// Implement this protocol to recieve waid in your view controller class when using WhatsappLoginButton
public protocol BridgeDelegate: AnyObject {
    func showLoader()
    func hideLoader()
    func dismissVC()
}
