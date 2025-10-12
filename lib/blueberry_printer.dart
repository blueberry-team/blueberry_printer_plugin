// You have generated a new plugin project without specifying the `--platforms`
// flag. A plugin project with no platform support was generated. To add a
// platform, run `flutter create -t plugin --platforms <platforms> .` under the
// same directory. You can also find a detailed instruction on how to add
// platforms in the `pubspec.yaml` at
// https://flutter.dev/to/pubspec-plugin-platforms.

import 'blueberry_printer_platform_interface.dart';
import 'models/order_detail_response.dart';
import 'models/order_history_total_response.dart';
import 'models/connection_status.dart';

class BlueberryPrinter {
  Future<String?> getPlatformVersion() {
    return BlueberryPrinterPlatform.instance.getPlatformVersion();
  }

  Future<List<Map<String, String>>> searchDevices() {
    return BlueberryPrinterPlatform.instance.searchDevices();
  }

  Future<bool> connectDevice(String address) {
    return BlueberryPrinterPlatform.instance.connectDevice(address);
  }

  Future<bool> printReceipt(String receiptText) {
    return BlueberryPrinterPlatform.instance.printReceipt(receiptText);
  }

  /// 간단한 텍스트 출력
  /// [text] 출력할 텍스트
  /// [fontSize] 폰트 크기 (기본값: 20.0)
  /// [isBold] 굵게 표시 여부 (기본값: false)
  /// [align] 텍스트 정렬 (LEFT, CENTER, RIGHT) (기본값: LEFT)
  Future<bool> printText(
    String text, {
    double fontSize = 20.0,
    bool isBold = false,
    String align = 'LEFT',
  }) {
    return BlueberryPrinterPlatform.instance.printText(
      text,
      fontSize: fontSize,
      isBold: isBold,
      align: align,
    );
  }

  Future<bool> disconnect() {
    return BlueberryPrinterPlatform.instance.disconnect();
  }

  /// 단일 주문 데이터로 영수증 출력 (점포용)
  /// [orderData] 주문 데이터
  /// [storeName] 매장명
  /// [tableNumber] 테이블 번호 (선택사항)
  /// [storeAddress] 매장 주소 (선택사항)
  /// [phoneNumber] 전화번호 (선택사항)
  /// [businessNumber] 사업자등록번호 (선택사항)
  /// [thankYouMessage] 감사 메시지 (선택사항)
  /// [showStoreLabel] 점포용 라벨 표시 여부 (기본값: true)
  Future<bool> printSingleOrder(
    OrderDetailResponse orderData, {
    required String storeName,
    String? tableNumber,
    String? storeAddress,
    String? phoneNumber,
    String? businessNumber,
    String? thankYouMessage,
    String language = 'kor', // kor, eng, jpn
    String currency = 'KRW', // KRW, USD, JPY, etc.
    bool showStoreLabel = true, // 점포용 라벨 표시 여부
  }) {
    return BlueberryPrinterPlatform.instance.printSingleOrder(
      orderData,
      storeName: storeName,
      tableNumber: tableNumber,
      storeAddress: storeAddress,
      phoneNumber: phoneNumber,
      businessNumber: businessNumber,
      thankYouMessage: thankYouMessage,
      language: language,
      currency: currency,
      showStoreLabel: showStoreLabel,
    );
  }

  /// 전체 주문 데이터로 영수증 출력 (모든 주문 버전 포함)
  /// [orderData] 주문 데이터 (모든 버전 포함)
  /// [storeName] 매장명
  /// [tableNumber] 테이블 번호 (선택사항)
  /// [storeAddress] 매장 주소 (선택사항)
  /// [phoneNumber] 전화번호 (선택사항)
  /// [businessNumber] 사업자등록번호 (선택사항)
  /// [thankYouMessage] 감사 메시지 (선택사항)
  Future<bool> printTotalOrder(
    OrderHistoryTotalResponse orderData, {
    required String storeName,
    String? tableNumber,
    String? storeAddress,
    String? phoneNumber,
    String? businessNumber,
    String? thankYouMessage,
    String language = 'kor', // kor, eng, jpn
    String currency = 'KRW', // KRW, USD, JPY, etc.
  }) {
    return BlueberryPrinterPlatform.instance.printTotalOrder(
      orderData,
      storeName: storeName,
      tableNumber: tableNumber,
      storeAddress: storeAddress,
      phoneNumber: phoneNumber,
      businessNumber: businessNumber,
      thankYouMessage: thankYouMessage,
      language: language,
      currency: currency,
    );
  }

  /// 실시간 프린터 연결 상태 스트림
  /// 연결 상태가 변경될 때마다 [ConnectionStatus] 객체가 전달됩니다.
  ///
  /// 사용 예시:
  /// ```dart
  /// final printer = BlueberryPrinter();
  /// printer.connectionStatusStream.listen((status) {
  ///   if (status.isConnected) {
  ///     print('프린터 연결됨: ${status.message}');
  ///   } else {
  ///     print('프린터 연결 끊김: ${status.message}, 이유: ${status.reason}');
  ///   }
  /// });
  /// ```
  Stream<ConnectionStatus> get connectionStatusStream {
    return BlueberryPrinterPlatform.instance.connectionStatusStream;
  }

  /// 소켓에서 받은 주문 알림 데이터로 영수증 출력
  /// [orderData] 주문 알림 데이터 (Map 형식)
  /// [language] 언어 설정 (kor, eng, jpn)
  /// [currency] 화폐 단위 (KRW, USD, JPY, etc.)
  ///
  /// 사용 예시:
  /// ```dart
  /// final printer = BlueberryPrinter();
  /// final orderData = OrderNotificationResponse.fromJson(socketData);
  /// await printer.printOrderFromSocket(
  ///   orderData.toJson(),
  ///   language: 'kor',
  ///   currency: 'KRW',
  /// );
  /// ```
  Future<bool> printOrderFromSocket(
    Map<String, dynamic> orderData, {
    String language = 'kor',
    String currency = 'KRW',
  }) {
    return BlueberryPrinterPlatform.instance.printOrderFromSocket(
      orderData,
      language: language,
      currency: currency,
    );
  }
}
