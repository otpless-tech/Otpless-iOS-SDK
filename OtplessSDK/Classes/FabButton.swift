//
//  FabButton.swift
//  OtplessSDK
//
//  Created by Anubhav Mathur on 05/06/23.
//


import UIKit

class FabButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupButton()
    }
    
    private func setupButton() {
        setTitle("Sign in", for: .normal)
        setTitleColor(.black, for: .normal)
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.black.cgColor
        backgroundColor = .white
        layer.cornerRadius = 5
        layer.masksToBounds = true
        
        addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }
    
    @objc private func buttonTapped() {
        // Custom action when the button is tapped
        Otpless.sharedInstance.start()
    }
    
}

