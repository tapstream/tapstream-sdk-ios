Pod::Spec.new do |s|
  s.name           = 'TapstreamIOS'
  s.version        = '3.0.0'
  s.summary        = 'Tapstream marketing analytics.'
  s.homepage       = 'https://tapstream.com/'
  s.license        = 'MIT'
  s.author         = { 'Michael Zsigmond' => 'support@tapstream.com' }
  s.source         = { :git => 'https://github.com/tapstream/tapstream-sdk-ios.git', :tag => 'v3.0.0' }
  s.ios.deployment_target = '7.0'
  s.source_files   = [
    'sdk/tapstream-sdk-ios',
    'sdk/tapstream-sdk-ios/word-of-mouth',
    'sdk/tapstream-sdk-ios/ios-only',
    'sdk/tapstream-sdk-ios/in-app-landers',
    'sdk/tapstream-sdk-ios/universal-links']
  s.resources      = 'sdk/tapstream-sdk-ios/in-app-landers/*.xib', 'sdk/tapstream-sdk-ios/word-of-mouth/*.xib'
  s.ios.frameworks = 'Foundation', 'UIKit'
end

