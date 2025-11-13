# Star Micronics 프린터 설정 가이드

이 플러그인에서 Star Micronics 프린터를 사용하려면 StarIO10 SDK를 설치해야 합니다.

## iOS 설정

### 1. StarIO10 SDK 다운로드

Star Micronics SDK는 두 가지 방법으로 설치할 수 있습니다:

#### 방법 A: 플러그인 개발 저장소에서 복사 (권장)

이미 `blueberry_printer_plugin` 저장소를 클론했다면:

```bash
# blueberry_printer_plugin 저장소에서 SDK 다운로드
cd /path/to/blueberry_printer_plugin/ios
./install_stario10.sh
```

SDK가 설치되면 프로젝트에서 자동으로 인식됩니다.

#### 방법 B: 직접 다운로드

1. [Star Micronics 공식 사이트](https://www.star-m.jp/products/s_print/sdk/starxpand/manual/en/ios-swift-sdk/index.html)에서 StarIO10 SDK 다운로드
2. 다운로드한 `StarIO10.xcframework`를 다음 위치에 복사:
   - 플러그인 개발: `blueberry_printer_plugin/ios/StarIO10.xcframework`
   - 앱 프로젝트: `.flutter-pub-cache/.../blueberry_printer-x.x.x/ios/StarIO10.xcframework`

### 2. Pod 설치

```bash
cd ios
pod install
```

### 3. Xcode 설정

Info.plist에 External Accessory 권한이 추가되어 있는지 확인:

```xml
<key>UISupportedExternalAccessoryProtocols</key>
<array>
    <string>jp.star-m.starpro</string>
</array>
```

## Android 설정

Android는 Gradle에서 자동으로 StarIO10 SDK를 다운로드합니다. 추가 설정이 필요하지 않습니다.

## 문제 해결

### iOS 빌드 오류: "Module 'StarIO10' not found"

1. StarIO10.xcframework가 올바른 위치에 있는지 확인
   ```bash
   ls -la /path/to/blueberry_printer_plugin/ios/StarIO10.xcframework
   ```

2. Pod 재설치
   ```bash
   cd ios
   rm -rf Pods Podfile.lock
   pod install
   ```

3. Xcode Clean Build
   ```bash
   cd ios
   xcodebuild clean
   ```

### 권한 문제

Star 프린터는 External Accessory 프레임워크를 사용하므로 Info.plist에 해당 프로토콜이 등록되어 있어야 합니다.

## 참고 자료

- [Star Micronics 공식 문서](https://www.star-m.jp/products/s_print/sdk/starxpand/manual/en/index.html)
- [StarXpand SDK GitHub](https://github.com/star-micronics/StarXpand-SDK-iOS)
