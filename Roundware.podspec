#
# Be sure to run `pod lib lint Roundware.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Roundware'
  s.version          = '0.3.2'
  s.summary          = 'Audio framework'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
    Audio framework that allows users to hear audio recorded nearby.
                       DESC

  s.homepage         = 'https://github.com/loafofpiecrust/roundware-ios-framework-v2'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'loafofpiecrust' => 'taylorsnead@gmail.com' }
  s.source           = { :git => 'https://github.com/loafofpiecrust/roundware-ios-framework-v2.git' }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.source_files  = "RWFramework", "RWFramework/RWFramework/**/*.{swift,h,m}"
  # s.exclude_files = "Classes/Exclude"


  s.ios.deployment_target = '10.0'
  s.swift_version = "5.0"

  s.frameworks = 'AVFoundation', 'SceneKit', 'SpriteKit'

  s.dependency "PromisesSwift", "~> 1.2.3"
  s.dependency "GEOSwift", "~> 5.0.0"
  s.dependency "GEOSwiftMapKit", "~> 1.0.0"
  s.dependency "Repeat", "~> 0.5.6"
end
