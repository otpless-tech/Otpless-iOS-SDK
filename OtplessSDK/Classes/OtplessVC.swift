//
//  OtplessVC.swift
//  OtplessSDK
//
//  Created by OTPLESS on 31/05/23.
//

import UIKit
import WebKit

class OtplessVC: UIViewController,WKNavigationDelegate {
   
    let JAVASCRIPT_OBJ = "window.webkit.messageHandlers"
    let messageName = "webNativeAssist"
    var mWebView: WKWebView! = nil
    var bridge: NativeWebBridge = NativeWebBridge()
    var startUri = "https://otpless.com/ios/index.html"
    private var loader = OtplessLoader()
    var isLoginPage = false
    var initialParams : [String: Any]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.presentationController?.delegate = self
        bridge.delegate = self
        // Do any additional setup after loading the view.
        initialise()
        OtplessHelper.sendEvent(event: "sdk_screen_loaded")
    }
    
    private func initialise() {
        self.loader.show()
        showWebview(url: startUri)
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
            }
            
            // Get the final URL with the appended query items
            if let finalURL = components?.url {
                let request = URLRequest(url: finalURL)
                self.mWebView.load(request)
            } else {
                //
            }
        }

    }
    
    func showWebview(url: String){
        DispatchQueue.main.async { [self] in
            self.loader.hide()
            initialiseWebView(startUrl: url)
        }
    }
    
    func initialiseWebView(startUrl: String){
        bridge.setVC(vc: self)
        if self.mWebView == nil {
            self.mWebView = WKWebView(frame: .zero, configuration: getWKWebViewConfiguration())
            self.mWebView.isHidden = false
            self.mWebView.backgroundColor = UIColor.clear
            self.mWebView.isOpaque = false
            self.mWebView.translatesAutoresizingMaskIntoConstraints = false
            self.mWebView.scrollView.maximumZoomScale = 0.0
            self.mWebView.scrollView.minimumZoomScale = 0.0
            self.mWebView.navigationDelegate = self
            self.mWebView.scrollView.delegate = self
            
            
            self.view.addSubview(self.mWebView)
            if #available(iOS 11.0, *) {
                let layoutGuide = view.safeAreaLayoutGuide
                self.mWebView.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor).isActive = true
                self.mWebView.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor).isActive = true
                //self.mWebView.topAnchor.constraint(equalTo: layoutGuide.topAnchor).isActive = true
                self.mWebView.heightAnchor.constraint(equalToConstant: view.bounds.height).isActive = true
                self.mWebView.bottomAnchor.constraint(equalTo: layoutGuide.bottomAnchor).isActive = true
            } else {
                mWebView.frame = self.view.frame
            }
           
        }
        mWebView.evaluateJavaScript("navigator.userAgent") { [weak self] (result, error) in
                    guard let self = self else { return }

            if let currentUserAgent = result as? String {
                // Append the custom User-Agent
                let customUserAgent = "\(currentUserAgent) otplesssdk"
                
                // Set the modified User-Agent
                self.mWebView.customUserAgent = customUserAgent
                
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
                if urlComponents.queryItems != nil {
                    urlComponents.queryItems?.append(queryItem)
                    urlComponents.queryItems?.append(queryItemOtpless)
                    urlComponents.queryItems?.append(queryItemGmail)
                } else {
                    urlComponents.queryItems = [queryItem,queryItemOtpless,queryItemGmail]
                }
                let updatedUrlComponentsWithLoginPage = self.manageLoginPage(urlComponents: urlComponents);
                let updatedUrlComponents =  self.addInitialParams(urlComponents: updatedUrlComponentsWithLoginPage)
                
                        // Get the updated URL with the appended query parameter
                        if let updatedURL = updatedUrlComponents.url {
                            if let encodedURLString = updatedURL.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                                if let encodedURL = URL(string: encodedURLString) {
                                    let request = URLRequest(url: encodedURL)
                                    self.mWebView.load(request)
                                }
                            }
                            
                        }
                    }
                }
    }
    
    func manageLoginPage(urlComponents: URLComponents) -> URLComponents {
        var updatedURLComponents = urlComponents // Create a mutable copy of urlComponents
        if (isLoginPage){
            let queryItem = URLQueryItem(name: "lp", value: "true");
            if updatedURLComponents.queryItems != nil {
                updatedURLComponents.queryItems?.append(queryItem)
            }
        }
        return updatedURLComponents
    }

    public func addInitialParams(urlComponents: URLComponents) -> URLComponents  {
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
}

extension OtplessVC: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == self.messageName {
            bridge.parseScriptMessage(message: message, webview: self.mWebView)
        }
    }
}

extension OtplessVC: UIScrollViewDelegate {
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        scrollView.pinchGestureRecognizer?.isEnabled = false
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return nil
    }
}

extension OtplessVC: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            // Handle the dismiss event here
        Otpless.sharedInstance.addButtonToVC()
        let otplessResponse = OtplessResponse(responseString: "user cancelled.", responseData: nil)
        Otpless.sharedInstance.delegate?.onResponse(response: otplessResponse)
        OtplessHelper.sendEvent(event: "user_abort_pan")
        }
}

extension OtplessVC: BridgeDelegate {
    
    func showLoader() {
        self.loader.show()
    }
    
    func hideLoader() {
        self.loader.hide()
    }
    func dismissVC() {
        Otpless.sharedInstance.addButtonToVC()
        self.mWebView.isHidden = true
        self.dismiss(animated: true)
        OtplessHelper.sendEvent(event: "sdk_screen_dismissed")
    }
}
