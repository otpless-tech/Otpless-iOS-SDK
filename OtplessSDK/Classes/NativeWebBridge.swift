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
    public weak var delegate: BridgeDelegate?
    public weak var headlessRequest: HeadlessRequest? = nil
    
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
                    
                }
                break
            case 11:
                // verification status call key 11
                if let response = dataDict?["response"] as? [String: Any] {
                    var responseParams =  [String : Any]()
                    responseParams["data"] = response
                    let otplessResponse = OtplessResponse(responseString: nil, responseData: responseParams)
                    Otpless.sharedInstance.delegate?.onResponse(response: otplessResponse)
                    delegate?.dismissView()
                    OtplessHelper.sendEvent(event: "auth_completed")
                }
                break
            case 12:
                // change the height of web view
                if let heightPercent = dataDict?["heightPercent"] as? Int {
                    Otpless.sharedInstance.setOtplessViewHeight(heightPercent: heightPercent)
                }
                break
            case 13:
                // extra params
                do {
                    if let headlessRequest = headlessRequest {
                        let extraParams = headlessRequest.makeJson()
                        
                        let jsonData = try JSONSerialization.data(withJSONObject: extraParams, options: .prettyPrinted)
                        
                        if let jsonStr = String(data: jsonData, encoding: .utf8) as String? {
                            let tempScript = "onExtraParamResult(" + jsonStr + ")"
                            let script = tempScript.replacingOccurrences(of: "\n", with: "")
                            callJs(webview: webView, script: script)
                        }
                    } else {
                        let extraParams = [String: Any]()
                        
                        let jsonData = try JSONSerialization.data(withJSONObject: extraParams, options: .prettyPrinted)
                        
                        if let jsonStr = String(data: jsonData, encoding: .utf8) as String? {
                            let tempScript = "onExtraParamResult(" + jsonStr + ")"
                            let script = tempScript.replacingOccurrences(of: "\n", with: "")
                            callJs(webview: webView, script: script)
                        }
                    }
                }  catch {
                    
                }
                break
            case 14:
                // close
                if delegate != nil {
                    let otplessResponse = OtplessResponse(responseString: "user cancelled.", responseData: nil)
                    Otpless.sharedInstance.delegate?.onResponse(response: otplessResponse)
                    delegate?.dismissView()
                    OtplessHelper.sendEvent(event: "user_abort")
                }
                break
            case 15:
                // send event
                break

            case 20:
                // send headless request to web
                sendHeadlessRequestToWeb()
                break
            case 21:
                // send headless response
                guard let dataDict = dataDict else {
                    return
                }
                
                let responseStr = dataDict["response"] as? String ?? ""
                let responseDict = Utils.convertToDictionary(text: responseStr)
                let closeView = dataDict["closeView"] as? Int == 1
                let responseType = responseDict?["responseType"] as? String ?? ""
                
                let statusCode = responseDict?["statusCode"] as? Int ?? 0
                let resp = (responseDict?["response"] as? [String: Any])
                
                let headlessResponse = HeadlessResponse(
                    responseType: responseType,
                    responseData: resp,
                    statusCode: statusCode
                )
                
                Otpless.sharedInstance.sendHeadlessResponse(response: headlessResponse, closeView: closeView)
                
                if containsIdentity(responseDict) {
                    OtplessHelper.sendEvent(event: "auth_completed")
                }
                
                break
            case 42:
                // perform silent auth
                let url = dataDict?["url"] as? String ?? ""
                
                let connectionUrl = URL(string: url)
                print("Connection url - \(connectionUrl)")
                if connectionUrl != nil {
                    forceOpenURLOverMobileNetwork(
                        url: connectionUrl!,
                        completion: { silentAuthResponse in
                            print("Silent auth response - \(silentAuthResponse)")
                            do {
                                let jsonData = try JSONSerialization.data(withJSONObject: silentAuthResponse, options: .prettyPrinted)
                                if let jsonStr = String(data: jsonData, encoding: .utf8) as String? {
                                    let tempScript = "onCellularNetworkResult(" + jsonStr + ")"
                                    let script = tempScript.replacingOccurrences(of: "\n", with: "")
                                    self.callJs(webview: self.webView, script: script)
                                }
                            } catch {
                                
                            }
                        }
                    )
                } else {
                    // handle case when unable to create URL from string
                }
                
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

    
    func setHeadlessRequest(headlessRequest: HeadlessRequest?, webview: WKWebView) {
        self.headlessRequest = headlessRequest
        if self.webView == nil {
            self.webView = webview
        }
    }
    
    func sendHeadlessRequestToWeb(withCode code: String = "") {
        do {
            var requestData: [String: Any] = [:]
            
            if !code.isEmpty {
                // Send only code in request to verify it and get details
                requestData["code"] = code
            } else if let request = headlessRequest {
                requestData = request.makeJson()
            }
            
            let jsonData = try JSONSerialization.data(withJSONObject: requestData, options: .prettyPrinted)
            if let jsonStr = String(data: jsonData, encoding: .utf8)?.replacingOccurrences(of: "\n", with: "") {
                let script = "headlessRequest(\(jsonStr))"
                if let webView = webView {
                    callJs(webview: webView, script: script)
                }
            }
        } catch {
            
        }
    }

    private func containsIdentity(_ response: [String: Any]?) -> Bool {
        guard let response = response else {
            return false
        }
        
        if let responseData = response["response"] as? [String: Any],
           let identities = responseData["identities"] as? [[String: Any]] {
            return !identities.isEmpty
        }
        
        return false
    }
}

// Implement this protocol to recieve waid in your view controller class when using WhatsappLoginButton
public protocol BridgeDelegate: AnyObject {
    func showLoader()
    func hideLoader()
    func dismissView()
}

extension NativeWebBridge {
    func forceOpenURLOverMobileNetwork(url: URL, completion: @escaping ([String: Any]) -> Void) {
        if #available(iOS 12.0, *) {
            let cellularConnectionManager = CellularConnectionManager()
            cellularConnectionManager.open(url: url, operators: nil, completion: completion)
        }
    }
}
