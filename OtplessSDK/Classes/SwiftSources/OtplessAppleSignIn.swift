//
//  OtplessAppleSignIn.swift
//  OtplessSDK
//
//  Created by Sparsh on 31/12/24.
//

import Foundation
import AuthenticationServices

class OtplessAppleSignIn: NSObject {
    
    private var completionHandler: ((Result<ASAuthorizationAppleIDCredential, Error>) -> Void)?
    
    func performSignIn(withNonce nonce: String?, onSignInComplete: @escaping (([String: Any]) -> Void)) {
        signIn(withNonce: nonce, completion: { result in
            switch result {
            case .success(let credential):
                let signInResult = self.handleSuccessfulSignIn(with: credential)
                
                onSignInComplete(signInResult)
            case .failure(let error):
                let signInResult = self.handleSignInError(error)
                onSignInComplete(signInResult)
            }
        })
    }
    
    private func signIn(withNonce nonce: String?, completion: @escaping (Result<ASAuthorizationAppleIDCredential, Error>) -> Void) {
        self.completionHandler = completion
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.nonce = nonce
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    private func handleSuccessfulSignIn(with credential: ASAuthorizationAppleIDCredential) -> [String: Any] {
        let appleSignInResult = AppleSignInResult()
        
        if let idToken = credential.identityToken,
           let idTokenStr = String(data: idToken, encoding: .utf8) {
            appleSignInResult.setIdToken(idTokenStr)
        }
        
        if let authorizationCode = credential.authorizationCode,
           let authorizationCodeStr = String(data: authorizationCode, encoding: .utf8) {
            appleSignInResult.setToken(authorizationCodeStr)
        }
        
        if appleSignInResult.idToken == nil && appleSignInResult.token == nil {
            appleSignInResult.setErrorStr("Could not get a valid token after authentication.")
        }
        
        return appleSignInResult.toDict()
    }
    
    private func handleSignInError(_ error: Error) -> [String: Any] {
        let appleSignInResult = AppleSignInResult()
        appleSignInResult.setErrorStr(error.localizedDescription)
        return appleSignInResult.toDict()
    }
}

extension OtplessAppleSignIn: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            completionHandler?(.success(appleIDCredential))
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completionHandler?(.failure(error))
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.windows.first!
    }
}

private class AppleSignInResult: NSObject {
    var idToken: String?
    var error: String?
    var success: Bool = false
    let channel = HeadlessChannelType.sharedInstance.APPLE_SDK
    var token: String?
    
    /// Setter function to set `token`
    /// - parameter token: It is the `authorizationCode` provided by Apple after sign in.
    func setToken(_ token: String) {
        self.token = token
        self.success = true
    }
    
    /// Setter function to set `idToken`
    /// - parameter idToken: It is the `authenticationToken (JWT)` provided by Apple after login is successful.
    func setIdToken(_ idToken: String) {
        self.idToken = idToken
        self.success = true
    }
    
    /// Setter function to set `error`
    /// - parameter error: It is the error string describing the error occured during Apple Sign In.
    func setErrorStr(_ error: String) {
        self.error = error
        self.success = false
    }
    
    func toDict() -> [String: Any] {
        var dict: [String: Any] =  [
            "channel": channel,
            "success": success
        ]
        
        if let idToken = idToken {
            dict["idToken"] = idToken
        }
        
        if let token = token {
            dict["token"] = token
        }
        
        if let error = error {
            dict["error"] = error
        }
        
        return dict
    }
}
