//
//  Constants.swift
//  OtplessSDK
//
//  Created by Sparsh on 06/01/25.
//

import Foundation

class Constants {
    static let KEY_LAST_URL_CACHE_COMPLETION_TIME = "otpless_url_cache_complete_time"
    static let URL_CACHE_SUPPORTED = "urlCacheSupported"
    static let URL_CACHE_EPOCH = "urlCacheEpoch"
    static let KEY_URL_CACHE_LINKED_TSID = "otpless_url_cache_linked_tsid"
}

class EventConstants {
    static let INIT_HEADLESS = "native_init_headless"
    static let SET_HEADLESS_CALLBACK = "native_set_headless_callback"
    static let START_HEADLESS = "native_start_headless"
    static let SHOW_LOGIN_PAGE = "native_show_login_page"
    static let SET_LOGIN_PAGE_CALLBACK = "native_set_login_page_callback"
    
    static let CLOSE_VIEW = "native_close_view"
    
    static let REQUEST_PUSHED_WEB = "native_request_pushed_web"
    static let WEBVIEW_ADDED = "native_webview_added"
    static let LOAD_URL = "native_load_url"
    static let JS_INJECT = "native_js_inject"
    static let WEBVIEW_URL_LOAD_SUCCESS = "native_webview_url_load_success"
    static let WEBVIEW_URL_LOAD_FAIL = "native_webview_url_load_fail"
    
    static let HEADLESS_REQUEST = "native_headless_request"
    static let HEADLESS_REQUEST_QUERY_WEB = "native_headless_request_query_web"
    static let HEADLESS_RESPONSE_WEB = "native_headless_response_web"
    static let LOGINPAGE_RESPONSE_WEB = "native_loginpage_response_web"
    
    static let DEEPLINK_WEB = "native_deeplink_web"
    static let GOOGLE_SDK_WEB = "native_google_sdk_web"
    static let FACEBOOK_SDK_WEB = "native_facebook_sdk_web"
    static let APPLE_SDK_WEB = "native_apple_sdk_web"
    static let LOGIN_SDK_CALLBACK = "native_login_sdk_callback"
    static let LOGIN_SDK_CALLBACK_EXP = "native_login_sdk_callback_exp"
    static let HEADLESS_TIMEOUT = "native_headless_timeout"
    static let HEADLESS_MERCHANT_COMMIT = "native_headless_merchant_commit"
    
    static let SNA_CALLBACK_RESULT = "native_sna_callback_result"
    
    static let HEADLESS_EMPTY_RESPONSE_WEB = "native_headless_empty_response_web"
}
