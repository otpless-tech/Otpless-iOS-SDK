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
        layer.borderColor = UIColor.lightGray.cgColor
        layer.shadowColor = UIColor.lightGray.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowOffset = CGSize(width: 2, height: 2)
        layer.shadowRadius = 4
        backgroundColor = .white
        layer.cornerRadius = 5
        
        
        addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }
    
    @objc private func buttonTapped() {
        // Custom action when the button is tapped
        Otpless.sharedInstance.signInButtonClicked()
    }
    
}

