project 'tapstream-sdk-ios'

def test_deps
  pod 'OCMock'
  pod 'Specta', '~> 1.0'
  pod 'OCHamcrest', '~> 5.0'
end

target 'TapstreamMac' do
    platform :osx, '10.8'
    target 'TapstreamMacTests' do
        test_deps
    end
end

target 'TapstreamIOS' do
    platform :ios, '7.0'
    target 'TapstreamIOSTests' do
        test_deps
    end
end


