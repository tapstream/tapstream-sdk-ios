Pod::Spec.new do |s|
  s.name         = 'TapstreamMac'
  s.version      = '3.0.0'
  s.summary      = 'Tapstream marketing analytics.'
  s.homepage     = 'https://tapstream.com/'
  s.license      = 'MIT'
  s.author       = { 'Michael Zsigmond' => 'support@tapstream.com' }
  s.source       = { :git => 'https://github.com/tapstream/tapstream-sdk-ios.git', :tag => 'v3.0.0' }
  s.osx.deployment_target = '10.6'
  s.source_files = 'tapstream-sdk-ios'
  s.osx.frameworks = 'Foundation', 'AppKit'
end


