//
//  ViewController.swift
//  OtplessSDK
//
//  Created by 121038664 on 02/05/2023.
//  Copyright (c) 2023 121038664. All rights reserved.
//

import UIKit
import OtplessSDK

class ViewController: UIViewController, onResponseDelegate, onEventCallback {
    static var logs: [CustomLog] = []
    
    static let APPID = ""
    
    @IBOutlet var showLoginPageButton: UIButton!
    
    private let startHeadlessButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Start Headless", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        return button
    }()
    
    private let startCustomHeadlessButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Start Custom Headless", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        return button
    }()
    
    
    private let navigateToLoggingVCButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Show Logs", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        return button
    }()
    
    private let copyResponseButton: UIButton = {
       let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Copy Response", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        return button
    }()
    
    private let responseLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .black
        label.numberOfLines = 0
        return label
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
        if let errorString = response?.errorString {
            DispatchQueue.main.async {
                self.responseLabel.text = errorString
            }
        } else if let responseData = response?.responseData {
            DispatchQueue.main.async {
                self.responseLabel.text = "\(responseData)"
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setDelegates()
        setupUI()
        addTargets()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}


extension ViewController: OtplessLoggerDelegate {
    
    private func setDelegates() {
        Otpless.sharedInstance.delegate = self
        Otpless.sharedInstance.eventDelegate = self
        Otpless.sharedInstance.setLoggerDelegate(delegate: self)
        Otpless.sharedInstance.webviewInspectable = true
    }
    
    private func addTargets() {
        navigateToLoggingVCButton.addTarget(self, action: #selector(navigateToLoggerVCButtonTapped), for: .touchUpInside)
        
        startHeadlessButton.addTarget(self, action: #selector(startHeadlessButtonTapped), for: .touchUpInside)
        startCustomHeadlessButton.addTarget(self, action: #selector(startCustomHeadlessButtonTapped), for: .touchUpInside)
        
        copyResponseButton.addTarget(self, action: #selector(copyResponseButtonTapped), for: .touchUpInside)
    }
    
    @IBAction func buttonclicked(_ sender: Any) {
        Otpless.sharedInstance.showOtplessLoginPageWithParams(appId: ViewController.APPID, vc: self, params: nil)
    }
    
    @objc func startHeadlessButtonTapped() {
        let headlessDemoVC = self.storyboard?.instantiateViewController(withIdentifier: "HeadlessDemoVC") as! HeadlessDemoVC
        self.navigationController?.pushViewController(headlessDemoVC, animated: true)
    }
    @objc func startCustomHeadlessButtonTapped() {
        let headlessDemoVC = self.storyboard?.instantiateViewController(withIdentifier: "CustomHeadlessVC") as! CustomHeadlessVC
        self.navigationController?.pushViewController(headlessDemoVC, animated: true)
    }
    
    @objc func navigateToLoggerVCButtonTapped() {
        let vc = LoggerVC()
        present(vc, animated: true)
    }
    
    @objc func copyResponseButtonTapped() {
        if let response = responseLabel.text, !response.trimmingCharacters(in: .whitespaces).isEmpty {
            UIPasteboard.general.string = response
        }
    }
    
    private func setupUI() {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .equalSpacing
        stackView.spacing = 16
        
        scrollView.addSubview(stackView)
        
        // Add buttons and label to stackView
        stackView.addArrangedSubview(showLoginPageButton)
        stackView.addArrangedSubview(startHeadlessButton)
        stackView.addArrangedSubview(startCustomHeadlessButton)
        stackView.addArrangedSubview(navigateToLoggingVCButton)
        stackView.addArrangedSubview(copyResponseButton)
        stackView.addArrangedSubview(responseLabel)
        
        // Set constraints for scrollView
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Set constraints for stackView
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        showLoginPageButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        startHeadlessButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        startCustomHeadlessButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        copyResponseButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
}


extension ViewController {
    
    func otplessLog(string: String, type: String) {
        ViewController.logs.append(CustomLog(type: type, message: string, time: getCurrentTime()))
    }

    private func getCurrentTime() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter.string(from: Date())
    }
}

struct CustomLog {
    let type: String
    let message: String
    let time: String
}
