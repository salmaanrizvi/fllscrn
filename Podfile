# Uncomment this line to define a global platform for your project
# platform :ios, '9.0'

target 'FLLSCRN' do
  # Comment this line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for FLLSCRN
  pod 'FontAwesome.swift', :git => 'https://github.com/thii/FontAwesome.swift.git', :branch => 'master'
  
  pod ‘KCFloatingActionButton’, :git => 'https://github.com/kciter/KCFloatingActionButton.git', :branch => 'swift3.0’
  
  pod 'IQKeyboardManagerSwift', :git => 'https://github.com/hackiftekhar/IQKeyboardManager.git', :branch => 'swift3'
  
  pod 'SCLAlertView', :git => 'https://github.com/vikmeup/SCLAlertView-Swift'
  
  post_install do |installer|
      installer.pods_project.targets.each do |target|
          target.build_configurations.each do |config|
              config.build_settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'NO'
          end
      end
  end

end
