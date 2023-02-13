//
//  WhatsappLoginButton.swift
//  OtplessSDK
//
//  Created by Otpless on 06/02/23.
//

import UIKit

@IBDesignable public class WhatsappLoginButton: UIButton,onVerifyWaidDelegate {
   
    @IBInspectable var buttonfontSize: CGFloat = 20.0
    let spacing: CGFloat = 8.0
    var otplessUrl: String = ""
    var apiRoute = "metaverse"
    var progressing = false;
    var checked = false;
    private var loader = OtplessLoader()
    
    public weak var delegate: onCallbackResponseDelegate?
   
    
    public func setButtonFontSize(size: CGFloat)
    {
        buttonfontSize = size
        titleLabel?.font = UIFont(name:"HelveticaNeue-Bold", size:buttonfontSize)
    
    }
    
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
              return
          }
          if let completeUrl = OtplessHelper.getCompleteUrl() {
              otplessUrl = OtplessHelper.addEventDetails(url: completeUrl)
              OtplessNetworkHelper.shared.setBaseUrl(url: otplessUrl)
          }
          Otpless.sharedInstance.delegateOnVerify = self
          if let image = UIImage(named: "otplesswhatsapp.png", in: Bundle(for: type(of: self)), compatibleWith: nil) {
            setImage(image, for: .normal)
          }
          setTitle("Continue with WhatsApp", for: .normal)
        addTarget(self, action:#selector(self.buttonClicked), for: .touchUpInside)
        backgroundColor = OtplessHelper.UIColorFromRGB(rgbValue: 0x23D366)
          setTitleColor(UIColor.white, for: UIControl.State.normal)
      }
    
    public func onVerifyWaid(mobile: String?, waId: String?, message: String?, error: String?) {
        DispatchQueue.main.async { [self] in
            self.loader.hide()
            self.setTitle(mobile, for: .normal)
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
            OtplessNetworkHelper.shared.fetchData(from: "metaverse", method: "POST", headers: headers, bodyParams:bodyParams as [String : Any]) { [self] (data, response, error) in
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
                                        self.setTitle(mobile, for: .normal)
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
        checkWaidExistsAndVerified()
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
        let xForImgVw = (self.frame.width - (imgVwWidthAndHeight + marginBetweenImgVwAndLabel + labelWidth))/2
        let yForImgVw = (self.frame.height - imgVwWidthAndHeight)/2
        let xForLabel = xForImgVw + imgVwWidthAndHeight + marginBetweenImgVwAndLabel
       if let imageView = self.imageView {
            imageView.frame = CGRect(x:xForImgVw, y: yForImgVw, width: imgVwWidthAndHeight, height:imgVwWidthAndHeight)
            }
        if let titleLabel = self.titleLabel {
            titleLabel.frame = CGRect(x: xForLabel , y: yForImgVw, width: labelWidth , height: imgVwWidthAndHeight)
            titleLabel.textAlignment = .left
            titleLabel.numberOfLines = 1
            titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
            
            titleLabel.adjustsFontSizeToFitWidth = true
            titleLabel.minimumScaleFactor=0.001
            //titleLabel.translatesAutoresizingMaskIntoConstraints = false
            }
        layer.cornerRadius = self.frame.height * 0.14
        layer.masksToBounds = true
    }
    
    func checkWaidExistsAndVerified (){
        if (!progressing){
            progressing = true
            
            let waIdExists = OtplessHelper.checkValueExists(forKey: OtplessHelper.waidDefaultKey);
            if (waIdExists){
                let waId = OtplessHelper.getValue(forKey:OtplessHelper.waidDefaultKey) as String?
                
                let headers = ["Content-Type": "application/json","Accept":"application/json"]
                let bodyParams = ["userId": waId, "api": "getUserDetail"]
                OtplessNetworkHelper.shared.fetchData(from: "metaverse", method: "POST", headers: headers, bodyParams:bodyParams as [String : Any]) { (data, response, error) in
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
                                     self.setTitle(mobile, for: .normal)
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
    
}
// Implement this protocol to recieve waid in your view controller class when using WhatsappLoginButton
public protocol onCallbackResponseDelegate: AnyObject {
    func onCallbackResponse(waId : String?, message: String?, error : String?)
}
