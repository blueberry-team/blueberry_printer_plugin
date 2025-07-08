#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint bluberry_printer.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'bluberry_printer'
  s.version          = '0.0.1'
  s.summary          = 'A Flutter plugin for Bluetooth printer connection and receipt printing with Korean support.'
  s.description      = <<-DESC
A Flutter plugin that enables Bluetooth printer connection and receipt printing with full Korean language support.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
  
  # 필요한 프레임워크 추가
  s.frameworks = 'CoreBluetooth', 'CoreGraphics', 'UIKit'
  
  # 개인정보 보호 매니페스트 (iOS 17+)
  # s.resource_bundles = {
  #   'bluberry_printer_privacy' => ['Resources/PrivacyInfo.xcprivacy']
  # }
end
