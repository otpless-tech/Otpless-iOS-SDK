//
//  OtplessAppleSignIn.swift
//  OtplessSDK
//
//  Created by Sparsh on 30/12/24.
//

import Foundation
import AuthenticationServices

class OtplessAppleSignIn: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private var onSignInComplete: (([String: Any]) -> Void)?
    
    func performSignIn(withNonce nonce: String?, onSignInComplete: @escaping ([String: Any]) -> Void) {
        if !isWindowValid() {
            onSignInComplete(
                AppleSignInResult(success: false, idToken: nil, error: "Could not get a valid Window.").toDict()
            )
            return
        }
        
        self.onSignInComplete = onSignInComplete
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = nonce
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    private func isWindowValid() -> Bool {
        if #available(iOS 15, *) {
            return Otpless.sharedInstance.getWindowScene() == nil && Otpless.sharedInstance.getWindow() == nil
        } else {
            return Otpless.sharedInstance.getWindow() == nil
        }
    }
}


extension OtplessAppleSignIn {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        if #available(iOS 15.0, *) {
            return ASPresentationAnchor(windowScene: Otpless.sharedInstance.getWindowScene()!)
        }
        
        return Otpless.sharedInstance.getWindow()!
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        case let appleIDCredential as ASAuthorizationAppleIDCredential:
            
            let authorizationCode = appleIDCredential.authorizationCode
            guard let authorizationCodeString = String(data: appleIDCredential.authorizationCode ?? Data(), encoding: .utf8) else {
                onSignInComplete?(
                    AppleSignInResult(success: false, idToken: nil, error: "Failed to convert authorization code to string").toDict()
                )
                return
            }
            
            print("Authorization code string: \(authorizationCodeString)")
            onSignInComplete?(
                AppleSignInResult(success: true, idToken: authorizationCodeString, error: nil).toDict()
            )
        default:
            onSignInComplete?(
                AppleSignInResult(success: false, idToken: nil, error: "Received unwanted credential type.").toDict()
            )
            break
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        onSignInComplete?(
            AppleSignInResult(success: false, idToken: nil, error: error.localizedDescription).toDict()
        )
    }
    
}

private class AppleSignInResult: NSObject {
    let idToken: String?
    let error: String?
    let success: Bool
    let channel = HeadlessChannelType.sharedInstance.APPLE_SDK
    
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
