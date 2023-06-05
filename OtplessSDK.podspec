#
# Be sure to run `pod lib lint OtplessSDK.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'OtplessSDK'
  s.version          = '1.1.3'
  s.summary          = 'Sign-up/ Sign-in via by Otpless.'

  s.description      = <<-DESC
  'Sign-up/ Sign-in by Otpless. Get your user authentication sorted in just five minutes by integrating of Otpless SDK.'
  DESC


  s.homepage         = 'https://github.com/otpless-tech/Otpless-iOS-SDK'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Otpless' => 'developer@otpless.com' }
  s.source           = { :git => 'https://github.com/otpless-tech/Otpless-iOS-SDK.git', :tag => s.version.to_s }

  s.ios.deployment_target = '11.0'

  s.source_files = 'OtplessSDK/Classes/**/*'
  
  s.resource_bundles = {
      'OtplessSDK' => ['OtplessSDK/Assets/*.png']
  }
  s.resources = ["OtplessSDK/Assets/*.png"]
  
  s.swift_versions = ['4.0', '4.1', '4.2', '5.0', '5.1', '5.2', '5.3', '5.4', '5.5']

end
