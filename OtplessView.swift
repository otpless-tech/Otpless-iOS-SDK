//
//  OtplessView.swift
//  OtplessSDK
//
//  Created by Sparsh on 12/02/24.
//

import UIKit
import WebKit

class OtplessView: UIView {
    
    let JAVASCRIPT_OBJ = "window.webkit.messageHandlers"
    let messageName = "webNativeAssist"
    var mWebView: WKWebView!
    var bridge: NativeWebBridge = NativeWebBridge()
    var startUri = "https://otpless.com/appid/"
    var finalDeeplinkUri: URL?
    var initialParams : [String: Any]?
    var headlessRequest: HeadlessRequest?
    var appId = ""
    var isOneTapEnabled: Bool = true

    init(headlessRequest: HeadlessRequest, isOneTapEnabled: Bool) {
        super.init(frame: CGRectZero)
        self.headlessRequest = headlessRequest
        self.appId = headlessRequest.getAppId()
        startUri += appId
        self.isOneTapEnabled = isOneTapEnabled
        setupOtplessView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupOtplessView()
    }
    
    func setupOtplessView() {
        initializeWebView()

        if #available(iOS 16.4, *) {
            self.mWebView.isInspectable = true
        } else {
            // Fallback on earlier versions
        }
        
        bridge.delegate = self
        bridge.setHeadlessRequest(headlessRequest: headlessRequest, webview: mWebView)
        
        clearWebViewCache()
        prepareUrlLoadWebview(startUrl: startUri)
        OtplessHelper.sendEvent(event: "sdk_screen_loaded")
    }
    
    func sendHeadlessRequestToWeb(request: HeadlessRequest) {
        bridge.setHeadlessRequest(headlessRequest: request, webview: mWebView)
        bridge.sendHeadlessRequestToWeb()
    }
    
    private func initializeWebView() {
        mWebView = WKWebView(frame: bounds, configuration: getWKWebViewConfiguration())
        mWebView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mWebView.backgroundColor = UIColor.clear
        addSubview(mWebView)
    }
    
    public func getWKWebViewConfiguration() -> WKWebViewConfiguration {
        let contentController = WKUserContentController()
        let scriptSource1 = "javascript: window.androidObj = function AndroidClass() { };"
        let scriptSource = "javascript: " +
        "window.androidObj.webNativeAssist = function(message) { " + JAVASCRIPT_OBJ + ".webNativeAssist.postMessage(message) }"
        let zoomDisableJs: String = "var meta = document.createElement('meta');" +
        "meta.name = 'viewport';" +
        "meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';" +
        "var head = document.getElementsByTagName('head')[0];" +
        "head.appendChild(meta);"
        let script1: WKUserScript = WKUserScript(source: scriptSource1, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let script: WKUserScript = WKUserScript(source: scriptSource, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let disableZoomScript = WKUserScript(source: zoomDisableJs, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        contentController.addUserScript(script1)
        contentController.addUserScript(script)
        contentController.addUserScript(disableZoomScript)
        contentController.add(self, name: messageName)
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        return config
    }
    
    func clearWebViewCache() {
        do {
            if #available(iOS 9.0, *) {
                let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
                let date = Date(timeIntervalSince1970: 0)
                WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes as! Set<String>, modifiedSince: date, completionHandler: {})
            } else {
                // Clear cache for earlier versions of iOS
                let libraryPath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first!
                let cookiesFolderPath = "\(libraryPath)/Cookies"
                do {
                    try FileManager.default.removeItem(atPath: cookiesFolderPath)
                } catch {
                    
                }
            }
        }
    }
    
    func prepareUrlLoadWebview(startUrl: String){
        self.mWebView.evaluateJavaScript("navigator.userAgent") { [weak self] (result, error) in
            guard let self = self else { return }
            
            if let currentUserAgent = result as? String {
                // Append the custom User-Agent
                let customUserAgent = "\(currentUserAgent) otplesssdk"
                
                // Set the modified User-Agent
                mWebView.customUserAgent = customUserAgent
                
                // Load a webpage
                var urlComponents = URLComponents(string: startUrl)!
                if let bundleIdentifier = Bundle.main.bundleIdentifier {
                    let queryItem = URLQueryItem(name: "package", value: bundleIdentifier)
                    let queryItemloginuri = URLQueryItem(name: "login_uri", value: bundleIdentifier + ".otpless://otpless")
                    if urlComponents.queryItems != nil {
                        urlComponents.queryItems?.append(queryItem)
                        urlComponents.queryItems?.append(queryItemloginuri)
                    } else {
                        urlComponents.queryItems = [queryItem]
                        urlComponents.queryItems?.append(queryItemloginuri)
                    }
                }
                
                let queryItem = URLQueryItem(name: "hasWhatsapp", value: DeviceInfoUtils.shared.hasWhatsApp ? "true" : "false" )
                let queryItemOtpless = URLQueryItem(name: "hasOtplessApp", value: DeviceInfoUtils.shared.hasOTPLESSInstalled ? "true" : "false" )
                let queryItemGmail = URLQueryItem(name: "hasGmailApp", value: DeviceInfoUtils.shared.hasGmailInstalled ? "true" : "false" )
                let queryItemHeadless = URLQueryItem(name: "isHeadless", value: "true")
                
                if urlComponents.queryItems != nil {
                    urlComponents.queryItems?.append(queryItem)
                    urlComponents.queryItems?.append(queryItemOtpless)
                    urlComponents.queryItems?.append(queryItemGmail)
                    urlComponents.queryItems?.append(queryItemHeadless)

                } else {
                    urlComponents.queryItems = [queryItem, queryItemOtpless, queryItemGmail, queryItemHeadless]
                }
                
                if isOneTapEnabled {
                    let plov: String? = OtplessHelper.getValue(forKey: "plov")
                    
                    if plov != nil && plov!.count > 0 {
                        let queryItemPlov = URLQueryItem(name: "plov", value: plov)
                        urlComponents.queryItems?.append(queryItemPlov)
                    }
                }
                
                let updatedUrlComponents =  addInitialParams(urlComponents: urlComponents)
                
                if let updatedURL = updatedUrlComponents.url {
                    let request = URLRequest(url: updatedURL)
                    mWebView.load(request)
                }
            }
        }
    }
    
    func addInitialParams(urlComponents: URLComponents) -> URLComponents  {
       var updatedURLComponents = urlComponents // Create a mutable copy of urlComponents
       
       if let initialParams = self.initialParams {
           if let method = initialParams["method"] as? String, method == "get" {
               if let parameters = initialParams["params"] as? [String: String] {
                   for (key, value) in parameters {
                       let queryItem = URLQueryItem(name: key, value: value)
                       if updatedURLComponents.queryItems != nil {
                           if let index = updatedURLComponents.queryItems?.firstIndex(where: { $0.name == key }) {
                               // Update the value of the query item
                               updatedURLComponents.queryItems?[index].value = value
                           } else {
                               updatedURLComponents.queryItems?.append(queryItem)
                           }
                       } else {
                           updatedURLComponents.queryItems = [queryItem]
                       }
                   }
               }
           }
       }
       return updatedURLComponents
   }
    
    public func onDeeplinkRecieved(deeplink: URL){
        let deepLinkURI = deeplink.absoluteString
        
        // Parse existing URL
        if (self.mWebView.url != nil) {
            var components = URLComponents(url:self.mWebView.url! , resolvingAgainstBaseURL: true)
            // Parse deep link URI
            if let deepLinkURL = URL(string: deepLinkURI),
               let deepLinkComponents = URLComponents(url: deepLinkURL, resolvingAgainstBaseURL: true),
               let queryItems = deepLinkComponents.queryItems {
                
                // Append query items to existing URL
                if components?.queryItems == nil {
                    components?.queryItems = queryItems
                } else {
                    components?.queryItems?.append(contentsOf: queryItems)
                }

                if let codeValue = queryItems.first(where: { $0.name == "code" })?.value {
                    self.bridge.sendHeadlessRequestToWeb(withCode: codeValue)
                    return
                }
            }
            
            // Get the final URL with the appended query items
            if let finalURL = components?.url {
                self.finalDeeplinkUri = finalURL
                let request = URLRequest(url: finalURL)
                self.mWebView.load(request)
            }
        }
    }
    
    func stopHeadless() {
        OtplessHelper.sendEvent(event: "merchant_abort")
        removeFromSuperview()
    }
}

extension OtplessView: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == self.messageName {
            bridge.parseScriptMessage(message: message, webview: self.mWebView)
        }
    }
}

extension OtplessView: BridgeDelegate {
    func showLoader() {
        
    }
    
    func hideLoader() {
        
    }
    
    func dismissVC() {
        removeFromSuperview()
    }
}
