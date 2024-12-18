//
//  OtplessLoader.swift
//  OtplessSDK
//
//  Created by Otpless on 07/02/23.
//

import UIKit

protocol OtplessLoaderDelegate: AnyObject {
    func loaderCloseButtonTapped()
    func loaderRetryButtonTapped()
}

class OtplessLoader: UIView {
    
    private var loader = UIActivityIndicatorView()
    weak var delegate: OtplessLoaderDelegate?
    private var closeButton = UIButton(type: .custom)
    private var centerTextLabel = UILabel()
    private var retryButton = UIButton(type: .system)
    private var centerLabelText = "Unable to Connect..."
    public var configParams : [String: Any]?
    public var loaderColor : UIColor = UIColor.gray
    public var textColor : UIColor = UIColor.black
    public var primaryColor : UIColor = UIColor(hexString:"#25d366") ?? UIColor.gray
    public var closeButtonColor : UIColor = UIColor.black
    public var loaderAlpha : CGFloat = 0.4
    public var loaderHidden : Bool = false
    public var networkFailureUiHidden : Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        getColorFromParams()
        loader.startAnimating()
        loader.color = loaderColor
        setupView()
        self.backgroundColor = .white
    }
    
    private func getColorFromParams(){
        if configParams != nil {
            if let color = UIColor(hexString: configParams?["primaryColor"] as? String ) {
                primaryColor = color
            }
            if let color = UIColor(hexString: configParams?["closeButtonColor"] as? String ) {
                closeButtonColor = color
            }
            if let color = UIColor(hexString: configParams?["loaderColor"] as? String ) {
                loaderColor = color
            }
            if let color = UIColor(hexString: configParams?["textColor"] as? String ) {
                textColor = color
            }
            if let alpha = configParams?["loaderAlpha"] as? String {
                if let floatValue = Float(alpha) {
                    loaderAlpha = CGFloat(floatValue)
                }
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loader.startAnimating()
        setupView()
    }
    
    private func setupView() {
        backgroundColor = UIColor.white.withAlphaComponent(loaderAlpha)
        loader.frame = CGRect(x:  (UIScreen.main.bounds.width - 100)/2, y:  (UIScreen.main.bounds.height - 100)/2, width: 100, height: 100)
        addSubview(loader)
        // Setup center text label
        centerTextLabel.text = centerLabelText
        centerTextLabel.numberOfLines = 0
        centerTextLabel.textColor = textColor
        centerTextLabel.textAlignment = .center
        addSubview(centerTextLabel)
        centerTextLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            centerTextLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            centerTextLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -150),
            centerTextLabel.heightAnchor.constraint(equalToConstant: 88),
            centerTextLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            centerTextLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20)
        ])
        // Setup retry button
        retryButton.setTitle("     Retry     ", for: .normal)
        retryButton.setTitleColor(textColor, for: .normal)
        retryButton.backgroundColor = primaryColor
        retryButton.addTarget(self, action: #selector(retryButtonClicked), for: .touchUpInside)
        addSubview(retryButton)
        retryButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            retryButton.topAnchor.constraint(equalTo: centerTextLabel.bottomAnchor, constant: 20),
            retryButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            retryButton.heightAnchor.constraint(equalToConstant: 44),
            retryButton.widthAnchor.constraint(equalToConstant: 88)
            // You might want to adjust constraints as per your design
        ])
        // Setup close button as text-based
        closeButton.setTitle("Close", for: .normal)
        closeButton.setTitleColor(closeButtonColor, for: .normal)
        closeButton.addTarget(self, action: #selector(closeButtonClicked), for: .touchUpInside)
        addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 30),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -30),
            closeButton.heightAnchor.constraint(equalToConstant: 88)
            
        ])
    }
    
    func updateAllColors(){
        getColorFromParams()
        backgroundColor = UIColor.white.withAlphaComponent(loaderAlpha)
        retryButton.setTitleColor(textColor, for: .normal)
        retryButton.backgroundColor = primaryColor
        
        centerTextLabel.textColor = textColor
        closeButton.setTitleColor(closeButtonColor, for: .normal)
        loader.color = loaderColor
    }
    
    @objc func closeButtonTapped(){
        self.removeFromSuperview()
    }
    
    func configure(withLoader: Bool, withCenterText: Bool, withRetryButton: Bool, withCloseButton: Bool) {
        loader.isHidden = !withLoader
        centerTextLabel.isHidden = !withCenterText
        retryButton.isHidden = !withRetryButton
        closeButton.isHidden = !withCloseButton
    }
    
    public func show(){
        if !loaderHidden {
            DispatchQueue.main.async { [self] in
                configure(withLoader: true, withCenterText: false, withRetryButton: false, withCloseButton: false)
                self.frame = CGRect(x: 0,y: 0,width: UIScreen.main.bounds.width,height: UIScreen.main.bounds.height)
                let window = UIApplication.shared.windows.last!
                window.addSubview(self)
            }
        }
    }
    
    public func showWithErrorAndRetry(errorText : String){
        if !networkFailureUiHidden {
            DispatchQueue.main.async { [self] in
                configure(withLoader: false, withCenterText: true, withRetryButton: true, withCloseButton: true)
                updateTextForError(errorText: errorText)
                self.frame = CGRect(x: 0,y: 0,width: UIScreen.main.bounds.width,height: UIScreen.main.bounds.height)
                let window = UIApplication.shared.windows.last!
                window.addSubview(self)
            }
        }
    }
    
    private func updateTextForError(errorText: String){
        centerTextLabel.text = errorText
        centerTextLabel.textAlignment = .center
        centerTextLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            centerTextLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            centerTextLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -200),
            centerTextLabel.heightAnchor.constraint(equalToConstant: 150),
            centerTextLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            centerTextLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20)
            
        ])
    }
    
    public func hide(){
        DispatchQueue.main.async { [self] in
            self.removeFromSuperview()
        }
    }
    
    @objc private func closeButtonClicked() {
        delegate?.loaderCloseButtonTapped()
    }
    
    @objc private func retryButtonClicked() {
        delegate?.loaderRetryButtonTapped()
    }
}

extension UIColor {
    convenience init?(hexString: String?) {
        guard let hexString = hexString else {
            return nil
        }
        
        var formattedString = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        formattedString = formattedString.replacingOccurrences(of: "#", with: "")
        
        guard formattedString.count == 6 else {
            return nil
        }
        
        var rgbValue: UInt64 = 0
        Scanner(string: formattedString).scanHexInt64(&rgbValue)
        
        let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgbValue & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
