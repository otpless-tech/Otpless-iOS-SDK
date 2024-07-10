//
//  OtplessWebAuthnManager.swift
//  OtplessSDK
//
//  Created by Sparsh on 27/06/24.
//

import Foundation

protocol OtplessWebAuthnManager {
    /// Initiate webAuthn registration using requestJson received from backend.
    func initiateRegistration(withRequest requestJson: [String: Any], onResponse callback: @escaping ([String: Any]) -> Void)
    
    /// Initiate sign in through webAuthn using requestJson received from backend.
    func initiateSignIn(withRequest requestJson: [String: Any], onResponse callback: @escaping ([String: Any]) -> Void)
    
    /// Check whether device supports Biometric or Passcode authentication to support webAuthn
    func isWebAuthnsupportedOnDevice(onResponse callback: (Bool) -> Void)
}
