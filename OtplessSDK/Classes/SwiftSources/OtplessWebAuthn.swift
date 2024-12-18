//
//  OtplessWebAuthn.swift
//  OtplessSDK
//
//  Created by Sparsh on 27/06/24.
//

import Foundation
import AuthenticationServices
import LocalAuthentication

/// `OtplessWebAuthn` is used to manage sign in and registration via WebAuthn.
///
/// We haven't annotated the class with `@available(iOS 16, *)` so that it's class level instance can be created in common classes thay may
/// supporting previous versions of iOS. Instead, we have annotated it's extension and other all the functions with `@available(iOS 16, *)`.
class OtplessWebAuthn: NSObject {
    private var responseCallback: ((WebAuthnResult) -> Void)?
    
    override init() {
        super.init()
    }
    
    /// Initiates Passkey registration.
    ///
    /// - parameter request: The request dictionary containing registration parameters.
    /// - parameter onResponse: The callback to handle the registration response.
    @available(iOS 16, *)
    func initiateRegistration(
        withRequest requestJson: [String: Any],
        onResponse responseCallback: @escaping (WebAuthnResult) -> Void
    ) {
        self.responseCallback = responseCallback
        
        if !isWindowValid() {
            let errorJson = Utils.createErrorDictionary(error: "window_nil", errorDescription: "The view was not in the app's view hierarchy.")
            responseCallback(.failure(errorJson))
            return
        }
        
        createRegistrationRequest(
            from: requestJson,
            onErrorCallback: responseCallback,
            onRegistrationRequestCreation: { platformKeyRequest in
                let authController = ASAuthorizationController(authorizationRequests: [ platformKeyRequest ])
                authController.delegate = self
                authController.presentationContextProvider = self
                authController.performRequests()
            }
        )
    }
    
    /// Initiates sign in via Passkey.
    ///
    /// - parameter request: The request dictionary containing registration parameters.
    /// - parameter onResponse: The callback to handle the sign in response.
    @available(iOS 16, *)
    func initiateSignIn(
        withRequest requestJson: [String: Any],
        onResponse responseCallback: @escaping (WebAuthnResult) -> Void
    ) {
        self.responseCallback = responseCallback
        
        if !isWindowValid() {
            let errorJson = Utils.createErrorDictionary(error: "window_nil", errorDescription: "The view was not in the app's view hierarchy.")
            responseCallback(.failure(errorJson))
            return
        }
        
        createSignInRequest(
            from: requestJson,
            onErrorCallback: responseCallback,
            onSignInRequestCreation: { platformKeyRequest in
                let authController = ASAuthorizationController(authorizationRequests: [ platformKeyRequest ])
                authController.delegate = self
                authController.presentationContextProvider = self
                authController.performRequests()
            }
        )
    }
    
    /// Checks whether device supports WebAuthN.
    ///
    /// - parameter callback: The callback to return the result of check.
    @available(iOS 16, *)
    func isWebAuthnsupportedOnDevice(onResponse callback: (Bool) -> Void) {
        if DeviceInfoUtils.shared.isDeviceSimulator() {
            callback(false)
            return
        }
        
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            callback(true)
        } else {
            if let laError = error as? LAError {
                switch laError.code {
                case .biometryNotAvailable:
                    OtplessLogger.log(string: "Biometrics not available on device", type: "isWebAuthnSupported")
                case .biometryNotEnrolled:
                    OtplessLogger.log(string: "Biometrics not available on device", type: "isWebAuthnSupported")
                case .passcodeNotSet:
                    OtplessLogger.log(string: "No passcode set on device", type: "isWebAuthnSupported")
                default:
                    OtplessLogger.log(string: "Authentication error \(error?.localizedDescription ?? "")", type: "isWebAuthnSupported")
                }
            } else {
                OtplessLogger.log(string: "Unknown error \(error?.localizedDescription ?? "")", type: "isWebAuthnSupported")
            }
            callback(false)
        }
    }
}

@available(iOS 16.0, *)
extension OtplessWebAuthn: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    /// Handles the error of an authorization request.
    ///
    /// - parameter controller: The authorization controller handling the authorization.
    /// - parameter error: The error that occurred during authorization.
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let authorizationError = error as? ASAuthorizationError
        let errorJson: [String: Any] = createError(fromAuthorizationError: authorizationError)
        responseCallback?(.failure(errorJson))
    }
    
    
    /// Provides the presentation anchor for the `ASAuthorizationController`.
    ///
    /// - parameter controller: The authorization controller requesting the presentation anchor.
    /// - returns: The presentation anchor for the authorization controller.
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return ASPresentationAnchor(windowScene: Otpless.sharedInstance.getWindowScene()!)
    }
    
    
    /// Handles the successful completion of an authorization request.
    ///
    /// - parameter controller: The authorization controller handling the authorization.
    /// - parameter authorization: The authorization result.
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialRegistration {
            // A new passkey was registered
            let registrationResponse = createRegistrationResponse(from: credential)
            responseCallback?(.success(registrationResponse))
        } else if let credential = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialAssertion {
            // A passkey was used to sign in
            let signInResponse = createSignInResponse(from: credential)
            responseCallback?(.success(signInResponse))
        } else {
            // Some other authorization type was used like passwords.
            let errorJson = Utils.createErrorDictionary(error: "unexpected_credential_type", errorDescription: "Unexpected credential type \(authorization.credential.description)")
            responseCallback?(.failure(errorJson))
        }
    }
}

@available(iOS 16, *)
extension OtplessWebAuthn {
    
    /// Create authorization error dictionary.
    ///
    /// - parameter error: This is the error that occured during registration or sign in via passkey.
    /// - returns: A dictionary containing error and its description.
    private func createError(fromAuthorizationError error: ASAuthorizationError?) -> [String: Any] {
        var errorJson: [String: Any] = [:]
        
        switch error?.code {
        case .canceled:
            errorJson = Utils.createErrorDictionary(error: "authorization_error", errorDescription: "User cancelled authorization attempt.")
        case .failed:
            errorJson = Utils.createErrorDictionary(error: "authorization_error", errorDescription: error?.localizedDescription ?? "Authorization attempt failed.")
        case .invalidResponse:
            errorJson = Utils.createErrorDictionary(error: "authorization_error", errorDescription: error?.localizedDescription ?? "Authorization request received invalid response.")
        case .notHandled:
            errorJson = Utils.createErrorDictionary(error: "authorization_error", errorDescription: error?.localizedDescription ?? "Authorization request was not handled.")
        case .notInteractive:
            errorJson = Utils.createErrorDictionary(error: "authorization_error", errorDescription: error?.localizedDescription ?? "Authorization request does not involve user interaction.")
        case .unknown:
            errorJson = Utils.createErrorDictionary(error: "authorization_error", errorDescription: error?.localizedDescription ?? "Authorization request failed due to unknown reasons.")
        default:
            errorJson = Utils.createErrorDictionary(error: "authorization_error", errorDescription: error?.localizedDescription ?? "Unable to authorize via passkey.")
        }
        
        return errorJson
    }
    

    /// Checks if window can be referenced.
    /// - returns: A boolean indicating whether window is valid or not.
    private func isWindowValid() -> Bool {
        return Otpless.sharedInstance.getWindowScene() != nil
    }
    
    /// Creates a parsing error and calls the callback with the error dictionary.
    ///
    /// - parameter errorIdentifier: The identifier for the parsing error.
    /// - parameter callback: The callback to return the error dictionary.
    private func createParsingError(
        errorIdentifier: String,
        callback: @escaping (WebAuthnResult) -> Void
    ) {
        callback(.failure(
            Utils.createErrorDictionary(error: "parsing_error", errorDescription: "Unable to parse \(errorIdentifier)")
        ))
    }
    
    
    /// Creates a registration response from the provided credential.
    ///
    /// - parameter credential: The credential used for registration.
    /// - returns: A dictionary containing the registration response.
    private func createRegistrationResponse(from credential: ASAuthorizationPlatformPublicKeyCredentialRegistration) -> [String: Any] {
        var attestationJson: [String: Any] = [:]
        
        attestationJson["clientDataJSON"] = Utils.base64UrlEncode(base64String:  credential.rawClientDataJSON.base64EncodedString())
        attestationJson["attestationObject"] = Utils.base64UrlEncode(base64String: credential.rawAttestationObject?.base64EncodedString() ?? "")
        
        var responseJson: [String: Any] = [:]
        responseJson["response"] = attestationJson
        responseJson["id"] = Utils.base64UrlEncode(base64String: credential.credentialID.base64EncodedString())
        responseJson["rawId"] = Utils.base64UrlEncode(base64String: credential.credentialID.base64EncodedString())
        responseJson["type"] = "public-key"
        
        return responseJson
    }
    
    
    /// Creates a sign-in response from the provided credential.
    ///
    /// - parameter credential: The credential used for sign-in.
    /// - returns: A dictionary containing the sign-in response.
    private func createSignInResponse(from credential: ASAuthorizationPlatformPublicKeyCredentialAssertion) -> [String: Any] {
        var attestationJson: [String: Any] = [:]
        
        attestationJson["clientDataJSON"] = Utils.base64UrlEncode(base64String:  credential.rawClientDataJSON.base64EncodedString())
        
        attestationJson["authenticatorData"] = Utils.base64UrlEncode(base64String:  credential.rawAuthenticatorData.base64EncodedString())
        attestationJson["signature"] = Utils.base64UrlEncode(base64String: credential.signature.base64EncodedString())
        
        var responseJson: [String: Any] = [:]
        responseJson["id"] = Utils.base64UrlEncode(base64String: credential.credentialID.base64EncodedString())
        responseJson["rawId"] = Utils.base64UrlEncode(base64String: credential.credentialID.base64EncodedString())
        responseJson["type"] = "public-key"
        responseJson["response"] = attestationJson
        
        return responseJson
    }
    
    
    /// Create RegistrationRequest using request dictionary from backend
    ///
    /// - parameter request: Dictionary sent from backend containing necessary details for creating a request
    /// - parameter onErrorCallback: Returns an error in the callback
    /// - parameter onRegistrationRequestCreation: Returns registration request for passkey (an instance of `ASAuthorizationPlatformPublicKeyCredentialRegistrationRequest`).
    func createRegistrationRequest(
        from request: [String: Any],
        onErrorCallback: @escaping (WebAuthnResult) -> Void,
        onRegistrationRequestCreation: (ASAuthorizationPlatformPublicKeyCredentialRegistrationRequest) -> Void
    ) {
        guard let user = request["user"] as? [String: Any] else {
            createParsingError(errorIdentifier: "user", callback: onErrorCallback)
            return
        }
        
        guard let rp = request["rp"] as? [String: Any] else {
            createParsingError(errorIdentifier: "relying party", callback: onErrorCallback)
            return
        }
        
        guard let challenge = request["challenge"] as? String else {
            createParsingError(errorIdentifier: "challenge", callback: onErrorCallback)
            return
        }
        
        var platformProvider: ASAuthorizationPlatformPublicKeyCredentialProvider?
        guard let rpId = rp["id"] as? String else {
            createParsingError(errorIdentifier: "rp id", callback: onErrorCallback)
            return
        }
        
        platformProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: rpId)
        
        var platformKeyRequest: ASAuthorizationPlatformPublicKeyCredentialRegistrationRequest?
        
        // Since the challenge received from backend is in format base64Url, it must be converted into base64.
        let backendCompatibleChallenge = Data(base64Encoded: Utils.convertBase64UrlToBase64(base64Url: challenge))
        
        if let challenge = backendCompatibleChallenge,
           let userId = (user["id"] as? String)?.data(using: .utf8),
           let name = (user["name"] as? String)
        {
            platformKeyRequest = platformProvider?.createCredentialRegistrationRequest(challenge: challenge, name: name, userID: userId)
        }
        
        guard let platformKeyRequest = platformKeyRequest else {
            createParsingError(errorIdentifier: "platformKeyRequest", callback: onErrorCallback)
            return
        }
        
        onRegistrationRequestCreation(platformKeyRequest)
    }
    
    
    /// Create Sign In Request using request dictionary from backend
    ///
    /// - parameter request: Dictionary sent from backend containing necessary details for creating a request
    /// - parameter onErrorCallback: Returns an error in the callback
    /// - parameter onSignInRequestCreation: Returns registration request for passkey (an instance of `ASAuthorizationPlatformPublicKeyCredentialRegistrationRequest`).
    func createSignInRequest(
        from request: [String: Any],
        onErrorCallback: @escaping (WebAuthnResult) -> Void,
        onSignInRequestCreation: (ASAuthorizationPlatformPublicKeyCredentialAssertionRequest) -> Void
    ) {
        guard let challenge = request["challenge"] as? String else {
            createParsingError(errorIdentifier: "challenge", callback: onErrorCallback)
            return
        }
        
        var platformProvider: ASAuthorizationPlatformPublicKeyCredentialProvider?
        guard let rpId = request["rpId"] as? String else {
            createParsingError(errorIdentifier: "rpId", callback: onErrorCallback)
            return
        }
        
        platformProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: rpId)
        
        var platformKeyRequest: ASAuthorizationPlatformPublicKeyCredentialAssertionRequest?
        
        // Since the challenge received from backend is in format base64Url, it must be converted into base64.
        let backendCompatibleChallenge = Data(base64Encoded: Utils.convertBase64UrlToBase64(base64Url: challenge))
        
        if let challenge = backendCompatibleChallenge {
            platformKeyRequest = platformProvider?.createCredentialAssertionRequest(challenge: challenge)
        }
        
        guard let platformKeyRequest = platformKeyRequest else {
            createParsingError(errorIdentifier: "platformKeyRequest", callback: onErrorCallback)
            return
        }
        
        onSignInRequestCreation(platformKeyRequest)
    }
}

enum WebAuthnResult {
    case success([String: Any])
    case failure([String: Any])
}
