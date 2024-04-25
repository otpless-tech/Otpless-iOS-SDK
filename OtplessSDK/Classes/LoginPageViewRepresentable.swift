//
//  LoginPageViewRepresentable.swift
//  OtplessSDK
//
//  Created by Sparsh on 08/04/24.
//

import Foundation
import SwiftUI
import UIKit

@available(iOS 13.0, *)
struct LoginPageViewRepresentable: UIViewRepresentable {
    
    func makeUIView(context: Context) -> some UIView {
        let view = OtplessView(isLoginPage: true)
        UIApplication.shared.windows.first?.addSubview(view)
        Otpless.sharedInstance.otplessView = view
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
}
