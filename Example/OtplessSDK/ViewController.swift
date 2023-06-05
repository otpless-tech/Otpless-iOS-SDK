//
//  ViewController.swift
//  OtplessSDK
//
//  Created by 121038664 on 02/05/2023.
//  Copyright (c) 2023 121038664. All rights reserved.
//

import UIKit
import OtplessSDK

class ViewController: UIViewController,onResponseDelegate{
    func onResponse(response: [String : Any]?) {
        responseTxtVw.text = response?.description
    }
  
    @IBOutlet weak var responseTxtVw: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        Otpless.sharedInstance.delegate = self
        Otpless.sharedInstance.shouldHideButton(hide: true)
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func buttonClicked(_ sender: UIButton) {
        Otpless.sharedInstance.start(vc: self)
    }
}

