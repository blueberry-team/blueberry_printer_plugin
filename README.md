# 🖨️ Bluberry Printer

[![pub package](https://img.shields.io/pub/v/bluberry_printer.svg)](https://pub.dev/packages/bluberry_printer)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Android-green.svg)](https://android.com)

**한국어 영수증 출력을 지원하는 블루투스 프린터 Flutter 플러그인**

Bluberry Printer는 ESC/POS 명령을 사용하여 블루투스 프린터에서 한국어 영수증을 출력할 수 있는 Flutter 플러그인입니다. 텍스트를 이미지로 변환하여 한글 폰트 문제를 해결하고, 깔끔한 영수증 레이아웃을 제공합니다.

## ✨ 주요 기능

- 🔍 **블루투스 기기 검색**: 주변 블루투스 프린터 자동 검색
- 🔗 **간편한 연결**: 원클릭으로 프린터 연결 및 해제
- 🧾 **한국어 영수증 출력**: 완벽한 한글 지원으로 깔끔한 영수증 출력
- 🎨 **커스텀 레이아웃**: 매장 정보, 상품 목록, 합계 등 자유로운 구성
- 📱 **사용자 친화적 UI**: 직관적인 인터페이스로 쉬운 사용
- ⚡ **빠른 출력**: 최적화된 이미지 변환으로 빠른 출력 속도

## 🚀 시작하기

### 설치

`pubspec.yaml` 파일에 다음을 추가하세요:

```yaml
dependencies:
  bluberry_printer: ^1.0.0
```

그리고 패키지를 설치하세요:

```bash
flutter pub get
```

### Android 권한 설정

`android/app/src/main/AndroidManifest.xml` 파일에 블루투스 권한을 추가하세요:

```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />

<!-- Android 12 이상을 위한 권한 -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
```

## 📖 사용법

### 기본 사용법

```dart
import 'package:bluberry_printer/bluberry_printer.dart';

class PrinterExample extends StatefulWidget {
  @override
  _PrinterExampleState createState() => _PrinterExampleState();
}

class _PrinterExampleState extends State<PrinterExample> {
  final _printer = BluberryPrinter();
  List<Map<String, String>> _devices = [];
  bool _isConnected = false;

  // 블루투스 기기 검색
  Future<void> _searchDevices() async {
    final devices = await _printer.searchDevices();
    setState(() {
      _devices = devices;
    });
  }

  // 프린터 연결
  Future<void> _connectDevice(String address) async {
    final success = await _printer.connectDevice(address);
    setState(() {
      _isConnected = success;
    });
  }

  // 샘플 영수증 출력
  Future<void> _printSample() async {
    await _printer.printSampleReceipt();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('블루베리 프린터')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _searchDevices,
            child: Text('기기 검색'),
          ),
          if (_isConnected)
            ElevatedButton(
              onPressed: _printSample,
              child: Text('샘플 출력'),
            ),
        ],
      ),
    );
  }
}
```

### 커스텀 영수증 출력

```dart
Future<void> _printCustomReceipt() async {
  const receiptText = '''
[TITLE]카페 블루베리[/TITLE]

[STORE_INFO]
서울특별시 강남구 테헤란로 123
전화: 02-1234-5678
사업자등록번호: 123-45-67890
[/STORE_INFO]

[SEPARATOR]

[ITEM_LIST]
아메리카노 (ICE)        4,500원 x 2
카페라떼 (HOT)          5,000원 x 1
블루베리 머핀           3,500원 x 1
[/ITEM_LIST]

[TOTAL]
소계: 17,500원
부가세: 1,750원
합계: 19,250원
[/TOTAL]

[THANK_YOU]
감사합니다!
다음에 또 방문해 주세요.
[/THANK_YOU]
  ''';

  await _printer.printReceipt(receiptText);
}
```

## 🏷️ 영수증 태그 가이드

| 태그 | 설명 | 예시 |
|------|------|------|
| `[TITLE]...[/TITLE]` | 영수증 제목 | `[TITLE]카페 블루베리[/TITLE]` |
| `[STORE_INFO]...[/STORE_INFO]` | 매장 정보 | 주소, 전화번호, 사업자번호 |
| `[SEPARATOR]` | 구분선 | `[SEPARATOR]` |
| `[ITEM_LIST]...[/ITEM_LIST]` | 상품 목록 | 상품명, 가격, 수량 |
| `[TOTAL]...[/TOTAL]` | 합계 정보 | 소계, 부가세, 총합계 |
| `[THANK_YOU]...[/THANK_YOU]` | 감사 메시지 | 인사말, 재방문 유도 |

## 🎯 API 참조

### 주요 메서드

#### `searchDevices()`
주변 블루투스 기기를 검색합니다.

```dart
Future<List<Map<String, String>>> searchDevices()
```

**반환값**: 기기 이름과 주소를 포함한 맵 리스트

#### `connectDevice(String address)`
지정된 주소의 블루투스 기기에 연결합니다.

```dart
Future<bool> connectDevice(String address)
```

**매개변수**:
- `address`: 연결할 기기의 블루투스 주소

**반환값**: 연결 성공 여부

#### `printReceipt(String receiptText)`
커스텀 영수증을 출력합니다.

```dart
Future<bool> printReceipt(String receiptText)
```

**매개변수**:
- `receiptText`: 출력할 영수증 텍스트 (태그 포함)

**반환값**: 출력 성공 여부

#### `printSampleReceipt()`
미리 정의된 샘플 영수증을 출력합니다.

```dart
Future<bool> printSampleReceipt()
```

**반환값**: 출력 성공 여부

#### `disconnect()`
현재 연결된 프린터와의 연결을 해제합니다.

```dart
Future<bool> disconnect()
```

**반환값**: 연결 해제 성공 여부

## 🛠️ 기술적 특징

### 한글 지원 방식
- **텍스트-이미지 변환**: 한글 텍스트를 비트맵 이미지로 변환하여 출력
- **ESC/POS 명령**: 표준 ESC/POS 명령을 사용하여 프린터 제어
- **최적화된 이미지 처리**: 메모리 효율적인 이미지 변환 및 전송

### 지원 프린터
- ESC/POS 명령을 지원하는 모든 블루투스 프린터
- 58mm, 80mm 용지 폭 지원
- 대부분의 POS 프린터와 호환

## 🔧 문제 해결

### 일반적인 문제

**Q: 기기 검색이 안 돼요**
A: 블루투스 권한을 확인하고, 기기의 블루투스가 켜져 있는지 확인하세요.

**Q: 연결은 되는데 출력이 안 돼요**
A: 프린터가 ESC/POS 명령을 지원하는지 확인하고, 용지가 충분한지 확인하세요.

**Q: 한글이 깨져서 나와요**
A: 이 플러그인은 텍스트를 이미지로 변환하므로 한글이 깨지지 않습니다. 프린터 연결 상태를 확인해보세요.

## 📱 예제 앱

이 저장소의 `example` 폴더에서 완전한 예제 앱을 확인할 수 있습니다:

```bash
cd example
flutter run
```

## 🤝 기여하기

버그 리포트, 기능 요청, 풀 리퀘스트를 환영합니다!

1. 이 저장소를 포크하세요
2. 새로운 브랜치를 생성하세요 (`git checkout -b feature/amazing-feature`)
3. 변경사항을 커밋하세요 (`git commit -m 'Add amazing feature'`)
4. 브랜치에 푸시하세요 (`git push origin feature/amazing-feature`)
5. 풀 리퀘스트를 열어주세요

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참고하세요.

## 🙏 감사의 말

이 플러그인은 다음 기술들을 기반으로 만들어졌습니다:
- Flutter 플랫폼 채널
- Android 블루투스 API
- ESC/POS 프린터 명령 표준

---

💙 **Bluberry Printer**로 더 나은 영수증 출력 경험을 만들어보세요!
