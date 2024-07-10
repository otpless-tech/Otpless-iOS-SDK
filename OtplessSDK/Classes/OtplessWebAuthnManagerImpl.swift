//
//  OtplessWebAuthnManagerImpl.swift
//  OtplessSDK
//
//  Created by Sparsh on 27/06/24.
//

import Foundation
import LocalAuthentication
import AuthenticationServices

@available(iOS 16.0, *)
class OtplessWebAuthnManagerImpl: NSObject, OtplessWebAuthnManager, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    var windowScene: UIWindowScene?
    private var callback: (([String: Any]) -> Void)?
    
    /// Initializes OtplessWebAuthnManager with UIWindowScene.
    ///
    /// - parameter windowScene: windowScene is needed to inflate Passkey UI.
    init(windowScene: UIWindowScene) {
        self.windowScene = windowScene
    }
    
    
    /// Handles the error of an authorization request.
    ///
    /// - parameter controller: The authorization controller handling the authorization.
    /// - parameter error: The error that occurred during authorization.
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let authorizationError = error as? ASAuthorizationError
        let errorJson: [String: Any] = createError(fromAuthorizationError: authorizationError)
        callback?(errorJson)
    }
    
    
    /// Initiates Passkey registration.
    ///
    /// - parameter request: The request dictionary containing registration parameters.
    /// - parameter callback: The callback to handle the registration response.
    func initiateRegistration(withRequest request: [String : Any], onResponse callback: @escaping ([String: Any]) -> Void) {
        self.callback = callback
        
        if !isWindowValid() {
            let errorJson = Utils.createErrorDictionary(error: "window_nil", errorDescription: "The view was not in the app's view hierarchy.")
            callback(errorJson)
            return
        }
        
        createRegistrationRequest(
            from: request,
            onErrorCallback: callback,
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
    /// - parameter callback: The callback to handle the sign in response.
    func initiateSignIn(withRequest request: [String : Any], onResponse callback: @escaping ([String : Any]) -> Void) {
        self.callback = callback
        
        if !isWindowValid() {
            let errorJson = Utils.createErrorDictionary(error: "window_nil", errorDescription: "The view was not in the app's view hierarchy.")
            callback(errorJson)
            return
        }
        
        createSignInRequest(
            from: request,
            onErrorCallback: callback,
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
                    print("Biometric authentication is not available on this device.")
                case .biometryNotEnrolled:
                    print("No biometric enrollment is present.")
                case .passcodeNotSet:
                    print("No passcode is set on this device.")
                default:
                    print("Authentication error: \(laError.localizedDescription)")
                }
            } else {
                print("Unknown error: \(String(describing: error?.localizedDescription))")
            }
            callback(false)
        }
    }
    
    
    /// Provides the presentation anchor for the ASAuthorizationController.
    ///
    /// - parameter controller: The authorization controller requesting the presentation anchor.
    /// - returns: The presentation anchor for the authorization controller.
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return ASPresentationAnchor(windowScene: windowScene!)
    }
    
    
    /// Handles the successful completion of an authorization request.
    ///
    /// - parameter controller: The authorization controller handling the authorization.
    /// - parameter authorization: The authorization result.
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialRegistration {
            // A new passkey was registered
            let registrationResponse = createRegistrationResponse(from: credential)
            callback?(registrationResponse)
        } else if let credential = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialAssertion {
            // A passkey was used to sign in
            let signInResponse = createSignInResponse(from: credential)
            callback?(signInResponse)
        } else {
            // Some other authorization type was used like passwords.
            let errorJson = Utils.createErrorDictionary(error: "unexpected_credential_type", errorDescription: "Unexpected credential type \(authorization.credential.description)")
            callback?(errorJson)
        }
    }
}

@available(iOS 16, *)
extension OtplessWebAuthnManagerImpl {
    
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
            errorJson = Utils.createErrorDictionary(error: "authorization_error", errorDescription: "Authorization attempt failed.")
        case .invalidResponse:
            errorJson = Utils.createErrorDictionary(error: "authorization_error", errorDescription: "Authorization request received invalid response.")
        case .notHandled:
            errorJson = Utils.createErrorDictionary(error: "authorization_error", errorDescription: "Authorization request was not handled.")
        case .notInteractive:
            errorJson = Utils.createErrorDictionary(error: "authorization_error", errorDescription: "Authorization request does not involve user interaction.")
        case .unknown:
            errorJson = Utils.createErrorDictionary(error: "authorization_error", errorDescription: "Authorization request failed due to unknown reasons.")
        default:
            errorJson = Utils.createErrorDictionary(error: "authorization_error", errorDescription: "Unable to authorize via passkey.")
        }
        
        return errorJson
    }
    

    /// Checks if window can be referenced.
    /// - returns: A boolean indicating whether window is valid or not.
    private func isWindowValid() -> Bool{
        return windowScene != nil
    }
    
    /// Creates a parsing error and calls the callback with the error dictionary.
    ///
    /// - parameter errorIdentifier: The identifier for the parsing error.
    /// - parameter callback: The callback to return the error dictionary.
    private func createParsingError(
        errorIdentifier: String,
        callback: @escaping ([String: Any]) -> Void
    ) {
        callback(
            Utils.createErrorDictionary(error: "parsing_error", errorDescription: "Unable to parse \(errorIdentifier)")
        )
    }
    
    
    /// Creates a registration response from the provided credential.
    ///
    /// - parameter credential: The credential used for registration.
    /// - returns: A dictionary containing the registration response.
    private func createRegistrationResponse(from credential: ASAuthorizationPlatformPublicKeyCredentialRegistration) -> [String: Any] {
        print("Credential- \(credential.debugDescription)")
        var attestationData: [String: Any] = [:]
        
        attestationData["clientDataJSON"] = credential.rawClientDataJSON.base64EncodedString()
        attestationData["attestationObject"] = credential.rawAttestationObject?.base64EncodedString()
        
        var responseJson: [String: Any] = [:]
        responseJson["response"] = attestationData
        responseJson["id"] = credential.credentialID.base64EncodedString()
        responseJson["rawId"] = credential.credentialID.base64EncodedString()
        responseJson["type"] = "public-key"
        
        return responseJson
    }
    
    
    /// Creates a sign-in response from the provided credential.
    ///
    /// - parameter credential: The credential used for sign-in.
    /// - returns: A dictionary containing the sign-in response.
    private func createSignInResponse(from credential: ASAuthorizationPlatformPublicKeyCredentialAssertion) -> [String: Any] {
        print("Credential- \(credential.debugDescription)")
        var attestationJson: [String: Any] = [:]
        attestationJson["clientDataJSON"] = credential.rawClientDataJSON.base64EncodedString()
        attestationJson["authenticatorData"] = credential.rawAuthenticatorData.base64EncodedString()
        attestationJson["signature"] = credential.signature.base64EncodedString()
        
        var responseJson: [String: Any] = [:]
        responseJson["id"] = credential.userID.base64EncodedString()
        responseJson["rawId"] = credential.credentialID.base64EncodedString()
        responseJson["type"] = "public-key"
        responseJson["response"] = attestationJson
        
        return responseJson
    }
    
    
    /// Create RegistrationRequest using request dictionary from backend
    ///
    /// - parameter request: Dictionary sent from backend containing necessary details for creating a request
    /// - parameter onErrorCallback: Returns an error in the callback
    /// - parameter onRegistrationRequestCreation: Returns registration request for passkey (an instance of ASAuthorizationPlatformPublicKeyCredentialRegistrationRequest).
    func createRegistrationRequest(
        from request: [String: Any],
        onErrorCallback: @escaping ([String: Any]) -> Void,
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
        
        if let challenge = challenge.data(using: .utf8),
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
    /// - parameter onSignInRequestCreation: Returns registration request for passkey (an instance of ASAuthorizationPlatformPublicKeyCredentialRegistrationRequest).
    func createSignInRequest(
        from request: [String: Any],
        onErrorCallback: @escaping ([String: Any]) -> Void,
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
        
        if let challenge = challenge.data(using: .utf8) {
            platformKeyRequest = platformProvider?.createCredentialAssertionRequest(challenge: challenge)
        }
        
        guard let platformKeyRequest = platformKeyRequest else {
            createParsingError(errorIdentifier: "platformKeyRequest", callback: onErrorCallback)
            return
        }
        
        onSignInRequestCreation(platformKeyRequest)
    }
}
