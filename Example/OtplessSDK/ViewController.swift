//
//  ViewController.swift
//  OtplessSDK
//
//  Created by 121038664 on 02/05/2023.
//  Copyright (c) 2023 121038664. All rights reserved.
//

import UIKit
import OtplessSDK

class ViewController: UIViewController, onCallbackResponseDelegate{
    func onCallbackResponse(waId: String?, message: String?, error: String?) {
        print(waId,"__",message,"__",error)
    }
    
    
    @IBOutlet weak var whatsappButton: WhatsappLoginButton!
    
   // var codeWhatappButton = WhatsappLoginButton(type: .custom)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        whatsappButton.delegate = self
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}

