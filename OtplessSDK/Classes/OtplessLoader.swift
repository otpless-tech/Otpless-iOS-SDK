//
//  OtplessLoader.swift
//  OtplessSDK
//
//  Created by Otpless on 07/02/23.
//

import UIKit

class OtplessLoader: UIView {
    private var activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        private var closeButton = UIButton(type: .system)

        override init(frame: CGRect) {
            super.init(frame: frame)
            setupView()
        }

        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            setupView()
        }

        private func setupView() {
            backgroundColor = UIColor.black.withAlphaComponent(0.7)
            activityIndicator.startAnimating()
            addSubview(activityIndicator)
            activityIndicator.translatesAutoresizingMaskIntoConstraints = false
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
            
            addSubview(closeButton)
            closeButton.setTitleColor(OtplessHelper.UIColorFromRGB(rgbValue: 0x23D366), for: .normal)
            closeButton.translatesAutoresizingMaskIntoConstraints = false
            closeButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20).isActive = true
            closeButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
            closeButton.setTitle("Cancel", for: .normal)
            closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        }

    @objc func closeButtonTapped(){
        self.removeFromSuperview()
    }
    
    public func show(){
        DispatchQueue.main.async { [self] in
            self.frame = CGRect(x: 0,y: 0,width: UIScreen.main.bounds.width,height: UIScreen.main.bounds.height)
            var window = UIApplication.shared.windows.last!
            window.addSubview(self)
        }
        
    }
    
    public func hide(){
        DispatchQueue.main.async { [self] in
            self.removeFromSuperview()
        }
    }
}
