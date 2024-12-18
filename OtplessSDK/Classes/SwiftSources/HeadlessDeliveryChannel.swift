//
//  HeadlessChannel.swift
//  OtplessSDK
//
//  Created by Sparsh on 28/03/24.
//

import Foundation

@objc internal class HeadlessDeliveryChannel: NSObject {
    @objc static let WHATSAPP = "WHATSAPP"
    @objc static let SMS = "SMS"
    @objc static let VIBER = "VIBER"
    @objc static let PHONECALL = "PHONECALL"
    
    @objc private var selectedDeliveryChannel: String = ""

    @objc func getSelectedDeliveryChannel() -> String {
        return selectedDeliveryChannel
    }
    
    @objc func setDeliveryChannel(channel: String) {
        self.selectedDeliveryChannel = channel
    }
}
