//
//  Google+FBAuth.swift
//  OtplessSDK
//
//  Created by Sparsh on 19/12/24.
//

import Foundation
import UIKit
import os

// Empty implementation for when Google SDK is not available
#if !canImport(GoogleSignIn)  && !canImport(GoogleSignInSwift)
internal class OtplessGIDSignIn: NSObject, GoogleAuthProtocol {
    func signIn(
        vc: UIViewController,
        withHint hint: String?,
        shouldAddAdditionalScopes additionalScopes: [String]?,
        withNonce nonce: String?,
        onSignIn: @escaping ([String: Any]) -> Void
    ) {
        os_log("OTPLESS: Google support not initialized. Please add OtplessSDK/GoogleSupport to your Podfile")
        onSignIn([
            "success": false,
            "error": "Google support not initialized. Please add OtplessSDK/GoogleSupport to your Podfile"
        ])
    }
    func isGIDDeeplink(url: URL) -> Bool {
        return false
    }
}
#else
import GoogleSignIn

#if canImport(GoogleSignInSwift)
import GoogleSignInSwift
#endif

internal class OtplessGIDSignIn: NSObject, GoogleAuthProtocol {
    func isGIDDeeplink(url: URL) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
    
    func signIn(
        vc: UIViewController,
        withHint hint: String?,
        shouldAddAdditionalScopes additionalScopes: [String]?,
        withNonce nonce: String?,
        onSignIn: @escaping ([String: Any]) -> Void
    ) {
        GIDSignIn.sharedInstance.signIn(
            withPresenting: vc,
            hint: hint,
            additionalScopes: additionalScopes,
            nonce: nonce
        ) { signInResult, error in
            if let error = error {
                onSignIn(
                    GIDSignInResult(success: false, idToken: nil, error: error.localizedDescription).toDict()
                )
                return
            }
            
            guard let signInResult = signInResult else {
                onSignIn(
                    GIDSignInResult(success: false, idToken: nil, error: "Could not get sign in result").toDict()
                )
                return
            }
            
            if let idToken = signInResult.user.idToken?.tokenString {
                onSignIn(
                    GIDSignInResult(success: true, idToken: idToken, error: nil).toDict()
                )
            } else {
                onSignIn(
                    GIDSignInResult(success: false, idToken: nil, error: "Invalid idToken").toDict()
                )
            }
        }
    }
}

private class GIDSignInResult: NSObject {
    let channel: String = HeadlessChannelType.sharedInstance.GOOGLE_SDK
    let success: Bool
    let idToken: String?
    let error: String?
    
    init(success: Bool, idToken: String?, error: String?) {
        self.success = success
        self.idToken = idToken
        self.error = error
    }
    
    func toDict() -> [String: Any] {
        var dict: [String: Any] =  [
            "channel": channel,
            "success": success
        ]
        
        if let idToken = idToken {
            dict["idToken"] = idToken
        }
        
        if let error = error {
            dict["error"] = error
        }
        
        return dict
    }
}
#endif
