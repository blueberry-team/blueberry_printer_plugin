import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'blueberry_printer_method_channel.dart';
import 'models/order_detail_response.dart';
import 'models/order_history_total_response.dart';

abstract class BlueberryPrinterPlatform extends PlatformInterface {
  /// Constructs a BlueberryPrinterPlatform.
  BlueberryPrinterPlatform() : super(token: _token);

  static final Object _token = Object();

  static BlueberryPrinterPlatform _instance = MethodChannelBlueberryPrinter();

  /// The default instance of [BlueberryPrinterPlatform] to use.
  ///
  /// Defaults to [MethodChannelBlueberryPrinter].
  static BlueberryPrinterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [BlueberryPrinterPlatform] when
  /// they register themselves.
  static set instance(BlueberryPrinterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<List<Map<String, String>>> searchDevices() {
    throw UnimplementedError('searchDevices() has not been implemented.');
  }

  Future<bool> connectDevice(String address) {
    throw UnimplementedError('connectDevice() has not been implemented.');
  }

  Future<bool> printReceipt(String receiptText) {
    throw UnimplementedError('printReceipt() has not been implemented.');
  }

  Future<bool> printSampleReceipt() {
    throw UnimplementedError('printSampleReceipt() has not been implemented.');
  }

  Future<bool> disconnect() {
    throw UnimplementedError('disconnect() has not been implemented.');
  }

  /// 단일 주문 데이터로 영수증 출력 (점포용)
  /// [orderData] 주문 데이터
  /// [storeName] 매장명
  /// [tableNumber] 테이블 번호 (선택사항)
  /// [storeAddress] 매장 주소 (선택사항)
  /// [phoneNumber] 전화번호 (선택사항)
  /// [businessNumber] 사업자등록번호 (선택사항)
  /// [thankYouMessage] 감사 메시지 (선택사항)
  /// [showStoreLabel] 점포용 라벨 표시 여부
  Future<bool> printSingleOrder(
    OrderDetailResponse orderData, {
    required String storeName,
    String? tableNumber,
    String? storeAddress,
    String? phoneNumber,
    String? businessNumber,
    String? thankYouMessage,
    String language = 'kor', // kor, eng, jpn
    String currency = 'KRW',
    bool showStoreLabel = true,
  }) {
    throw UnimplementedError('printSingleOrder() has not been implemented.');
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
    String currency = 'KRW',
  }) {
    throw UnimplementedError('printTotalOrder() has not been implemented.');
  }
}
