//
//  OtplessView.swift
//  OtplessSDK
//
//  Created by Sparsh on 28/03/24.
//
import UIKit
import WebKit

class OtplessView: UIView {
    
    let JAVASCRIPT_OBJ = "window.webkit.messageHandlers"
    let messageName = "webNativeAssist"
    var mWebView: WKWebView! = nil
    var bridge: NativeWebBridge = NativeWebBridge()
    var startUri = "https://otpless.com/rc4/appid/"
    var finalDeeplinkUri: URL?
    var initialParams: [String: Any]?
    var headlessRequest: HeadlessRequest?
    var networkUIHidden: Bool = false
    var hideActivityIndicator: Bool = false
    var loader = OtplessLoader()
    var configParams: [String: Any]?
    var isHeadless: Bool = false
    private var headlessViewHeight: CGFloat = 0.1
    
    init(headlessRequest: HeadlessRequest) {
        super.init(frame: CGRectZero)
        translatesAutoresizingMaskIntoConstraints = false
        self.isHeadless = true
        self.headlessRequest = headlessRequest
        startUri += Otpless.sharedInstance.getAppId()
        setupView()
    }
    
    init(isLoginPage: Bool) {
        super.init(frame: CGRectZero)
        translatesAutoresizingMaskIntoConstraints = false
        self.isHeadless = false
        startUri += Otpless.sharedInstance.getAppId()
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    private func setupView() {
        initializeWebView()
        bridge.delegate = self
        
        if self.isHeadless {
            bridge.setHeadlessRequest(headlessRequest: headlessRequest, webview: mWebView)
        } else {
            setupLoader()
            getConfigParams()
        }
        
        clearWebViewCache()
        prepareUrlLoadWebview(startUrl: startUri, isHeadless: self.isHeadless)
        OtplessHelper.sendEvent(event: "sdk_screen_loaded")
    }
    
    private func initializeWebView() {
        mWebView = WKWebView(frame: bounds, configuration: getWKWebViewConfiguration())
        mWebView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mWebView.backgroundColor = UIColor.clear
        mWebView.isOpaque = false
        mWebView.navigationDelegate = self
        
        if !self.isHeadless {
            setupScrollView()
        }

        setInspectable()
        addSubview(mWebView)
    }
    
    private func setupScrollView() {
        mWebView.scrollView.delegate = self
        mWebView.scrollView.minimumZoomScale = 0.0
        mWebView.scrollView.maximumZoomScale = 0.0
    }
    
    private func setupLoader() {
        loader.delegate = self
        loader.networkFailureUiHidden = networkUIHidden
        loader.loaderHidden = hideActivityIndicator
    }
    
    private func setInspectable() {
        if #available(iOS 16.4, *) {
            if (Otpless.sharedInstance.webviewInspectable) {
                self.mWebView.isInspectable = true
            }
        }
    }
    
    private func getConfigParams(){
        if let initialParams = self.initialParams {
            if let method = initialParams["method"] as? String, method == "get" {
                if let parameters = initialParams["params"] as? [String: String] {
                    configParams = parameters
                    loader.configParams = configParams
                    loader.updateAllColors()
                }
            }
        }
    }
    
    func sendHeadlessRequestToWeb(request: HeadlessRequest) {
        bridge.setHeadlessRequest(headlessRequest: request, webview: mWebView)
        bridge.sendHeadlessRequestToWeb()
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
    
    func prepareUrlLoadWebview(startUrl: String, isHeadless: Bool){
        self.mWebView.evaluateJavaScript("navigator.userAgent") { [weak self] (result, error) in
            guard let self = self else { return }
            
            if let currentUserAgent = result as? String {
                // Append the custom User-Agent
                let customUserAgent = "\(currentUserAgent) otplesssdk"
                Otpless.sharedInstance.setUserAgent(customUserAgent)
                
                // Set the modified User-Agent
                mWebView.customUserAgent = customUserAgent
                let inid = DeviceInfoUtils.shared.getInstallationId()
                let tsid = DeviceInfoUtils.shared.getTrackingSessionId()
                
                // Load a webpage
                var urlComponents = URLComponents(string: startUrl)!
                if let bundleIdentifier = Bundle.main.bundleIdentifier {
                    let queryItem = URLQueryItem(name: "package", value: bundleIdentifier)
                    
                    if urlComponents.queryItems != nil {
                        urlComponents.queryItems?.append(queryItem)
                    } else {
                        urlComponents.queryItems = [queryItem]
                    }
                }
                
                var loginUri = "otpless." + Otpless.sharedInstance.getAppId().lowercased() + "://otpless"
                
                if let loginUriFromClient = Otpless.sharedInstance.getLoginUri(),
                   !loginUriFromClient.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                {
                    loginUri = loginUriFromClient.lowercased()
                }
                
                let queryItemLoginUri = URLQueryItem(name: "login_uri", value: loginUri)
                
                let queryItemWhatsApp = URLQueryItem(name: "hasWhatsapp", value: DeviceInfoUtils.shared.hasWhatsApp ? "true" : "false" )
                let queryItemOtpless = URLQueryItem(name: "hasOtplessApp", value: DeviceInfoUtils.shared.hasOTPLESSInstalled ? "true" : "false" )
                let queryItemGmail = URLQueryItem(name: "hasGmailApp", value: DeviceInfoUtils.shared.hasGmailInstalled ? "true" : "false" )
                let querySilentAuth = URLQueryItem(name: "isSilentAuthSupported", value: "true")
                
                if urlComponents.queryItems != nil {
                    urlComponents.queryItems?.append(queryItemWhatsApp)
                    urlComponents.queryItems?.append(queryItemOtpless)
                    urlComponents.queryItems?.append(queryItemGmail)
                    urlComponents.queryItems?.append(querySilentAuth)
                    urlComponents.queryItems?.append(queryItemLoginUri)
                } else {
                    urlComponents.queryItems = [queryItemWhatsApp, queryItemOtpless, queryItemGmail, querySilentAuth, queryItemLoginUri]
                }
                
                if isHeadless {
                    let queryItemHeadless = URLQueryItem(name: "isHeadless", value: "true")
                    urlComponents.queryItems?.append(queryItemHeadless)
                }
                
                if inid != nil {
                    let queryItemInid = URLQueryItem(name: "inid", value: inid)
                    urlComponents.queryItems?.append(queryItemInid)
                }
                
                if tsid != nil {
                    let queryItemTsid = URLQueryItem(name: "tsid", value: tsid)
                    urlComponents.queryItems?.append(queryItemTsid)
                }
                
                if #available(iOS 16, *) {
                    let queryWebAuthn = URLQueryItem(name: "isWebAuthnSupported", value: "true")
                    urlComponents.queryItems?.append(queryWebAuthn)
                }
                
                let updatedUrlComponents = addInitialParams(urlComponents: urlComponents)

                if let updatedURL = updatedUrlComponents.url {
                    let request = URLRequest(url: updatedURL)
                    OtplessLogger.log(string: request.url?.absoluteString ?? "Unable to get URL", type: "WebView URL")
                    mWebView.load(request)
                }
            }
        }
    }
    
    public func onDeeplinkRecieved(deeplink: URL){
        let deepLinkURI = deeplink.absoluteString
        
        OtplessLogger.log(string: deepLinkURI, type: "Deeplink")
        
        // Parse existing URL
        if (self.mWebView.url != nil) {
            var components = URLComponents(url: self.mWebView.url!, resolvingAgainstBaseURL: true)
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
                
                if isHeadless {
                    if let codeValue = queryItems.first(where: { $0.name == "code" })?.value {
                        self.bridge.sendHeadlessRequestToWeb(withCode: codeValue)
                        return
                    }
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
    
    func stopOtpless(dueToNoInternet: Bool) {
        self.loader.hide()
        if !dueToNoInternet {
            OtplessHelper.sendEvent(event: "merchant_abort")
        }
        removeFromSuperview()
    }
    
    func reloadUrl(){
        if (self.mWebView != nil) {
            if (self.mWebView.url != nil && finalDeeplinkUri != nil) {
                let request = URLRequest(url: finalDeeplinkUri!)
                self.mWebView.load(request)
            } else {
                prepareUrlLoadWebview(startUrl: startUri, isHeadless: isHeadless)
            }
            self.loader.show()
        }
    }
    
    func setLoginPageAttributes(networkUIHidden: Bool, hideActivityIndicator: Bool, initialParams: [String: Any]?) {
        self.networkUIHidden = networkUIHidden
        self.hideActivityIndicator = hideActivityIndicator
        self.initialParams = initialParams
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
    
    func setConstraints(_ constraints: [NSLayoutConstraint]) {
        NSLayoutConstraint.activate(constraints)
    }
    
    func setHeight(forHeightPercent heightPercent: Int) {
        if heightPercent < 0 || heightPercent > 100 {
            self.headlessViewHeight = UIScreen.main.bounds.height
        } else {
            self.headlessViewHeight = (CGFloat(heightPercent) * UIScreen.main.bounds.height) / 100
        }
        
        self.constraints.forEach { (constraint) in
            if constraint.firstAttribute == .height {
                constraint.constant = self.headlessViewHeight
            }
        }
    }
    
    func getViewHeight() -> CGFloat {
        return self.headlessViewHeight
    }
}
