
Pod::Spec.new do |s|
  s.name             = 'OtplessSDK'
  s.version          = '2.2.3'
  s.summary          = 'Sign-up/ Sign-in engineered by OTPLESS.'

  s.description      = <<-DESC
  'Sign-up/ Sign-in engineered by OTPLESS. Get your user authentication sorted in just five minutes by integrating of Otpless sdk.'
  DESC


  s.homepage         = 'https://github.com/otpless-tech/Otpless-iOS-SDK'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Otpless' => 'developer@otpless.com' }
  s.source           = { :git => 'https://github.com/otpless-tech/Otpless-iOS-SDK.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/otpless'
  s.ios.deployment_target = '13.0'
  
  s.dependency 'GoogleSignIn', '~> 8.1.0-vwg-eap-1.0.0'
  s.dependency 'GoogleSignInSwiftSupport', '~> 8.0.0'
  s.dependency 'FBSDKLoginKit', '~> 17.0.2'
  s.dependency 'FBSDKCoreKit', '~> 17.0.2'

  s.source_files = 'OtplessSDK/Classes/**/*'
  s.resource_bundles = {
      'OtplessSDK' => ['OtplessSDK/PrivacyInfo.xcprivacy']
  }
  
  s.swift_versions = ['4.0', '4.1', '4.2', '5.0', '5.1', '5.2', '5.3', '5.4', '5.5']

end
