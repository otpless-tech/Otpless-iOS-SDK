//
//  OtplessFBSignIn.swift
//  OtplessSDK
//
//  Created by Sparsh on 19/12/24.
//

import Foundation
import os
import UIKit

#if !canImport(FBSDKLoginKit) && !canImport(FacebookCore)
class OtplessFBSignIn: NSObject, FacebookAuthProtocol {
    func register(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]?) {
        // No-op when Facebook SDK is not available
    }
    
    func register(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) {
        // No-op when Facebook SDK is not available
    }
    
    @available(iOS 13.0, *)
    func register(openURLContexts URLContexts: Set<UIOpenURLContext>) {
        // No-op when Facebook SDK is not available
    }
    
    func startFBSignIn(
        withNonce nonce: String,
        withPermissions permissions: [String] = ["public_profile", "email"],
        onSignIn: @escaping ([String: Any]) -> Void
    ) {
        os_log("OTPLESS: Facebook support not initialized. Please add OtplessSDK/FacebookSupport to your Podfile")
        onSignIn([
            "success": false,
            "error": "Facebook support not initialized. Please add OtplessSDK/FacebookSupport to your Podfile"
        ])
        
        let errorEvent = [
            "channel": HeadlessChannelType.sharedInstance.FACEBOOK_SDK,
            "success": "false",
            "error": "Facebook support not initialized. Please add OtplessSDK/FacebookSupport to your Podfile"
        ]
        OtplessHelper.sendEvent(event: EventConstants.LOGIN_SDK_CALLBACK_EXP, extras: errorEvent)
    }
    
    func logoutFBUser() {
        // No-op when Facebook SDK is not available
    }
}

#else

#if canImport(FBSDKCoreKit)
import FBSDKCoreKit
import FBSDKLoginKit
#endif

// Import for SPM
#if canImport(FacebookCore)
import FacebookCore
#endif

class OtplessFBSignIn: NSObject, FacebookAuthProtocol {
    func register(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]?) {
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
    }
    
    func register(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) {
        ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )
    }
    
    @available(iOS 13.0, *)
    func register(openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else {
            return
        }

        ApplicationDelegate.shared.application(
            UIApplication.shared,
            open: url,
            sourceApplication: nil,
            annotation: [UIApplication.OpenURLOptionsKey.annotation]
        )
    }
    
    func startFBSignIn(
        withNonce nonce: String,
        withPermissions permissions: [String] = ["public_profile", "email"],
        onSignIn: @escaping ([String: Any]) -> Void
    ) {
        let loginManager = LoginManager()
        let configuration = LoginConfiguration(permissions: permissions, tracking: .enabled, nonce: nonce)
        
        let fBSignInResult = FBSignInResult()
        
        guard let configuration = configuration else {
            fBSignInResult.setErrorStr("Could not get LocalConfiguration instance")
            onSignIn(fBSignInResult.toDict())
            return
        }
        
        loginManager.logIn(configuration: configuration, completion: { result in
            switch result {
            case .cancelled:
                fBSignInResult.setErrorStr("User cancelled the facebook login")
                onSignIn(fBSignInResult.toDict())
                break
            case .failed(let error):
                fBSignInResult.setErrorStr(error.localizedDescription)
                let event = [
                    "channel": HeadlessChannelType.sharedInstance.FACEBOOK,
                    "success": "false",
                    "error": error.localizedDescription
                ]
                OtplessHelper.sendEvent(event: EventConstants.LOGIN_SDK_CALLBACK_EXP, extras: event)
                break
            case .success( _, _, let token):
                if let accessTokenStr = token?.tokenString {
                    fBSignInResult.setToken(accessTokenStr)
                }
                
                if let authenticationTokenStr = AuthenticationToken.current?.tokenString {
                    fBSignInResult.setIdToken(authenticationTokenStr)
                }
                
                if token?.tokenString.isEmpty == true && AuthenticationToken.current?.tokenString.isEmpty == true {
                    fBSignInResult.setErrorStr("Authentication Failed")
                }
                break
            }
            
            onSignIn(fBSignInResult.toDict())
        })
    }
    
    /// Logs out the existing user from FB so that a user can login again from a different identity if they want to.
    func logoutFBUser() {
        LoginManager().logOut()
    }
}

#endif

/// Helper class to send the result of Facebook sign in using Facebook's Limited Login SDK.
private class FBSignInResult: NSObject {
    let channel = HeadlessChannelType.sharedInstance.FACEBOOK_SDK
    var token: String?
    var error: String?
    var success: Bool = false
    var idToken: String?
    
    /// Setter function to set `token`
    /// - parameter token: It is the `accessToken` provided by Facebook after Limited Login. It may or may not be present in the response because it's availability is dependent on the `NSUserTrackingUsageDescription` permission. If the permission is granted, only then we receive `accessToken`.
    func setToken(_ token: String) {
        self.token = token
    }
    
    /// Setter function to set `idToken`
    /// - parameter idToken: It is the `authenticationToken (JWT)` provided by Facebook after Limited Login is successful.
    func setIdToken(_ idToken: String) {
        self.idToken = idToken
        self.success = true
    }
    
    /// Setter function to set `success`
    /// - parameter success: It is a boolean indicating whether the login is successful.
    func setIsSuccessful(_ success: Bool) {
        self.success = success
        self.success = true
    }
    
    /// Setter function to set `error`
    /// - parameter error: It is the error string describing the error occured during Limited Login.
    func setErrorStr(_ error: String) {
        self.error = error
        self.success = false
    }
    
    func toDict() -> [String: Any] {
        var dict: [String: Any] = [
            "channel": channel,
            "success": success
        ]
        
        if let token = token {
            dict["token"] = token
        }
        
        if let error = error {
            dict["error"] = error
        }
        
        if let idToken = idToken {
            dict["idToken"] = idToken
        }
        
        return dict
    }
}
