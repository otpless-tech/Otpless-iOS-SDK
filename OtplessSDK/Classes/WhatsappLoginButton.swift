//
//  WhatsappLoginButton.swift
//  OtplessSDK
//
//  Created by Otpless on 06/02/23.
//

import UIKit

public final class WhatsappLoginButton: UIButton,onVerifyWaidDelegate {
   
    var otplessUrl: String = ""
    var apiRoute = "metaverse"
    var buttonText = "Continue with WhatsApp"
    private var loader = OtplessLoader()
    
    public weak var delegate: onCallbackResponseDelegate?
   
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        setImageAndTitle()
      }
      
      required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        setImageAndTitle()
      }
    
      func setImageAndTitle() {
          if !Otpless.sharedInstance.isWhatsappInstalled() {
              self.isHidden = true
          }
          if let completeUrl = OtplessHelper.getCompleteUrl() {
              otplessUrl = OtplessHelper.addEventDetails(url: completeUrl)
              OtplessNetworkHelper.shared.setBaseUrl(url: otplessUrl)
          }
          Otpless.sharedInstance.delegateOnVerify = self
          if let image = UIImage(named: "otplesswhatsapp.png", in: Bundle(for: type(of: self)), compatibleWith: nil) {
            setImage(image, for: .normal)
          }
          checkWaidExistsAndVerified()
          setTitle(buttonText, for: .normal)
        addTarget(self, action:#selector(self.buttonClicked), for: .touchUpInside)
        backgroundColor = OtplessHelper.UIColorFromRGB(rgbValue: 0x23D366)
          setTitleColor(UIColor.white, for: UIControl.State.normal)
          titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
      }
    
    public func onVerifyWaid(mobile: String?, waId: String?, message: String?, error: String?) {
        DispatchQueue.main.async { [self] in
            buttonText = mobile ?? "Continue with WhatsApp"
            self.loader.hide()
            manageLabelAndImage()
            if((self.delegate) != nil){
                delegate?.onCallbackResponse(waId: waId, message: message, error: error)
            }
        }
    }

    
    @objc private func buttonClicked(){
        self.loader.show()
        let waIdExists = OtplessHelper.checkValueExists(forKey: OtplessHelper.waidDefaultKey);
        if (waIdExists){
            let waId = OtplessHelper.getValue(forKey:OtplessHelper.waidDefaultKey) as String?
            let headers = ["Content-Type": "application/json","Accept":"application/json"]
            let bodyParams = ["userId": waId, "api": "getUserDetail"]
            OtplessNetworkHelper.shared.fetchData(method: "POST", headers: headers, bodyParams:bodyParams as [String : Any]) { [self] (data, response, error) in
              guard let data = data else {
                // handle error
                  removeWaidAndContinueToWhatsapp()
                return
              }
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    // process the JSON data
                    let jsonDictionary = json as? [String: Any]
                    if let success = jsonDictionary?["success"] as? Bool {
                        if success{
                            if let jsonData = jsonDictionary?["data"] as? [String: Any]{
                                if let mobile = jsonData["userMobile"] as? String {
                                    DispatchQueue.main.async { [self] in
                                        buttonText = mobile
                                        manageLabelAndImage()
                                        if((self.delegate) != nil){
                                            delegate?.onCallbackResponse(waId: waId!, message: "success", error: nil)
                                            self.loader.hide()
                                        }
                                    }
                                } else {removeWaidAndContinueToWhatsapp()}
                            } else {removeWaidAndContinueToWhatsapp()}
                        } else {
                            removeWaidAndContinueToWhatsapp()
                        }
                    } else {
                        removeWaidAndContinueToWhatsapp()
                    }
                    
                  } catch {
                      removeWaidAndContinueToWhatsapp()
                  }
            }

            
        } else {
            self.loader.show()
            Otpless.sharedInstance.continueToWhatsapp(url: otplessUrl)
        }
    }
    
    public func removeWaidAndContinueToWhatsapp (){
        OtplessHelper.removeUserMobileAndWaid()
        Otpless.sharedInstance.continueToWhatsapp(url: otplessUrl)
    }
    
    public func show(){
        self.isHidden = false
    }
    
    public func hide(){
        self.isHidden = true
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        manageLabelAndImage()
    }
    
    func manageLabelAndImage(){
        
        let imgVwWidthAndHeight =  self.frame.height/2
        let expectedHeightForView = imgVwWidthAndHeight * 7
        
        let marginBetweenImgVwAndLabel = self.frame.height/8
        let marginLeftAndRight = self.frame.height/4
        var labelWidth = self.frame.width - imgVwWidthAndHeight - marginBetweenImgVwAndLabel - (marginLeftAndRight * 2)
        if labelWidth > expectedHeightForView {
            labelWidth = expectedHeightForView
        }
        let yForImgVw = (self.frame.height - imgVwWidthAndHeight)/2
    
        if let titleLabel = self.titleLabel ,let imageView = self.imageView  {
            if titleLabel.text != buttonText{
                setTitle(buttonText, for: .normal)
            }
            titleLabel.textAlignment = .center
            titleLabel.numberOfLines = 1
            titleLabel.sizeToFit()
            if titleLabel.frame.width > labelWidth {
                titleLabel.frame = CGRect(x: (self.frame.width - labelWidth + imgVwWidthAndHeight + marginBetweenImgVwAndLabel)/2 , y: yForImgVw, width: labelWidth , height: imgVwWidthAndHeight)
            }
            titleLabel.frame = CGRect(x: (self.frame.width - titleLabel.frame.width + imgVwWidthAndHeight + marginBetweenImgVwAndLabel)/2 , y: yForImgVw, width: titleLabel.frame.width , height: imgVwWidthAndHeight)
            
            imageView.frame = CGRect(x:(self.frame.width - titleLabel.frame.width - imgVwWidthAndHeight - marginBetweenImgVwAndLabel)/2, y: yForImgVw, width: imgVwWidthAndHeight, height:imgVwWidthAndHeight)
            
            titleLabel.adjustsFontSizeToFitWidth = true
            titleLabel.minimumScaleFactor=0.001
            }
        layer.cornerRadius = self.frame.height * 0.14
        layer.masksToBounds = true
    }
    
    func checkWaidExistsAndVerified (){

            let waIdExists = OtplessHelper.checkValueExists(forKey: OtplessHelper.waidDefaultKey);
            if (waIdExists){
                let waId = OtplessHelper.getValue(forKey:OtplessHelper.waidDefaultKey) as String?
                
                let headers = ["Content-Type": "application/json","Accept":"application/json"]
                let bodyParams = ["userId": waId, "api": "getUserDetail"]
                OtplessNetworkHelper.shared.fetchData(method: "POST", headers: headers, bodyParams:bodyParams as [String : Any]) { (data, response, error) in
                  guard let data = data else {
                    // handle error
                      if (error != nil) {
                          OtplessHelper.removeUserMobileAndWaid()
                      }
                    return
                  }
                    do {
                        let json = try JSONSerialization.jsonObject(with: data, options: [])
                        // process the JSON data
                        let jsonDictionary = json as? [String: Any]
                         if let jsonData = jsonDictionary?["data"] as? [String: Any]{
                             if let mobile = jsonData["userMobile"] as? String {
                                 DispatchQueue.main.async {
                                     self.buttonText = mobile
                                     self.manageLabelAndImage()
                                 }
                         }
                      }
                        
                      } catch {
                          OtplessHelper.removeUserMobileAndWaid()
                        // handle error
                      }
                }
            }
    }
    
}
// Implement this protocol to recieve waid in your view controller class when using WhatsappLoginButton
public protocol onCallbackResponseDelegate: AnyObject {
    func onCallbackResponse(waId : String?, message: String?, error : String?)
}
