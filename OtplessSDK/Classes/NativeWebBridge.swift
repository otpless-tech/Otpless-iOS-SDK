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
                if let key = dataDict?["infoKey"] as? String{
                    if let value =  dataDict?["infoValue"] as? String{
                        OtplessHelper.setValue(value: key, forKey: value)
                    }
                }
                break
            case 5:
                // get string
                if let key = dataDict?["infoKey"] as? String{
                    let value : String? = OtplessHelper.getValue(forKey: key)
                    if value != nil {
                        var params = [String: String]()
                        params[key] = value
                        do {
                            let jsonData = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
                            if let jsonStr = String(data: jsonData, encoding: .utf8) as String? {
                                let tempScript = "onStorageValueSuccess(" + jsonStr + ")"
                                let script = tempScript.replacingOccurrences(of: "\n", with: "")
                                callJs(webview: webView, script: script)
                            }
                        } catch {

                        }
                    } else {
                        do {
                            var params = [String: String]()
                            params[key] = ""
                            let jsonData = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
                            if let jsonStr = String(data: jsonData, encoding: .utf8) as String? {
                                let tempScript = "onStorageValueSuccess(" + jsonStr + ")"
                                let script = tempScript.replacingOccurrences(of: "\n", with: "")
                                callJs(webview: webView, script: script)
                            }
                        } catch {
                        
                        }
                    }
                    //onStorageValueSuccess
                }
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
                    var parametersToSend =  DeviceInfoUtils.shared.getAppInfo()
                    parametersToSend["appSignature"] = DeviceInfoUtils.shared.appHash
                    let jsonData = try JSONSerialization.data(withJSONObject: parametersToSend, options: .prettyPrinted)
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
                    var responseParams =  [String : Any]()
                    responseParams["data"] = response
                    let otplessResponse = OtplessResponse(responseString: nil, responseData: responseParams)
                    Otpless.sharedInstance.delegate?.onResponse(response: otplessResponse)
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
                    let otplessResponse = OtplessResponse(responseString: "user cancelled.", responseData: nil)
                    Otpless.sharedInstance.delegate?.onResponse(response: otplessResponse)
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
