//
//  OtplessViewExtensions.swift
//  OtplessSDK
//
//  Created by Sparsh on 28/03/24.
//

import Foundation
import UIKit
import WebKit

extension OtplessView: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == self.messageName {
            bridge.parseScriptMessage(message: message, webview: self.mWebView)
        }
    }
}

extension OtplessView: BridgeDelegate {
    func showLoader() {
        if !isHeadless {
            self.loader.show()
        }
    }
    
    func hideLoader() {
        if !isHeadless {
            self.loader.hide()
        }
    }
    
    func dismissView() {
        self.mWebView.isHidden = true
        self.removeFromSuperview()
        OtplessHelper.sendEvent(event: "sdk_screen_dismissed")
    }
}

extension OtplessView: OtplessLoaderDelegate {
    func loaderCloseButtonTapped() {
        if !isHeadless {
            self.loader.hide()
        }
        
        let otplessResponse = OtplessResponse(responseString: "Connection Error User Cancelled", responseData: nil)
        Otpless.sharedInstance.delegate?.onResponse(response: otplessResponse)
        self.mWebView.isHidden = true
        self.removeFromSuperview()
        OtplessHelper.sendEvent(event: "user_abort_connection_error")
    }
    
    func loaderRetryButtonTapped() {
        reloadUrl()
    }
}

extension OtplessView: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if !isHeadless {
            loader.hide()
        }

        guard let urlError = error as? URLError else {
            // Handle other types of errors if needed
            
            return
        }
        
        if [
            .notConnectedToInternet,
            .cannotFindHost,
            .cannotConnectToHost,
            .networkConnectionLost,
            .timedOut,
            .unsupportedURL
        ].contains(urlError.code)  {
            Otpless.sharedInstance.eventDelegate?.onEvent(
                eventCallback: OtplessEventResponse(
                    responseString: error.localizedDescription,
                    responseData: nil,
                    eventCode: .networkFailure
                )
            )
            
            if isHeadless {
                if let request = headlessRequest,
                   !request.isEmpty()
                {
                    Otpless.sharedInstance.headlessDelegate?.onHeadlessResponse(
                        response: HeadlessResponse(
                            responseType: "INTERNET_ERR",
                            responseData: [
                                "statusCode": 5002,
                                "response": [
                                    "message": "Internet Error."
                                ]
                            ],
                            errorString: urlError.localizedDescription.description
                        )
                    )
                }
                
                Otpless.sharedInstance.dismissOtplessView(true)
            } else {
                loader.showWithErrorAndRetry(errorText: "Connection error" + " : " + error.localizedDescription.description)
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if !isHeadless {
            loader.hide()
        }
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if !isHeadless {
            loader.hide()
        }
     
        guard let urlError = error as? URLError else {
            // Handle other types of errors if needed
            
            return
        }
        
        if [
            .notConnectedToInternet,
            .cannotFindHost,
            .cannotConnectToHost,
            .networkConnectionLost,
            .timedOut,
            .unsupportedURL
        ].contains(urlError.code) {
            Otpless.sharedInstance.eventDelegate?.onEvent(
                eventCallback: OtplessEventResponse(
                    responseString: error.localizedDescription,
                    responseData: nil,
                    eventCode: .networkFailure
                )
            )
            
            if isHeadless {
                if let request = headlessRequest,
                   !request.isEmpty()
                {
                    Otpless.sharedInstance.headlessDelegate?.onHeadlessResponse(
                        response: HeadlessResponse(
                            responseType: "INTERNET_ERR",
                            responseData: [
                                "statusCode": 5002,
                                "response": [
                                    "message": "Internet Error."
                                ]
                            ],
                            errorString: urlError.localizedDescription.description
                        )
                    )
                }
                Otpless.sharedInstance.dismissOtplessView(true)
            } else {
                loader.showWithErrorAndRetry(errorText: "Connection error" + " : " + error.localizedDescription.description)
            }
        }
    }
}

extension OtplessView: UIScrollViewDelegate {
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        scrollView.pinchGestureRecognizer?.isEnabled = false
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return nil
    }
}
