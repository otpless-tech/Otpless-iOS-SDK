//
//  HeadlessViewRepresentable.swift
//  OtplessSDK
//
//  Created by Sparsh on 08/04/24.
//

import Foundation
import SwiftUI
import UIKit

@available(iOS 13.0, *)
struct HeadlessViewRepresentable: UIViewRepresentable {    
    var headlessRequest: HeadlessRequest!
    
    func makeUIView(context: Context) -> OtplessView  {
        let view = OtplessView(headlessRequest: headlessRequest)
        UIApplication.shared.windows.first?.addSubview(view)
        Otpless.sharedInstance.otplessView = view
        return view
    }
    
    func updateUIView(_ uiView: OtplessView, context: Context) {
        
    }
}
