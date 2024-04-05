//
//  HeadlessChannel.swift
//  OtplessSDK
//
//  Created by Sparsh on 28/03/24.
//

import Foundation

@objc internal class HeadlessChannel: NSObject {
    @objc static let PHONE = "PHONE"
    @objc static let EMAIL = "EMAIL"
    @objc static let OAUTH = "OAUTH"
    
    @objc private var selectedChannel: String = ""

    @objc func getSelectedChannel() -> String {
        return selectedChannel
    }
    
    @objc func setChannel(channel: String) {
        self.selectedChannel = channel
    }
}
