//
//  ViewController.swift
//  OtplessSDK
//
//  Created by 121038664 on 02/05/2023.
//  Copyright (c) 2023 121038664. All rights reserved.
//

import UIKit
import OtplessSDK

class ViewController: UIViewController, onResponseDelegate{
    func onResponse(response: OtplessSDK.OtplessResponse?) {
        if (response?.errorString != nil) {
            print(response?.errorString ?? "no value in erro")
               } else {
                   if (response != nil && response?.responseData != nil
       && response?.responseData?["data"] != nil){
                       if let data = response?.responseData?["data"] as? [String: Any] {
                           let token = data["token"]
                           print(token ?? "no token")
                       }
                   }
                   
               }
        
    }
    
   
    
   // var codeWhatappButton = WhatsappLoginButton(type: .custom)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        Otpless.sharedInstance.delegate = self
        Otpless.sharedInstance.start(vc: self)
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}

