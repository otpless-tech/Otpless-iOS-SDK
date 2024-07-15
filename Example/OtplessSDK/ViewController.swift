//
//  ViewController.swift
//  OtplessSDK
//
//  Created by 121038664 on 02/05/2023.
//  Copyright (c) 2023 121038664. All rights reserved.
//

import UIKit
import OtplessSDK

class ViewController: UIViewController, onResponseDelegate , onEventCallback{
    let startHeadlessButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Start Headless", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        return button
    }()
    
    func onEvent(eventCallback: OtplessSDK.OtplessEventResponse?) {
        guard let eventCodeInstance = eventCallback?.eventCode else {
            print("Event callback or event code is missing.")
            return
        }

        if let responseString = eventCallback?.responseString {
            switch eventCodeInstance {
            case .networkFailure:
                print("networkFailure - EventCallback: \(responseString)")
                // Handle network failure case using responseString

            case .userDismissed:
                print("userDismissed - EventCallback: \(responseString)")
                // Handle user dismissed case using responseString

            // You can add more cases if needed

            @unknown default:
                print("Unknown case.")
                // Handle any unknown cases that might occur
            }
        } else {
            print("No response string provided.")
        }
    }

    func onResponse(response: OtplessSDK.OtplessResponse?) {
        if (response?.errorString != nil) {
            print(response?.errorString ?? "no value in erro")
        } else {
            if (response != nil && response?.responseData != nil
                && response?.responseData?["data"] != nil){
                if let data = response?.responseData?["data"] as? [String: Any] {
                    let token = data["token"]
                    print(token ?? "no token")
                }
            }
            
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        Otpless.sharedInstance.delegate = self
        Otpless.sharedInstance.eventDelegate = self
        
        view.addSubview(startHeadlessButton)
        startHeadlessButton.addTarget(self, action: #selector(startHeadlessButtonTapped), for: .touchUpInside)
        NSLayoutConstraint.activate([
            startHeadlessButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startHeadlessButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100)
        ])
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func buttonclicked(_ sender: Any) {
        Otpless.sharedInstance.webviewInspectable = true
        Otpless.sharedInstance.showOtplessLoginPageWithParams(appId: "Y5QD4JEB7AMLZ3F5JR7U", vc: self, params: nil)
    }
    
    @objc func startHeadlessButtonTapped() {
        let headlessDemoVC = self.storyboard?.instantiateViewController(withIdentifier: "HeadlessDemoVC") as! HeadlessDemoVC
        self.navigationController?.pushViewController(headlessDemoVC, animated: true)
    }
}

