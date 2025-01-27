//
//  NativeWebManagerExtension.swift
//  OtplessSDK
//
//  Created by Sparsh on 12/08/24.
//

import Foundation
import WebKit

extension NativeWebBridge {
    
    
    /// Key 1 - Show loader
    func showLoader(usingDelegate delegate: BridgeDelegate?) {
        delegate?.showLoader()
    }
    
    
    /// Key 2 - Hide loader
    func hideLoader(usingDelegate delegate: BridgeDelegate?) {
        delegate?.hideLoader()
    }
    
    
    /// Key 4 - Save string in local storage
    func saveString(forKey key: String, value: String) {
        OtplessHelper.setValue(value: key, forKey: value)
    }
    
    
    /// Key 5 - Get string from local storage
    func getString(forKey key: String) {
        let value : String? = OtplessHelper.getValue(forKey: key)
        var params = [String: String]()
        
        if value != nil {
            params[key] = value
        } else {
            params[key] = ""
        }
        let jsonStr = Utils.convertDictionaryToString(params)
        loadScript(function: "onStorageValueSuccess", message: jsonStr)
    }
    
    
    /// Key 7 - Open deeplink
    func openDeepLink(_ deeplink: String) {
        let urlWithOutDecoding = deeplink.removingPercentEncoding
        if let link = URL(string: (urlWithOutDecoding!.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed))!) {
            UIApplication.shared.open(link, options: [:], completionHandler: nil)
        }
        OtplessHelper.sendEvent(event: EventConstants.DEEPLINK_WEB)
    }
    
    
    /// Key 8 - Get AppInfo
    func getAppInfo() {
        var parametersToSend =  DeviceInfoUtils.shared.getAppInfo()
        parametersToSend["appSignature"] = DeviceInfoUtils.shared.appHash
        let jsonStr = Utils.convertDictionaryToString(parametersToSend)
        loadScript(function: "onAppInfoResult", message: jsonStr)
    }
    
    
    /// Key 11 - login page verification status
    func responseVerificationStatus(forResponse response: [String : Any]?, delegate: BridgeDelegate?) {
        var responseParams =  [String : Any]()
        responseParams["data"] = response
        let otplessResponse = OtplessResponse(responseString: nil, responseData: responseParams)
        Otpless.sharedInstance.delegate?.onResponse(response: otplessResponse)
        delegate?.dismissView()
        OtplessHelper.sendEvent(event: EventConstants.LOGINPAGE_RESPONSE_WEB)
    }
    
    
    /// Key 12 - Change height of WebView
    func changeWebViewHeight(withHeightPercent heightPercent: Int) {
        Otpless.sharedInstance.setOtplessViewHeight(heightPercent: heightPercent)
    }
    
    
    /// Key 13 - Get extra params
    func getExtraParams(from request: HeadlessRequest?) {
        var extraParams = [String: Any]()
        if let headlessRequest = request {
            extraParams = headlessRequest.makeJson()
        }
        let jsonStr = Utils.convertDictionaryToString(extraParams)
        loadScript(function: "onExtraParamResult", message: jsonStr)
    }
    
    
    /// Key 14 - WebView closed by user
    func onCloseWebView() {
        let otplessResponse = OtplessResponse(responseString: "user cancelled.", responseData: nil)
        Otpless.sharedInstance.delegate?.onResponse(response: otplessResponse)
        delegate?.dismissView()
        OtplessHelper.sendEvent(event: "user_abort")
    }
    
    
    /// Key 15 - Send event
    func sendEvent() {
        // TODO
    }
    
    
    /// Key 20 - Send headless request to web
    func sendHeadlessRequestToWeb(_ headlessRequest: HeadlessRequest?, withCode code: String = "") {
        var requestData: [String: Any] = [:]
        
        if !code.trimmingCharacters(in: .whitespaces).isEmpty {
            // Send only code in request to verify it and get details
            requestData["code"] = code
        } else if let request = headlessRequest {
            requestData = request.makeJson()
        }
        
        let jsonStr = Utils.convertDictionaryToString(requestData)
        loadScript(function: "headlessRequest", message: jsonStr)
        
        OtplessHelper.sendEvent(event: EventConstants.HEADLESS_REQUEST)
    }
    
    
    /// Key 21 - Send headless response to merchant
    func sendHeadlessResponse(_ response: [String : Any]?) {
        self.parseHeadlessResponse(withResponse: response)
    }
    
    
    /// Key 26 - Initiate WebAuthn registration
    func initiateWebAuthnRegistration(withRequest requestJson: [String : Any]?) {
        guard let requestJson = requestJson else {
            self.loadErrorInScript(function: "onWebAuthnRegistrationError", error: "json_parsing_error", errorDescription: "Unable to parse request json")
            return
        }
        
        if #available(iOS 16, *) {
            guard let _ = Otpless.sharedInstance.getWindowScene() else {
                self.loadErrorInScript(function: "onWebAuthnRegistrationError", error: "window_nil", errorDescription: "Window scene is nil, can't show Passkey bottom sheet.")
                return
            }
            
            if otplessWebAuthn == nil {
                otplessWebAuthn = OtplessWebAuthn()
            }
            
            otplessWebAuthn?.initiateRegistration(withRequest: requestJson, onResponse: { response in
                switch response {
                case .success(let dictionary):
                    self.loadScript(function: "onWebAuthnRegistrationSuccess", message: Utils.convertDictionaryToString(dictionary))
                case .failure(let dictionary):
                    self.loadScript(function: "onWebAuthnRegistrationError", message: Utils.convertDictionaryToString(dictionary))
                }
            })
        } else {
            self.loadUnsupportedIOSVersionErrorInScript(function: "onWebAuthnRegistrationError", supportedFrom: "iOS 16", feature: "Passkeys")
            return
        }
    }
    
    
    /// Key 27 - Initiate WebAuthn sign in
    func initiateWebAuthnSignIn(withRequest requestJson: [String : Any]?) {
        guard let requestJson = requestJson else {
            self.loadErrorInScript(function: "onWebAuthnSigninError", error: "json_parsing_error", errorDescription: "Unable to parse request json")
            return
        }
        
        if #available(iOS 16, *) {
            guard let _ = Otpless.sharedInstance.getWindowScene() else {
                self.loadErrorInScript(function: "onWebAuthnSigninError", error: "window_nil", errorDescription: "Window scene is nil, can't show Passkey bottom sheet.")
                return
            }
            
            if otplessWebAuthn == nil {
                otplessWebAuthn = OtplessWebAuthn()
            }
            
            otplessWebAuthn?.initiateSignIn(withRequest: requestJson, onResponse: { response in
                switch response {
                case .success(let dictionary):
                    self.loadScript(function: "onWebAuthnSigninSuccess", message: Utils.convertDictionaryToString(dictionary))
                case .failure(let dictionary):
                    self.loadScript(function: "onWebAuthnSigninError", message: Utils.convertDictionaryToString(dictionary))
                }
            })
        } else {
            self.loadUnsupportedIOSVersionErrorInScript(function: "onWebAuthnSigninError", supportedFrom:  "iOS 16", feature: "Passkeys")
            return
        }
    }
    
    
    /// Key 28 - Check WebAuthn availability
    func checkWebAuthnAvailability() {
        if #available(iOS 16, *) {
            if otplessWebAuthn == nil {
                otplessWebAuthn = OtplessWebAuthn()
            }
            
            otplessWebAuthn?.isWebAuthnsupportedOnDevice(onResponse: { isSupported in
                var webAuthnAvailabilityResponse: [String: Any] = [:]
                webAuthnAvailabilityResponse["isAvailable"] = "\(isSupported)"
                let responseStr = Utils.convertDictionaryToString(webAuthnAvailabilityResponse)
                self.loadScript(function: "onCheckWebAuthnAuthenticatorResult", message: responseStr)
            })
        } else {
            var webAuthnAvailabilityResponse: [String: Any] = [:]
            webAuthnAvailabilityResponse["isAvailable"] = "false"
            let responseStr = Utils.convertDictionaryToString(webAuthnAvailabilityResponse)
            loadScript(function: "onCheckWebAuthnAuthenticatorResult", message: responseStr)
        }
    }
    
    /// Key 42 - Perform SNA (Silent Network Auth)
    func performSilentAuth(withConnectionUrl url: URL?) {
        if url != nil {
            forceOpenURLOverMobileNetwork(
                url: url!,
                completion: { silentAuthResponse in
                    let jsonStr = Utils.convertDictionaryToString(silentAuthResponse)
                    self.loadScript(function: "onCellularNetworkResult", message: jsonStr)
                    OtplessHelper.sendEvent(event: EventConstants.SNA_CALLBACK_RESULT)
                }
            )
        } else {
            // handle case when unable to create URL from string
            self.loadErrorInScript(function: "onCellularNetworkResult", error: "url_parsing_fail", errorDescription: "Unable to parse url from string.")
        }
    }
    
    /// Key 43 - Make requests to provided SNA URLs
    func warmupURLCache(forURLs urls: [String]) {
        if #available(iOS 12.0, *) {
            var urlsToPing: [String] = []
            var areURLsFromWeb = false
            if urls.isEmpty {
                urlsToPing = Utils.getSNAPreLoadingURLs()
                areURLsFromWeb = false
            } else {
                urlsToPing = urls
                areURLsFromWeb = true
            }
            
            OtplessNetworkHelper.shared.warmupURLCache(
                forURLs: urlsToPing,
                shouldRequireMobileDataEnabled: true,
                areURLsFromWeb: areURLsFromWeb,
                onComplete: {
                    OtplessHelper.setValue(value: Int64(Date().timeIntervalSince1970), forKey: Constants.KEY_LAST_URL_CACHE_COMPLETION_TIME)
                }
            )
        }
    }
    
    
    /// Key 56 - Performs custom SSO Authentication. Currently supported channels: `APPLE_SDK, GOOGLE_SDK & FACEBOOK_SDK`
    func useNativeSDKToAuthenticateUser(channel: String, data: [String: Any]) {
        let nonce = data["nonce"] as? String ?? "failed_to_fetch_nonce"
        
        switch channel {
        case HeadlessChannelType.sharedInstance.GOOGLE_SDK:
            if let vc = Otpless.sharedInstance.merchantVC {
                if let GoogleAuthClass = NSClassFromString("OtplessSDK.OtplessGIDSignIn") as? NSObject.Type {
                    let googleAuthHandler = GoogleAuthClass.init()
                    if let handler = googleAuthHandler as? GoogleAuthProtocol {
                        handler.signIn(
                            vc: vc,
                            withHint: nil,
                            shouldAddAdditionalScopes: nil,
                            withNonce: nonce,
                            onSignIn: { signInResult in
                                self.loadScript(function: "ssoSdkResponse", message: Utils.convertDictionaryToString(signInResult))
                            })
                    } else {
                        self.loadScript(function: "ssoSdkResponse", message: Utils.convertDictionaryToString(Utils.createErrorDictionary(error: "missing_dependency", errorDescription: "Google support not initialized. Please add OtplessSDK/GoogleSupport to your Podfile")))
                    }
                } else {
                    self.loadScript(function: "ssoSdkResponse", message: Utils.convertDictionaryToString(Utils.createErrorDictionary(error: "missing_class", errorDescription: "Could not find an instance of OtplessGIDSignIn")))
                }
            }
            OtplessHelper.sendEvent(event: EventConstants.GOOGLE_SDK_WEB)
            break
        case HeadlessChannelType.sharedInstance.FACEBOOK_SDK:
            if let FacebookAuthClass = NSClassFromString("OtplessSDK.OtplessFBSignIn") as? NSObject.Type {
                let fbAuthHandler = FacebookAuthClass.init()
                if let handler = fbAuthHandler as? FacebookAuthProtocol {
                    handler.logoutFBUser()
                    let permissions = data["permissions"] as? [String] ?? ["public_profile", "email"]
                    handler.startFBSignIn(
                        withNonce: nonce,
                        withPermissions: permissions,
                        onSignIn: { signInResult in
                            self.loadScript(function: "ssoSdkResponse", message: Utils.convertDictionaryToString(signInResult))
                        })
                } else {
                    self.loadScript(function: "ssoSdkResponse", message: Utils.convertDictionaryToString(Utils.createErrorDictionary(error: "missing_dependency", errorDescription: "Facebook support not initialized. Please add OtplessSDK/FacebookSupport to your Podfile")))
                }
            } else {
                self.loadScript(function: "ssoSdkResponse", message: Utils.convertDictionaryToString(Utils.createErrorDictionary(error: "missing_class", errorDescription: "Could not find an instance of OtplessFBSignIn")))
            }
            OtplessHelper.sendEvent(event: EventConstants.FACEBOOK_SDK_WEB)
            break
        case HeadlessChannelType.sharedInstance.APPLE_SDK:
            if #available(iOS 13.0, *) {
                let otplessAppleSignIn = OtplessAppleSignIn()
                otplessAppleSignIn.performSignIn(withNonce: nonce, onSignInComplete: { signInResult in
                    self.loadScript(function: "ssoSdkResponse", message: Utils.convertDictionaryToString(signInResult))
                })
            } else {
                self.loadScript(
                    function: "ssoSdkResponse",
                    message: Utils.convertDictionaryToString(
                        Utils.createUnsupportedIOSVersionError(supportedFrom: "13.0", forFeature: "APPLE_SDK Sign In")
                    )
                )
            }
            OtplessHelper.sendEvent(event: EventConstants.APPLE_SDK_WEB)
            break
        default:
            self.loadScript(function: "ssoSdkResponse", message: Utils.convertDictionaryToString(["success": false, "error": "Could not find a valid channel to authenticate user."]))
        }
        OtplessHelper.sendEvent(event: EventConstants.LOGIN_SDK_CALLBACK)
    }
    
    /// Key 57 - Logout user if session exists in 3rd party sdk
    func logoutUserFromSDK(channel: String) {
        switch channel {
        case HeadlessChannelType.sharedInstance.GOOGLE_SDK:
            // Not required
            break
        case HeadlessChannelType.sharedInstance.FACEBOOK_SDK:
            OtplessFBSignIn().logoutFBUser()
            break
        case HeadlessChannelType.sharedInstance.APPLE_SDK:
            // Not required
            break
        default:
            OtplessLogger.log(string: "Invalid channel received", type: "SDK_AUTHENTICATION")
        }
    }
}


extension NativeWebBridge {
    private func loadScript(function: String, message: String) {
        let tempScript = function + "(" + message + ")"
        let script = tempScript.replacingOccurrences(of: "\n", with: "")
        callJs(webview: webView, script: script)
    }
    
    private func callJs(webview: WKWebView, script: String) {
        OtplessLogger.log(string: script, type: "JS Script")
        DispatchQueue.main.async {
            webview.evaluateJavaScript(script, completionHandler: nil)
        }
    }
    
    private func parseHeadlessResponse(withResponse response: [String: Any]?) {
        let responseStr = response?["response"] as? String ?? ""
        if responseStr.isEmpty {
            Otpless.sharedInstance.stopOtplessAndSendEmptyResponseError()
            return
        }
        
        let responseDict = Utils.convertToDictionary(text: responseStr)
        let closeView = response?["closeView"] as? Int == 1
        let responseType = responseDict?["responseType"] as? String ?? ""
        
        let statusCode = responseDict?["statusCode"] as? Int ?? 0
        let resp = (responseDict?["response"] as? [String: Any])
        
        let headlessResponse = HeadlessResponse(
            responseType: responseType,
            responseData: resp,
            statusCode: statusCode
        )
        
        Otpless.sharedInstance.sendHeadlessResponse(response: headlessResponse, closeView: closeView, sendWebResponseEvent: true)
    }
    
    private func forceOpenURLOverMobileNetwork(url: URL, completion: @escaping ([String: Any]) -> Void) {
        if #available(iOS 12.0, *) {
            let cellularConnectionManager = CellularConnectionManager()
            cellularConnectionManager.open(url: url, operators: nil, completion: completion)
        } else {
            let errorJson = Utils.createUnsupportedIOSVersionError(supportedFrom: "iOS 12", forFeature: "Silent Network Authentication")
            completion(errorJson)
        }
    }
    
    @available(iOS 13, *)
    private func getWindowScene() -> UIWindowScene? {
        return webView.window?.windowScene
    }
}

/// Handles exceptions and errors and send them to web
extension NativeWebBridge {
    
    private func loadErrorInScript(function: String, error: String, errorDescription: String) {
        let error = Utils.createErrorDictionary(error: error, errorDescription: errorDescription)
        loadScript(function: function, message: Utils.convertDictionaryToString(error))
    }
    
    private func loadUnsupportedIOSVersionErrorInScript(function: String, supportedFrom: String, feature: String) {
        let unsupportedIOSVersionError = Utils.createUnsupportedIOSVersionError(supportedFrom: supportedFrom, forFeature: feature)
        loadScript(function: function, message: Utils.convertDictionaryToString(unsupportedIOSVersionError))
    }
}
