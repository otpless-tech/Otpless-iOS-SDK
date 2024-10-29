//
//  HeadlessDemoVC.swift
//  OtplessSDK_Example
//
//  Created by Sparsh on 28/03/24.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import UIKit
import OtplessSDK

class HeadlessDemoVC: UIViewController, onHeadlessResponseDelegate {
    func onHeadlessResponse(response: OtplessSDK.HeadlessResponse?) {
        DispatchQueue.main.async {
            self.responseTextView.text = response?.toString()
            self.responseTextView.alpha = 0
            UIView.animate(withDuration: 0.5, animations: {
                self.responseTextView.alpha = 1
            })
        }
    }
    
    @IBOutlet var phoneOrEmailTextField: UITextField!
    @IBOutlet var otpTextField: UITextField!
    @IBOutlet var channelTextField: UITextField!
    @IBOutlet var startHeadlessButton: UIButton!
    @IBOutlet var userIdTextField: UITextField!
    @IBOutlet var verifyOtpButton: UIButton!
    @IBOutlet var responseTextView: UITextView!
    @IBOutlet var copyResponseToClipboardButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setDelegates()
        setTapGestures()
        
        Otpless.sharedInstance.webviewInspectable = true
        Otpless.sharedInstance.initialise(vc: self, appId: ViewController.APPID)
        
        channelTextField.autocapitalizationType = .allCharacters
        responseTextView.isEditable = false
    }
    
    private func setDelegates() {
        // TextField delegate to dismiss keyboard when return key of keyboard is pressed
        channelTextField.delegate = self
        otpTextField.delegate = self
        phoneOrEmailTextField.delegate = self
        userIdTextField.delegate = self
        
        // Headless delegate
        Otpless.sharedInstance.headlessDelegate = self
    }
    
    private func setTapGestures() {
        let dismissKeyboardGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
         view.addGestureRecognizer(dismissKeyboardGesture)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @IBAction func verifyOtp() {
        let headlessRequest = HeadlessRequest()
                
        guard let channelType = channelTextField.text, channelType.count > 0 else {
            if let phoneNumber = Int64(phoneOrEmailTextField.text!) {
                headlessRequest.setPhoneNumber(number: String(phoneNumber), withCountryCode: "+91")
            } else {
                headlessRequest.setEmail(phoneOrEmailTextField.text ?? "")
            }
            
            if let otp = Int64(otpTextField.text!) {
                Otpless.sharedInstance.verifyOTP(otp: String(otp), headlessRequest: headlessRequest)
            }
            
            return
        }
        
        headlessRequest.setChannelType(channelType)
        
        if let otp = Int64(otpTextField.text!) {
            Otpless.sharedInstance.verifyOTP(otp: String(otp), headlessRequest: headlessRequest)
        }
    }
    
    @IBAction func startHeadless() {
        let headlessRequest = HeadlessRequest()
        
        if let userId = userIdTextField.text,
           !userId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Otpless.sharedInstance.initiateWebAuthn(withUserId: userId)
            return
        }
                
        guard let channelType = channelTextField.text, !channelType.isEmpty else {
            if let phoneNumber = Int64(phoneOrEmailTextField.text!) {
                headlessRequest.setPhoneNumber(number: String(phoneNumber), withCountryCode: "+91")
            } else {
                headlessRequest.setEmail(phoneOrEmailTextField.text ?? "")
            }
            
            Otpless.sharedInstance.startHeadless(headlessRequest: headlessRequest)
            return
        }
        
        headlessRequest.setChannelType(channelType)
        
        Otpless.sharedInstance.startHeadless(headlessRequest: headlessRequest)
    }
    
    @IBAction func copyToClipboard() {
        UIPasteboard.general.string = responseTextView.text
    }
}

extension HeadlessDemoVC: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
