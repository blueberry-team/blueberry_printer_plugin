#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint blueberry_printer.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'blueberry_printer'
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
  s.public_header_files = 'Classes/BlueberryPrinterPlugin.h'
  s.dependency 'Flutter'
  s.platform = :ios, '14.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'CLANG_ENABLE_MODULES' => 'YES'
  }
  s.swift_version = '5.0'

  # 필요한 프레임워크 추가
  s.frameworks = 'CoreBluetooth', 'CoreGraphics', 'UIKit', 'ExternalAccessory'
  
  # PrinterSDK 정적 라이브러리 추가
  s.vendored_libraries = 'Classes/PrinterSDK/libPrinterSDK.a'

  # StarIO10 SDK - Swift Package Manager를 통해 설치
  # Xcode에서 File > Add Packages 하여 추가 필요
  # URL: https://github.com/star-micronics/StarXpand-SDK-iOS
  # 또는 프로젝트 루트에서 실행:
  #   xcodebuild -resolvePackageDependencies

  # 참고: StarIO10은 Swift Package로 제공되므로
  # 사용자가 Xcode 프로젝트에서 직접 추가해야 합니다.

  # 개인정보 보호 매니페스트 (iOS 17+)
  # s.resource_bundles = {
  #   'blueberry_printer_privacy' => ['Resources/PrivacyInfo.xcprivacy']
  # }
end
