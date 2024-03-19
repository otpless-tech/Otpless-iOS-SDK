//
//  HeadlessChannel.swift
//  OtplessSDK
//
//  Created by Sparsh on 08/02/24.
//

import Foundation

@objc public class HeadlessChannel: NSObject {
    @objc static let PHONE = "PHONE"
    @objc static let EMAIL = "EMAIL"
    @objc static let OAUTH = "OAUTH"
    
    @objc private var selectedChannel: String = "PHONE"

    @objc func getSelectedChannel() -> String {
        return selectedChannel
    }
    
    @objc func setChannel(channel: String) {
        self.selectedChannel = channel
    }
}
