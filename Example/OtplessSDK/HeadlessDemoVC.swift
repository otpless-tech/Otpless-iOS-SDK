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
        if let errorString = response?.errorString {
            DispatchQueue.main.async {
                let alertController = UIAlertController(title: "Error", message: errorString, preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default) { _ in
                    // Handle OK button tap
                }
                alertController.addAction(okAction)
                self.present(alertController, animated: true, completion: nil)
            }
        } else {
            if let userDetails = response?.responseData {
                DispatchQueue.main.async {
                    self.setupNameAndNumberLabel(userDetails)
                }
            }
        }
    }
    
    private func setupNameAndNumberLabel(_ userDetails: [String: Any]) {
        let margins = view.layoutMarginsGuide
        view.addSubview(tokenLabel)
        view.addSubview(nameLabel)
        view.addSubview(numberLabel)
        view.addSubview(emailLabel)
        
        tokenLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        emailLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tokenLabel.topAnchor.constraint(equalTo: verifyCodeOrOtpButton.bottomAnchor, constant: 20),
            tokenLabel.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: 20),
            tokenLabel.trailingAnchor.constraint(equalTo: margins.trailingAnchor, constant: -20),
            
            nameLabel.topAnchor.constraint(equalTo: tokenLabel.bottomAnchor, constant: 20),
            nameLabel.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(equalTo: margins.trailingAnchor, constant: -20),
            
            numberLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 20),
            numberLabel.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: 20),
            numberLabel.trailingAnchor.constraint(equalTo: margins.trailingAnchor, constant: -20),
            
            emailLabel.topAnchor.constraint(equalTo: numberLabel.bottomAnchor, constant: 20),
            emailLabel.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: 20),
            emailLabel.trailingAnchor.constraint(equalTo: margins.trailingAnchor, constant: -20),
        ])
        
        tokenLabel.textColor = .black
        nameLabel.textColor = .black
        numberLabel.textColor = .black
        emailLabel.textColor = .black
        
        tokenLabel.numberOfLines = 0
        nameLabel.numberOfLines = 0
        numberLabel.numberOfLines = 0
        emailLabel.numberOfLines = 0
        
        let response = userDetails["response"] as? [String: Any]
        
        tokenLabel.text = "Token - \(response?["token"] as? String ?? "Unable to get token")"
        
        if let identities = response?["identities"] as? [[String: Any]] {
            
            for identity in identities {
                if let name = identity["name"] as? String {
                    nameLabel.text = name
                }
                if let identityValue = identity["identityValue"] as? String,
                   let identityType = identity["identityType"] as? String {
                    if identityType == "EMAIL" {
                        emailLabel.text = identityValue
                    } else {
                        numberLabel.text = identityValue
                    }
                }
            }
        }
    }
    
    private let phoneOrEmailTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.layer.cornerRadius = 15
        textField.layer.borderWidth = 0
        textField.textColor = .black
        textField.tintColor = .black
        textField.font = UIFont.preferredFont(forTextStyle: .title2)
        textField.adjustsFontSizeToFitWidth = true
        textField.minimumFontSize = 12
        textField.backgroundColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1)
        textField.autocorrectionType = .no
        textField.textAlignment = .center
        
        if #available(iOS 13.0, *) {
            textField.attributedPlaceholder = NSAttributedString(string: "Enter number or email id", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        } else {
            textField.placeholder = "Enter number or email id"
        }
        return textField
    }()
    
    private let otpOrCodeTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.layer.cornerRadius = 15
        textField.layer.borderWidth = 0
        textField.textColor = .black
        textField.tintColor = .black
        textField.font = UIFont.preferredFont(forTextStyle: .title2)
        textField.adjustsFontSizeToFitWidth = true
        textField.minimumFontSize = 12
        textField.backgroundColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1)
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.textAlignment = .center
        
        if #available(iOS 13.0, *) {
            textField.attributedPlaceholder = NSAttributedString(string: "Enter otp/code", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        } else {
            textField.placeholder = "Enter otp/code"
        }
        
        return textField
    }()
    
    private let channelTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.layer.cornerRadius = 15
        textField.layer.borderWidth = 0
        textField.textColor = .black
        textField.tintColor = .black
        textField.font = UIFont.preferredFont(forTextStyle: .title2)
        textField.adjustsFontSizeToFitWidth = true
        textField.minimumFontSize = 12
        textField.backgroundColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1)
        textField.autocorrectionType = .no
        textField.textAlignment = .center
        textField.autocapitalizationType = .allCharacters
        
        if #available(iOS 13.0, *) {
            textField.attributedPlaceholder = NSAttributedString(string: "Enter channel", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        } else {
            textField.placeholder = "Enter channel"
        }
        
        return textField
    }()
    
    private let startHeadlessButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Start Headless", for: .normal)
        button.layer.cornerRadius = 15
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        return button
    }()
    
    private let verifyCodeOrOtpButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Verify Code/OTP", for: .normal)
        button.layer.cornerRadius = 15
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        return button
    }()
    
    private let tokenLabel = UILabel()
    private let nameLabel = UILabel()
    private let numberLabel = UILabel()
    private let emailLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        Otpless.sharedInstance.headlessDelegate = self
    }
    
    private func configureViews() {
        view.backgroundColor = .white
        addViews()
        addConstraints()
        
        startHeadlessButton.addTarget(self, action: #selector(startHeadless), for: .touchUpInside)
        verifyCodeOrOtpButton.addTarget(self, action: #selector(verifyCodeOrOtp), for: .touchUpInside)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func addViews() {
        view.addSubview(phoneOrEmailTextField)
        view.addSubview(otpOrCodeTextField)
        view.addSubview(channelTextField)
        view.addSubview(startHeadlessButton)
        view.addSubview(verifyCodeOrOtpButton)
    }
    
    private func addConstraints() {
        let margins = view.layoutMarginsGuide
        
        NSLayoutConstraint.activate([
            phoneOrEmailTextField.topAnchor.constraint(equalTo: margins.topAnchor, constant: 20),
            phoneOrEmailTextField.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: 20),
            phoneOrEmailTextField.trailingAnchor.constraint(equalTo: margins.trailingAnchor, constant: -20),
            phoneOrEmailTextField.heightAnchor.constraint(equalToConstant: 50),
            
            otpOrCodeTextField.topAnchor.constraint(equalTo: phoneOrEmailTextField.bottomAnchor, constant: 20),
            otpOrCodeTextField.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: 20),
            otpOrCodeTextField.trailingAnchor.constraint(equalTo: margins.trailingAnchor, constant: -20),
            otpOrCodeTextField.heightAnchor.constraint(equalToConstant: 50),
            
            channelTextField.topAnchor.constraint(equalTo: otpOrCodeTextField.bottomAnchor, constant: 20),
            channelTextField.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: 20),
            channelTextField.trailingAnchor.constraint(equalTo: margins.trailingAnchor, constant: -20),
            channelTextField.heightAnchor.constraint(equalToConstant: 50),
            
            startHeadlessButton.topAnchor.constraint(equalTo: channelTextField.bottomAnchor, constant: 20),
            startHeadlessButton.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: 20),
            startHeadlessButton.trailingAnchor.constraint(equalTo: margins.trailingAnchor, constant: -20),
            startHeadlessButton.heightAnchor.constraint(equalToConstant: 50),
            
            verifyCodeOrOtpButton.topAnchor.constraint(equalTo: startHeadlessButton.bottomAnchor, constant: 20),
            verifyCodeOrOtpButton.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: 20),
            verifyCodeOrOtpButton.trailingAnchor.constraint(equalTo: margins.trailingAnchor, constant: -20),
            verifyCodeOrOtpButton.heightAnchor.constraint(equalToConstant: 50),
        ])
    }
    
    @objc func startHeadless() {
        let headlessRequest = HeadlessRequest(appId: "YOUR_APPID")
        
        guard let channelText = channelTextField.text else {
            print("No channel provided")
            return
        }
        
        var channelType: String?
        switch channelText.lowercased() {
        case "whatsapp":
            channelType = HeadlessChannelType.sharedInstance.WHATSAPP
        case "gmail":
            channelType = HeadlessChannelType.sharedInstance.GMAIL
        case "apple":
            channelType = HeadlessChannelType.sharedInstance.APPLE
        case "twitter":
            channelType = HeadlessChannelType.sharedInstance.TWITTER
        case "discord":
            channelType = HeadlessChannelType.sharedInstance.DISCORD
        case "slack":
            channelType = HeadlessChannelType.sharedInstance.SLACK
        case "facebook":
            channelType = HeadlessChannelType.sharedInstance.FACEBOOK
        case "linkedin":
            channelType = HeadlessChannelType.sharedInstance.LINKEDIN
        case "microsoft":
            channelType = HeadlessChannelType.sharedInstance.MICROSOFT
        case "line":
            channelType = HeadlessChannelType.sharedInstance.LINE
        case "linear":
            channelType = HeadlessChannelType.sharedInstance.LINEAR
        case "notion":
            channelType = HeadlessChannelType.sharedInstance.NOTION
        case "twitch":
            channelType = HeadlessChannelType.sharedInstance.TWITCH
        case "github":
            channelType = HeadlessChannelType.sharedInstance.GITHUB
        case "bitbucket":
            channelType = HeadlessChannelType.sharedInstance.BITBUCKET
        case "atlassian":
            channelType = HeadlessChannelType.sharedInstance.ATLASSIAN
        case "gitlab":
            channelType = HeadlessChannelType.sharedInstance.GITLAB
        default:
            print("channelType - nil, Channel - phone/email")
        }
        
        guard let channelType = channelType else {
            if let phoneNumber = Int64(phoneOrEmailTextField.text!) {
                headlessRequest.setPhoneNumber(number: String(phoneNumber), withCountryCode: "+91")
            } else {
                headlessRequest.setEmail(phoneOrEmailTextField.text ?? "")
            }
            
            Otpless.sharedInstance.startHeadless(vc: self, headlessRequest: headlessRequest)
            return
        }
        
        headlessRequest.setChannelType(channelType)
        
        Otpless.sharedInstance.startHeadless(vc: self, headlessRequest: headlessRequest)
    }
    
    @objc func verifyCodeOrOtp() {
        
        let headlessRequest = HeadlessRequest(appId: "YOUR_APPID")
        
        guard let channelText = channelTextField.text else {
            print("No channel provided")
            return
        }

        var channelType: String?
        switch channelText.lowercased() {
        case "whatsapp":
            channelType = HeadlessChannelType.sharedInstance.WHATSAPP
        case "gmail":
            channelType = HeadlessChannelType.sharedInstance.GMAIL
        case "apple":
            channelType = HeadlessChannelType.sharedInstance.APPLE
        case "twitter":
            channelType = HeadlessChannelType.sharedInstance.TWITTER
        case "discord":
            channelType = HeadlessChannelType.sharedInstance.DISCORD
        case "slack":
            channelType = HeadlessChannelType.sharedInstance.SLACK
        case "facebook":
            channelType = HeadlessChannelType.sharedInstance.FACEBOOK
        case "linkedin":
            channelType = HeadlessChannelType.sharedInstance.LINKEDIN
        case "microsoft":
            channelType = HeadlessChannelType.sharedInstance.MICROSOFT
        case "line":
            channelType = HeadlessChannelType.sharedInstance.LINE
        case "linear":
            channelType = HeadlessChannelType.sharedInstance.LINEAR
        case "notion":
            channelType = HeadlessChannelType.sharedInstance.NOTION
        case "twitch":
            channelType = HeadlessChannelType.sharedInstance.TWITCH
        case "github":
            channelType = HeadlessChannelType.sharedInstance.GITHUB
        case "bitbucket":
            channelType = HeadlessChannelType.sharedInstance.BITBUCKET
        case "atlassian":
            channelType = HeadlessChannelType.sharedInstance.ATLASSIAN
        case "gitlab":
            channelType = HeadlessChannelType.sharedInstance.GITLAB
        default:
            print("channelType - nil, Channel - phone/email")
        }
        
        guard let channelType = channelType else {
            if let phoneNumber = Int64(phoneOrEmailTextField.text!) {
                headlessRequest.setPhoneNumber(number: String(phoneNumber), withCountryCode: "+91")
            } else {
                headlessRequest.setEmail(phoneOrEmailTextField.text ?? "")
            }

            
            if let otp = Int64(otpOrCodeTextField.text!) {
                Otpless.sharedInstance.verifyOTP(otp: String(otp), headlessRequest: headlessRequest)
            } else {
                Otpless.sharedInstance.verifyCode(code: otpOrCodeTextField.text!, headlessRequest: headlessRequest)
            }
            
            return
        }
        
        headlessRequest.setChannelType(channelType)
        
        if let otp = Int64(otpOrCodeTextField.text!) {
            Otpless.sharedInstance.verifyOTP(otp: String(otp), headlessRequest: headlessRequest)
        } else {
            Otpless.sharedInstance.verifyCode(code: otpOrCodeTextField.text!, headlessRequest: headlessRequest)
        }
    }
}
