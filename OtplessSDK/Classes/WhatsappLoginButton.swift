//
//  WhatsappLoginButton.swift
//  OtplessSDK
//
//  Created by Otpless on 06/02/23.
//

import UIKit

@IBDesignable public class WhatsappLoginButton: UIButton,onVerifyWaidDelegate {
   
    @IBInspectable var buttonfontSize: CGFloat = 15.0
    let spacing: CGFloat = 8.0
    var otplessUrl: String = ""
    var apiRoute = "metaverse"
    var progressing = false;
    var checked = false;
    private var loader = OtplessLoader()
    
    public weak var delegate: onCallbackResponseDelegate?
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    public func setButtonFontSize(size: CGFloat)
    {
        buttonfontSize = size
        titleLabel?.font = UIFont(name:"HelveticaNeue-Bold", size:buttonfontSize)
    
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        setImageAndTitle(imageName: "otplesswhatsapp.png", title: "Continue with WhatsApp")
      }
      
      required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        setImageAndTitle(imageName: "otplesswhatsapp.png", title: "Continue with WhatsApp")
      }
    
      func setImageAndTitle(imageName: String, title: String) {
          
          if let completeUrl = OtplessHelper.getCompleteUrl() {
              otplessUrl = OtplessHelper.addEventDetails(url: completeUrl)
              OtplessNetworkHelper.shared.setBaseUrl(url: otplessUrl)
          } 
          Otpless.sharedInstance.delegateOnVerify = self
          if let image = UIImage(named: imageName, in: Bundle(for: type(of: self)), compatibleWith: nil) {
            setImage(image, for: .normal)
          }
          setTitle(title, for: .normal)
        addTarget(self, action:#selector(self.buttonClicked), for: .touchUpInside)
        backgroundColor = OtplessHelper.UIColorFromRGB(rgbValue: 0x23D366)
        setTitleColor(UIColor.white, for: UIControlState.normal)
        layer.cornerRadius = 20
        layer.masksToBounds = true
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
            OtplessNetworkHelper.shared.fetchData(from: "metaverse", method: "POST", headers: headers, bodyParams:bodyParams) { [self] (data, response, error) in
              guard let data = data else {
                // handle error
                  if (error != nil) {
                      OtplessHelper.removeUserMobileAndWaid()
                  }
                  Otpless.sharedInstance.continueToWhatsapp(url: otplessUrl)
                return
              }
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    // process the JSON data
                    let jsonDictionary = json as? [String: Any]
                     if let jsonData = jsonDictionary?["data"] as? [String: Any]{
                         if let mobile = jsonData["userMobile"] as? String {
                             DispatchQueue.main.async { [self] in
                                 self.setTitle(mobile, for: .normal)
                                 if((self.delegate) != nil){
                                     delegate?.onCallbackResponse(waId: waId!, message: "success", error: nil)
                                     self.loader.hide()
                                 }
                             }
                     }
                  }
                    
                  } catch {
                      OtplessHelper.removeUserMobileAndWaid()
                      Otpless.sharedInstance.continueToWhatsapp(url: otplessUrl)
                    // handle error
                  }
            }

            
        } else {
            self.loader.show()
            Otpless.sharedInstance.continueToWhatsapp(url: otplessUrl)
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        checkWaidExistsAndVerified()
       if let imageView = self.imageView {
            imageView.frame = CGRect(x: self.frame.height/4, y: (self.frame.height - (self.frame.height/2))/2, width: self.frame.height/2, height: self.frame.height/2)
            //imageView.contentMode = UIViewContentMode.scaleAspectFill
            }
        if let titleLabel = self.titleLabel {
            titleLabel.frame = CGRect(x: 0 , y: 0, width: self.frame.width , height: self.frame.height)
            titleLabel.textAlignment  = .center
            titleLabel.font = UIFont(name:"HelveticaNeue-Bold", size:buttonfontSize)
            }
    }
    
    func checkWaidExistsAndVerified (){
        if (!progressing){
            progressing = true
            
            let waIdExists = OtplessHelper.checkValueExists(forKey: OtplessHelper.waidDefaultKey);
            if (waIdExists){
                let waId = OtplessHelper.getValue(forKey:OtplessHelper.waidDefaultKey) as String?
                
                let headers = ["Content-Type": "application/json","Accept":"application/json"]
                let bodyParams = ["userId": waId, "api": "getUserDetail"]
                OtplessNetworkHelper.shared.fetchData(from: "metaverse", method: "POST", headers: headers, bodyParams:bodyParams) { (data, response, error) in
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
