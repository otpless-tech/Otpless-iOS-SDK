//
//  OtplessSwiftUI.swift
//  OtplessSDK
//
//  Created by Sparsh on 25/04/24.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)
final class SwiftUISupport: NSObject {
    var responseCallback: ((OtplessResponse?) -> Void)?
    var headlessResponseCallback: ((HeadlessResponse?) -> Void)?
    var otplessView: OtplessView!
    static let sharedInstance = SwiftUISupport()
    
    private func getHeightFromHeightPercent(_ heightPercent: Int) -> Double {
        if heightPercent < 0 || heightPercent > 100 {
            return UIScreen.main.bounds.height
        } else {
            return ((CGFloat(heightPercent) * UIScreen.main.bounds.height) / 100 )
        }
    }
    
    public func initializeLoginPage(
        data: @escaping (OtplessResponse?) -> (Void)
    ) -> some View {
        self.responseCallback = data
        let loginPageSwiftUIView = LoginPageViewRepresentable()
            .frame(height: UIScreen.main.bounds.height)
        
        return loginPageSwiftUIView
    }
    
    func setResponseInCallback(_ response: OtplessResponse) {
        responseCallback!(response)
    }
    
    public func startHeadlessSwiftUI(
        headlessRequest: HeadlessRequest,
        data: @escaping (HeadlessResponse?) -> Void
    ) -> some View {
        self.headlessResponseCallback = data
        let headlessViewSwiftUI = HeadlessViewRepresentable(headlessRequest: headlessRequest)
        
        return headlessViewSwiftUI
    }
    
    func setHeadlessResponseInCallback(_ response: HeadlessResponse?) {
        if headlessResponseCallback != nil {
            headlessResponseCallback!(response)
        }
    }
}
