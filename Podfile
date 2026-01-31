workspace 'THLHOSTS'

def common_pods
  use_frameworks!
  pod 'Masonry'
  pod 'Swifter', :git => 'https://github.com/yichengchen/swifter'
  pod 'SnapKit'
end

target 'THLHOSTS' do
  platform :tvos, '17.0'
  project 'THLHOSTS/THLHOSTS.xcodeproj'
  common_pods
end

target 'THLHOSTSApp' do
  platform :tvos, '17.0'
  project 'THLHOSTSApp/THLHOSTSApp.xcodeproj'
  common_pods
end
