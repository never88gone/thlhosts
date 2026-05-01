workspace 'THLHOSTS'

def shared_pods
  use_frameworks!
  pod 'Masonry'
  pod 'Swifter', :git => 'https://github.com/yichengchen/swifter'
  pod 'SnapKit'
end

project 'THLHOSTSApp/THLHOSTSApp.xcodeproj'

# 宿主 Target (支持多平台: tvOS, iOS, iPadOS)
target 'THLHOSTSApp' do
  platform :ios, '15.0'
  shared_pods
end

# 扩展 Target (iOS)
target 'THLHOSTSNetworkExtension' do
  platform :ios, '15.0'
  shared_pods
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      config.build_settings['TVOS_DEPLOYMENT_TARGET'] = '15.0'
      config.build_settings['SWIFT_VERSION'] = '5.0'
      # 显式支持多平台
      config.build_settings['SUPPORTED_PLATFORMS'] = 'iphonesimulator iphoneos appletvsimulator appletvos'
    end
  end
end
