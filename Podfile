project 'tapstream-sdk-ios'

def test_deps
  pod 'OCMock', '~> 3.0'
  pod 'Specta', '~> 2.0'
  pod 'OCHamcrest', '~> 9.0'
end

target 'TapstreamIOS' do
    platform :ios, '15.0'
    target 'TapstreamIOSTests' do
        test_deps
    end
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
        end
    end
end
