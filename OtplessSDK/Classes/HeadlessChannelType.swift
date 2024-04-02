//
//  HeadlessChannelType.swift
//  OtplessSDK
//
//  Created by Sparsh on 28/03/24.
//

import Foundation

@objc public class HeadlessChannelType: NSObject {
    @objc public let WHATSAPP = "WHATSAPP"
    @objc public let GMAIL = "GMAIL"
    @objc public let APPLE = "APPLE"
    @objc public let TWITTER = "TWITTER"
    @objc public let DISCORD = "DISCORD"
    @objc public let SLACK = "SLACK"
    @objc public let FACEBOOK = "FACEBOOK"
    @objc public let LINKEDIN = "LINKEDIN"
    @objc public let MICROSOFT = "MICROSOFT"
    @objc public let LINE = "LINE"
    @objc public let LINEAR = "LINEAR"
    @objc public let NOTION = "NOTION"
    @objc public let TWITCH = "TWITCH"
    @objc public let GITHUB = "GITHUB"
    @objc public let BITBUCKET = "BITBUCKET"
    @objc public let ATLASSIAN = "ATLASSIAN"
    @objc public let GITLAB = "GITLAB"
    
    @objc public static var sharedInstance : HeadlessChannelType = {
        let instance = HeadlessChannelType()
        return instance
    }()
    
    private var selectedChannelType: String = ""

    @objc func getSelectedChannelType() -> String {
        return selectedChannelType
    }
    
    @objc func setChannelType(channelType: String) {
        self.selectedChannelType = channelType
    }
}
