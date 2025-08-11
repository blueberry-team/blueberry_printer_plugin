// You have generated a new plugin project without specifying the `--platforms`
// flag. A plugin project with no platform support was generated. To add a
// platform, run `flutter create -t plugin --platforms <platforms> .` under the
// same directory. You can also find a detailed instruction on how to add
// platforms in the `pubspec.yaml` at
// https://flutter.dev/to/pubspec-plugin-platforms.

import 'blueberry_printer_platform_interface.dart';
import 'models/order_detail_response.dart';

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

  /// 구조화된 주문 데이터로 영수증 출력
  /// [orderData] 주문 데이터
  /// [storeName] 매장명
  /// [storeAddress] 매장 주소 (선택사항)
  /// [phoneNumber] 전화번호 (선택사항)
  /// [businessNumber] 사업자등록번호 (선택사항)
  /// [thankYouMessage] 감사 메시지 (선택사항)
  Future<bool> printOrderReceipt(
    OrderDetailResponse orderData, {
    required String storeName,
    String? storeAddress,
    String? phoneNumber,
    String? businessNumber,
    String? thankYouMessage,
    String language = 'kor', // kor, eng, jpn
    String currency = 'KRW', // KRW, USD, JPY, etc.
  }) {
    return BlueberryPrinterPlatform.instance.printOrderReceipt(
      orderData,
      storeName: storeName,
      storeAddress: storeAddress,
      phoneNumber: phoneNumber,
      businessNumber: businessNumber,
      thankYouMessage: thankYouMessage,
      language: language,
      currency: currency,
    );
  }

  /// 누적 주문 데이터로 영수증 출력 (모든 주문 버전 포함)
  /// [orderData] 주문 데이터 (모든 버전 포함)
  /// [storeName] 매장명
  /// [storeAddress] 매장 주소 (선택사항)
  /// [phoneNumber] 전화번호 (선택사항)
  /// [businessNumber] 사업자등록번호 (선택사항)
  /// [thankYouMessage] 감사 메시지 (선택사항)
  Future<bool> printCumulativeOrderReceipt(
    OrderDetailResponse orderData, {
    required String storeName,
    String? storeAddress,
    String? phoneNumber,
    String? businessNumber,
    String? thankYouMessage,
    String language = 'kor', // kor, eng, jpn
    String currency = 'KRW', // KRW, USD, JPY, etc.
  }) {
    return BlueberryPrinterPlatform.instance.printCumulativeOrderReceipt(
      orderData,
      storeName: storeName,
      storeAddress: storeAddress,
      phoneNumber: phoneNumber,
      businessNumber: businessNumber,
      thankYouMessage: thankYouMessage,
      language: language,
      currency: currency,
    );
  }
}
