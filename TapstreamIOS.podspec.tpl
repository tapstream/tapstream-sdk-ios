Pod::Spec.new do |s|
  s.name           = 'TapstreamIOS'
  s.version        = '{{version}}'
  s.summary        = 'Tapstream marketing analytics.'
  s.homepage       = 'https://tapstream.com/'
  s.license        = 'MIT'
  s.author         = { 'Michael Zsigmond' => 'support@tapstream.com' }
  s.source         = { :git => 'https://github.com/tapstream/tapstream-sdk-ios.git', :tag => 'v{{version}}-ios' }
  s.ios.deployment_target = '7.0'
  s.source_files   = [
    'tapstream-sdk-ios',
    'tapstream-sdk-ios/word-of-mouth',
    'tapstream-sdk-ios/ios-only',
    'tapstream-sdk-ios/in-app-landers',
    'tapstream-sdk-ios/universal-links']
  s.resources      = 'tapstream-sdk-ios/in-app-landers/*.xib', 'tapstream-sdk-ios/word-of-mouth/*.xib'
  s.ios.frameworks = 'Foundation', 'UIKit'
end


