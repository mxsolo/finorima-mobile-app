project 'Project/Universal.xcodeproj'

# Uncomment the next line to define a global platform for your project
platform :ios, '11.0'

target 'Universal' do
  use_frameworks!
  #use_modular_headers!

  #Networking
  pod 'Alamofire', '~> 4.5'
  pod 'SDWebImage', '~> 4.0'
  pod 'OhhAuth', '~> 1.1.0'
  pod 'OneSignal', '>= 2.11.1', '< 3.0'

  #Parsers
  pod 'SwiftyJSON', '~> 4.0'
  pod 'ObjectMapper', '~> 4.2.0'
  pod 'FeedKit', '~> 8.0'
  pod 'Swifter', :git => 'https://github.com/mattdonnelly/Swifter.git' #Customised to remove deprecation warning

  #Google
  pod 'GoogleMaps', '~> 3.0.3'
  pod 'Google-Mobile-Ads-SDK', '~> 7.65.0'

  #Views
  pod "CollieGallery", :git => 'https://github.com/gmunhoz/CollieGallery.git' #Customised
  pod 'LPSnackbar'
  pod 'Cosmos', '~> 23.0'
  pod 'KILabel', '1.0.0'
  pod 'UITableView+FDTemplateLayoutCell'
  pod 'AMScrollingNavbar' #Customised

  #Media Playback
  pod "youtube-ios-player-helper", "~> 1.0.3"
  pod 'BMPlayer', '~> 1.3.2' #Customised to remove deprecation warning
  pod 'FRadioPlayer', '~> 0.1.20'

  #Utility
  pod 'KVOController'

end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
            config.build_settings['DEBUG_INFORMATION_FORMAT'] = 'dwarf'
        end
    end
end
