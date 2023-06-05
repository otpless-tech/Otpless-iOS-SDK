//
//  OtplessLoader.swift
//  OtplessSDK
//
//  Created by Otpless on 07/02/23.
//

import UIKit


class OtplessLoader: UIView {
        
    // private var label = UILabel()
 private var loader = UIActivityIndicatorView()

     override init(frame: CGRect) {
         super.init(frame: frame)
         loader.startAnimating()
         loader.color = .white
         setupView()
     }

     required init?(coder aDecoder: NSCoder) {
         super.init(coder: aDecoder)
         loader.startAnimating()
         setupView()
     }

     private func setupView() {
         backgroundColor = UIColor.black.withAlphaComponent(0.7)
         loader.frame = CGRect(x:  (UIScreen.main.bounds.width - 100)/2, y:  (UIScreen.main.bounds.height - 100)/2, width: 100, height: 100)
                        addSubview(loader)
         
//            label.text = "loading..."
//            label.textColor = UIColor.white
//            label.textAlignment = .center
     }

 @objc func closeButtonTapped(){
     self.removeFromSuperview()
 }
 
 public func show(){
     DispatchQueue.main.async { [self] in
         self.frame = CGRect(x: 0,y: 0,width: UIScreen.main.bounds.width,height: UIScreen.main.bounds.height)
         let window = UIApplication.shared.windows.last!
         window.addSubview(self)
     }
     
 }
 
 public func hide(){
     DispatchQueue.main.async { [self] in
         self.removeFromSuperview()
     }
 }
}

