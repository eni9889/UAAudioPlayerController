#
# Be sure to run `pod lib lint UAAudioPlayerController.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "UAAudioPlayerController"
  s.version          = "0.1.0"
  s.summary          = "A short description of UAAudioPlayerController."
  s.description      = <<-DESC
                       An optional longer description of UAAudioPlayerController

                       * Markdown format.
                       * Don't worry about the indent, we strip it!
                       DESC
  s.homepage         = "https://github.com/eni9889/UAAudioPlayerController"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Enea Gjoka" => "enea@instamotor.com" }
  s.source           = { :git => "https://github.com/<GITHUB_USERNAME>/UAAudioPlayerController.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/unlimapps'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes'
  s.resources = 'Pod/Assets/Images/*.png', 'Pod/Assets/Nibs/*.xib'

  s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'UIKit', 'AudioToolbox', 'MediaPlayer', 'QuartzCore', 'AVFoundation'
  s.dependency 'MarqueeLabel', '~> 2.0.1'
  s.dependency 'AFNetworking', '~> 2.0'
  s.dependency 'NAKPlaybackIndicatorView', '~> 0.0.3'
end
