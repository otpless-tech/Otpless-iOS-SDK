//
//  HeadlessDemoVC.swift
//  OtplessSDK_Example
//
//  Created by Sparsh on 28/03/24.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import UIKit
import OtplessSDK
import AppTrackingTransparency
import AdSupport

class HeadlessDemoVC: UIViewController, onHeadlessResponseDelegate {
    func onHeadlessResponse(response: OtplessSDK.HeadlessResponse?) {
        print("Response - \(String(describing: response?.responseData))")
        if response?.statusCode != 200 {
            DispatchQueue.main.async {
                let alertController = UIAlertController(title: "Error", message: "\(response?.responseData as? [String: Any])", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default) { _ in
                    // Handle OK button tap
                }
                alertController.addAction(okAction)
                self.present(alertController, animated: true, completion: nil)
            }
        } else {
            if let userDetails = response?.responseData {
                DispatchQueue.main.async {
                    self.view.addSubview(self.tokenLabel)
                    NSLayoutConstraint.activate([
                        self.tokenLabel.topAnchor.constraint(equalTo: self.setChannelButton.bottomAnchor, constant: 20),
                        self.tokenLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20),
                        self.tokenLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20),
                        self.tokenLabel.bottomAnchor.constraint(equalTo: self.channelPickerSwitch.topAnchor, constant: -20)
                    ])
                    let token = userDetails["token"] as? String ?? ""
                    if token.isEmpty {
                        self.tokenLabel.text = """
                        responseType - \(response?.responseType)\n
                        status code - \(response?.statusCode)\n
                        response - \(userDetails)
                    """
                    } else {
                        self.tokenLabel.text = """
                        responseType - \(response?.responseType)\n
                        status code - \(response?.statusCode)\n
                        token - \(token)
                    """
                    }
                }
            }
        }
    }
    
    @IBOutlet var phoneOrEmailTextField: UITextField!
    @IBOutlet var otpTextField: UITextField!
    @IBOutlet var channelTextField: UITextField!
    @IBOutlet var startHeadlessButton: UIButton!
    @IBOutlet var setChannelButton: UIButton!
    @IBOutlet var verifyOtpButton: UIButton!
    @IBOutlet var channelPicker: UIPickerView!
    @IBOutlet var channelPickerSwitch: UISwitch!
    private var typedChannel = false
    private let tokenLabel: UILabel = {
       let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()
   
    let channels = [
        HeadlessChannelType.sharedInstance.FACEBOOK_SDK,
        HeadlessChannelType.sharedInstance.GOOGLE_SDK,
        HeadlessChannelType.sharedInstance.WHATSAPP,
        HeadlessChannelType.sharedInstance.GMAIL,
        HeadlessChannelType.sharedInstance.APPLE,
        HeadlessChannelType.sharedInstance.TWITTER,
        HeadlessChannelType.sharedInstance.DISCORD,
        HeadlessChannelType.sharedInstance.SLACK,
        HeadlessChannelType.sharedInstance.FACEBOOK,
        HeadlessChannelType.sharedInstance.LINKEDIN,
        HeadlessChannelType.sharedInstance.MICROSOFT,
        HeadlessChannelType.sharedInstance.LINE,
        HeadlessChannelType.sharedInstance.LINEAR,
        HeadlessChannelType.sharedInstance.NOTION,
        HeadlessChannelType.sharedInstance.TWITCH,
        HeadlessChannelType.sharedInstance.GITHUB,
        HeadlessChannelType.sharedInstance.BITBUCKET,
        HeadlessChannelType.sharedInstance.ATLASSIAN,
        HeadlessChannelType.sharedInstance.GITLAB
    ]
    
    var selectedChannel: String = HeadlessChannelType.sharedInstance.FACEBOOK_SDK
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Otpless.sharedInstance.webviewInspectable = true
        channelPicker.dataSource = self
        channelPicker.delegate = self
        channelTextField.delegate = self
        otpTextField.delegate = self
        phoneOrEmailTextField.delegate = self
        Otpless.sharedInstance.initialise(vc: self, appId: ViewController.APPID)
        Otpless.sharedInstance.headlessDelegate = self
        
        let dismissKeyboardGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
         view.addGestureRecognizer(dismissKeyboardGesture)
        
        channelTextField.autocapitalizationType = .allCharacters
        
        requestTrackingPermission()
    }
    
    
    func requestTrackingPermission() {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                switch status {
                case .authorized:
                    print("User granted tracking permission")
                    // Proceed with tracking

                case .denied:
                    print("User denied tracking permission")

                case .notDetermined:
                    print("User has not yet been asked for tracking permission")

                case .restricted:
                    print("User cannot grant tracking permission due to restrictions")
                    
                @unknown default:
                    print("Unknown authorization status")
                }
            }
        } else {
            print("Tracking permission not required for iOS versions below 14")
            // For older iOS versions, proceed without tracking
        }
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
    
    @IBAction func setChannel() {
        if !typedChannel {
            self.channelTextField.text = selectedChannel
        }
    }
    
    @IBAction func switchValueChanged(_ sender: UISwitch) {
        if sender.isOn {
            channelPicker.isHidden = false
            self.typedChannel = false
        } else {
            channelPicker.isHidden = true
            self.typedChannel = true
        }
    }
}

extension HeadlessDemoVC: UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return channels.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return channels[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedChannel = channels[row]
    }
}
