Pod::Spec.new do |s|
  s.name         = 'TapstreamMac'
  s.version      = '{{version}}'
  s.summary      = 'BETA Tapstream marketing analytics SDK for macOS.'
  s.homepage     = 'https://tapstream.com/'
  s.license      = 'MIT'
  s.author       = { 'Michael Zsigmond' => 'support@tapstream.com' }
  s.source       = { :git => 'https://github.com/tapstream/tapstream-sdk-ios.git', :tag => 'v{{version}}-macos' }
  s.osx.deployment_target = '10.6'
  s.source_files = 'tapstream-sdk-ios'
  s.osx.frameworks = 'Foundation', 'AppKit'
  s.subspec 'Core' do |core|
    core.source_files = ['tapstream-sdk-ios']
  end
end


