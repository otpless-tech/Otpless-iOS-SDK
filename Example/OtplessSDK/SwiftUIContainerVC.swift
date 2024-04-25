//
//  SwiftUIContainerVC.swift
//  OtplessSDK_Example
//
//  Created by Sparsh on 08/04/24.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import UIKit
import SwiftUI
import OtplessSDK

@available(iOS 13.0.0, *)
class SwiftUIContainerVC: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemPink
        let hostingController = UIHostingController(rootView: LoginPageSwiftUIView())
        addChildViewController(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        hostingController.didMove(toParent: self)
        Otpless.sharedInstance.webviewInspectable = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }
}

@available(iOS 13.0.0, *)
struct LoginPageSwiftUIView: View {
    @State private var isInitialized = false
    @State private var token: String = ""
    
    
    var body: some View {
        NavigationView {
            VStack {
                Text("This screen is made in SwiftUI")
                Button("Show Login Page") {
                    isInitialized.toggle()
                }
                .padding()
                
                if isInitialized {
                    Otpless.sharedInstance.swiftUILoginPage(
                        appId: "APPID",
                        onResponse: { response in
                            if let responseData = response?.responseData?["data"] as? [String: Any],
                               let token = responseData["token"] as? String {
                                
                                self.token = token
                            }
                            isInitialized = false
                        }
                    )
                }
                
                NavigationLink(destination: HeadlessDemoView()) {
                    Text("Start Headless SwiftUI")
                        .frame(width: 220, height: 50)
                        .foregroundColor(.blue)
                }
                
                Text("Token From Login Page: \(token)")
            }
        }
        .navigationBarBackButtonHidden()
    }
    
}


@available(iOS 13.0, *)
struct HeadlessDemoView: View {
    @State private var numberOrEmailText: String = ""
    @State private var otp: String = ""
    @State private var channel: String = ""
    @State private var startHeadless: Bool = false
    @State private var selectedChannel = HeadlessChannelType.sharedInstance.WHATSAPP
    @State private var headlessViewHeight = 0.0
    @State private var token: String = ""
    @State private var showChannels: Bool = true
    @State private var showOneTapUI: Bool = false
    @State var headlessRequest: HeadlessRequest?
    
    let channels = [
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
    
    @State private var height: Double = 0.0
    
    var body: some View {
        VStack {
            HStack {
                TextField("Enter email/number", text: $numberOrEmailText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Spacer(minLength: 20)
                
                Button("Start headless") {
                    let req = HeadlessRequest()
                    if !showChannels {
                        
                        if let phoneNumber = Int64(numberOrEmailText) {
                            req.setPhoneNumber(number: String(phoneNumber), withCountryCode: "+91")
                        } else {
                            req.setEmail(numberOrEmailText)
                        }
                    } else {
                        req.setChannelType(selectedChannel)
                    }
                    
                    startHeadless = true
                    
                    headlessRequest = req
                }
                .padding(8)
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(10)
            }
            .padding(10)
            
            HStack {
                TextField("OTP", text: $otp)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: UIScreen.main.bounds.width / 2)
                    .keyboardType(.numberPad)
                
                Spacer()
                
                Button("Verify OTP") {
                    Otpless.sharedInstance.verifyOTP(otp: otp, headlessRequest: headlessRequest)
                }
                .padding(8)
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(10)
            }
            .padding(10)
            
            HStack {
                TextField("Type/set channel", text: $selectedChannel)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: UIScreen.main.bounds.width / 2)
                Spacer()
                
                Button("Show One Tap UI") {
                    showOneTapUI = true
                }
            }
            .padding(10)
            
            Toggle("Use channels", isOn: $showChannels)
                .padding()
            
            if showChannels {
                Picker("Channels", selection: $selectedChannel) {
                    ForEach(channels, id: \.self) { channel in
                        Text(channel)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .padding(10)
            }
            
            if !token.isEmpty {
                Text("Token - \(token)")
            }
            
            Spacer()
            
            if startHeadless {
                Otpless.sharedInstance.swiftUIHeadlessView(
                    appId: "APPID",
                    headlessRequest: headlessRequest!
                ) { response in
                    print("Response - \(response?.responseData)")
                    if let token = response?.responseData?["token"] as? String {
                        self.token = token
                    }
                    startHeadless = false
                }
            }
        }
    }
    
    func onOtplessCallback(response: HeadlessResponse?) {
        if let token = response?.responseData?["token"] as? String {
            self.token = token
        }
    }
}

@available(iOS 15.0, *)
struct HeadlessDemoView_Previews: PreviewProvider {
    static var previews: some View {
        HeadlessDemoView()
    }
}
