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
    
    /// Initiates the Google Sign-In process.
    ///
    /// - Parameters:
    ///   - vc: The `UIViewController` that presents the sign-in UI.
    ///   - hint: An optional string to suggest a Google account for the sign-in prompt.
    ///   - additionalScopes: An optional array of additional OAuth 2.0 scopes to request access to.
    ///   - nonce: An optional cryptographic nonce to associate with the sign-in request for enhanced security.
    ///   - onSignIn: A closure that returns a dictionary with the sign-in result.
    ///     - The dictionary includes:
    ///       - `success`: A `Bool` indicating whether the sign-in was successful.
    ///       - `idToken`: A `String?` containing the ID token if the sign-in is successful, or `nil` otherwise.
    ///       - `error`: A `String?` containing an error message if the sign-in fails, or `nil` otherwise.
    ///
    /// - Note: This function handles errors internally and calls the `onSignIn` closure with a result dictionary
    ///         representing the success or failure of the sign-in process.
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
