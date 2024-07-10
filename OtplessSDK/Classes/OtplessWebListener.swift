//
//  OtplessWebManager.swift
//  OtplessSDK
//
//  Created by Sparsh on 25/06/24.
//

import Foundation
import WebKit

protocol OtplessWebListener {
    
    /// Key 1 - Show loader
    func showLoader(usingDelegate delegate: BridgeDelegate?)
    
    /// Key 2 - Hide loader
    func hideLoader(usingDelegate delegate: BridgeDelegate?)
    
    /// Key 4 - Save string in local storage
    func saveString(forKey key: String, value: String)
    
    /// Key 5 - Get string from local storage
    func getString(forKey key: String)
    
    /// Key 7 - Open deeplink
    func openDeepLink(_ deeplink: String)
    
    /// Key 8 - Get AppInfo
    func getAppInfo()
    
    /// Key 11 - login page verification status
    func responseVerificationStatus(forResponse response: [String: Any]?, delegate: BridgeDelegate?)
    
    /// Key 12 - Change height of WebView
    func changeWebViewHeight(withHeightPercent heightPercent: Int)
    
    /// Key 13 - Get extra params
    func getExtraParams(fromHeadlessRequest request: HeadlessRequest?)
    
    /// Key 14 - WebView closed by user
    func onCloseWebView(delegate: BridgeDelegate?)
    
    /// Key 15 - Send event
    func sendEvent()
    
    /// Key 20 - Send headless request to web
    func sendHeadlessRequestToWeb(_ headlessRequest: HeadlessRequest?, withCode code: String)
    
    /// Key 21 - Send headless response to merchant
    func sendHeadlessResponse(_ response: [String: Any]?)
    
    /// Key 26 - Initiate WebAuthn registration
    func initiateWebAuthnRegistration(withRequest requestJson: [String: Any]?)
    
    /// Key 27 - Initiate WebAuthn sign in
    func initiateWebAuthnSignIn(withRequest requestJson: [String: Any]?)
    
    /// Key 28 - Check WebAuthn availability
    func checkWebAuthnAvailability()
    
    /// Key 42 - Perform SNA (Silent Network Auth)
    func performSilentAuth(withConnectionUrl url: URL?)
}
