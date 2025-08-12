// You have generated a new plugin project without specifying the `--platforms`
// flag. A plugin project with no platform support was generated. To add a
// platform, run `flutter create -t plugin --platforms <platforms> .` under the
// same directory. You can also find a detailed instruction on how to add
// platforms in the `pubspec.yaml` at
// https://flutter.dev/to/pubspec-plugin-platforms.

import 'blueberry_printer_platform_interface.dart';
import 'models/order_detail_response.dart';
import 'models/order_history_total_response.dart';

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

  Future<bool> printSampleReceipt() {
    return BlueberryPrinterPlatform.instance.printSampleReceipt();
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
}
