Pod::Spec.new do |s|
  s.name           = 'TapstreamIOS'
  s.version        = '{{version}}'
  s.summary        = 'Tapstream marketing analytics SDK for iOS.'
  s.homepage       = 'https://tapstream.com/'
  s.license        = 'MIT'
  s.author         = { 'Tapstream' => 'support@tapstream.com' }
  s.source         = { :git => 'https://github.com/tapstream/tapstream-sdk-ios.git', :tag => 'v{{version}}-ios' }

  s.ios.deployment_target = '11.0'
  s.ios.frameworks = 'Foundation', 'UIKit', 'WebKit'

  s.subspec 'Core' do |core|
    core.source_files = ['tapstream-sdk-ios', 'tapstream-sdk-ios/ios-only']
  end

  s.subspec 'InAppLanders' do |ial|
    ial.source_files = ['tapstream-sdk-ios', 'tapstream-sdk-ios/ios-only', 'tapstream-sdk-ios/in-app-landers']
    ial.resources    = 'tapstream-sdk-ios/in-app-landers/*.xib'
  end

  s.subspec 'WordOfMouth' do |wom|
    wom.source_files = ['tapstream-sdk-ios', 'tapstream-sdk-ios/ios-only', 'tapstream-sdk-ios/word-of-mouth']
    wom.resources    = 'tapstream-sdk-ios/word-of-mouth/*.xib'
  end
end
