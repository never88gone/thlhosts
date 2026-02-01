workspace 'THLHOSTS'

def shared_pods
  use_frameworks!
  pod 'Masonry'
  pod 'Swifter', :git => 'https://github.com/yichengchen/swifter'
  pod 'SnapKit'
end

target 'THLHOSTSApp' do
  platform :tvos, '17.0'
  project 'THLHOSTSApp/THLHOSTSApp.xcodeproj'
  shared_pods
end

# Future Targets for iOS/macOS
target 'THLHOSTSApp_iOS' do
  platform :ios, '15.0'
  project 'THLHOSTSApp/THLHOSTSApp.xcodeproj'
  shared_pods
end

target 'THLHOSTSNetworkExtension' do
  platform :ios, '15.0' # Adjust platform as needed (e.g., universal if possible, or separate targets)
  project 'THLHOSTSApp/THLHOSTSApp.xcodeproj'
  # Network Extension typically needs fewer pods, but Swifter might be needed if shared logic uses it
  # shared_pods 
  pod 'Swifter', :git => 'https://github.com/yichengchen/swifter'
  use_frameworks!
end

# target 'THLHOSTSApp_macOS' do
#   platform :osx, '12.0'
#   project 'THLHOSTSApp/THLHOSTSApp.xcodeproj'
#   shared_pods
# end
