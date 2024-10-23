//
//  HeadlessDemoVC.swift
//  OtplessSDK_Example
//
//  Created by Sparsh on 28/03/24.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import UIKit
import OtplessSDK

class CustomHeadlessVC: UIViewController, onHeadlessResponseDelegate {
    func onHeadlessResponse(response: OtplessSDK.HeadlessResponse?) {
        print("Response - \(String(describing: response?.responseData))")
        responseTextView.text = "STATUS CODE: " + String(describing: response?.statusCode) + "\n" + "RESPONSE TYPE: " + String(describing: response?.responseType) + "\n" + "RESPONSE : " + String(describing: response?.responseData);
        if response?.statusCode != 200 {
           
        } else {
            if let userDetails = response?.responseData {
                DispatchQueue.main.async {
                    let token = userDetails["token"] as? String ?? ""
                    if token.isEmpty {
                        
                    } else {
                        
                    }
                }
            }
        }
    }
    
    @IBOutlet var phoneOrEmailTextField: UITextField!
    @IBOutlet var otpTextField: UITextField!
    @IBOutlet var channelTextField: UITextField!
    @IBOutlet var otpLengthTextField: UITextField!
    @IBOutlet var expiryTextField: UITextField!
    @IBOutlet var startHeadlessButton: UIButton!
    @IBOutlet var verifyOtpButton: UIButton!
    @IBOutlet var responseTextView: UITextView!
    private var typedChannel = false
    
    
    var selectedChannel: String = HeadlessChannelType.sharedInstance.WHATSAPP
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Otpless.sharedInstance.webviewInspectable = true
        
        channelTextField.delegate = self
        otpTextField.delegate = self
        phoneOrEmailTextField.delegate = self
        Otpless.sharedInstance.initialise(vc: self, appId: ViewController.APPID)
        Otpless.sharedInstance.headlessDelegate = self
        
        let dismissKeyboardGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(dismissKeyboardGesture)
        
        channelTextField.autocapitalizationType = .allCharacters
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @IBAction func verifyOtp() {
        dismissKeyboard()
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
        
        
        if let otp = Int64(otpTextField.text!) {
            Otpless.sharedInstance.verifyOTP(otp: String(otp), headlessRequest: headlessRequest)
        }
    }
    
    @IBAction func startHeadless() {
        dismissKeyboard()
        let headlessRequest = HeadlessRequest()
        
            if let phoneNumber = Int64(phoneOrEmailTextField.text!) {
                headlessRequest.setPhoneNumber(number: String(phoneNumber), withCountryCode: "+91")
            } else {
                headlessRequest.setEmail(phoneOrEmailTextField.text ?? "")
            }
        if let channel = channelTextField.text {
            headlessRequest.setDeliveryChannel(channel)
        }
        if let expiry = expiryTextField.text {
            headlessRequest.setExpiry(expiry: expiry)
        }
        if let otpLength = otpLengthTextField.text {
            headlessRequest.setOtpLength(otpLength: otpLength)
        }
        
        Otpless.sharedInstance.startHeadless(headlessRequest: headlessRequest)
    }
    
    @IBAction func copyResponse() {
        let pasteboard = UIPasteboard.general
        pasteboard.string = responseTextView.text
    }
}

extension CustomHeadlessVC: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}
