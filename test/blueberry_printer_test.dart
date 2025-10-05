import 'package:flutter_test/flutter_test.dart';
import 'package:blueberry_printer/blueberry_printer.dart';
import 'package:blueberry_printer/blueberry_printer_platform_interface.dart';
import 'package:blueberry_printer/blueberry_printer_method_channel.dart';
import 'package:blueberry_printer/models/order_detail_response.dart';
import 'package:blueberry_printer/models/order_history_total_response.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockBlueberryPrinterPlatform
    with MockPlatformInterfaceMixin
    implements BlueberryPrinterPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<List<Map<String, String>>> searchDevices() async {
    return [
      {'name': 'Test Printer', 'address': '00:11:22:33:44:55'}
    ];
  }

  @override
  Future<bool> connectDevice(String address) async => true;

  @override
  Future<bool> printReceipt(String receiptText) async => true;

  @override
  Future<bool> printSampleReceipt() async => true;

  @override
  Future<bool> disconnect() async => true;

  @override
  Future<bool> printSingleOrder(
    OrderDetailResponse orderData, {
    required String storeName,
    String? tableNumber,
    String? storeAddress,
    String? phoneNumber,
    String? businessNumber,
    String? thankYouMessage,
    String language = 'kor',
    String currency = 'KRW',
    bool showStoreLabel = true,
  }) async =>
      true;

  @override
  Future<bool> printTotalOrder(
    OrderHistoryTotalResponse orderData, {
    required String storeName,
    String? tableNumber,
    String? storeAddress,
    String? phoneNumber,
    String? businessNumber,
    String? thankYouMessage,
    String language = 'kor',
    String currency = 'KRW',
  }) async =>
      true;
}

void main() {
  final BlueberryPrinterPlatform initialPlatform = BlueberryPrinterPlatform.instance;

  test('$MethodChannelBlueberryPrinter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelBlueberryPrinter>());
  });

  test('getPlatformVersion', () async {
    BlueberryPrinter blueberryPrinterPlugin = BlueberryPrinter();
    MockBlueberryPrinterPlatform fakePlatform = MockBlueberryPrinterPlatform();
    BlueberryPrinterPlatform.instance = fakePlatform;

    expect(await blueberryPrinterPlugin.getPlatformVersion(), '42');
  });

  test('searchDevices returns device list', () async {
    BlueberryPrinter blueberryPrinterPlugin = BlueberryPrinter();
    MockBlueberryPrinterPlatform fakePlatform = MockBlueberryPrinterPlatform();
    BlueberryPrinterPlatform.instance = fakePlatform;

    final devices = await blueberryPrinterPlugin.searchDevices();
    expect(devices, isNotEmpty);
    expect(devices.first['name'], 'Test Printer');
  });

  test('connectDevice returns true on success', () async {
    BlueberryPrinter blueberryPrinterPlugin = BlueberryPrinter();
    MockBlueberryPrinterPlatform fakePlatform = MockBlueberryPrinterPlatform();
    BlueberryPrinterPlatform.instance = fakePlatform;

    final result = await blueberryPrinterPlugin.connectDevice('00:11:22:33:44:55');
    expect(result, true);
  });

  test('printReceipt returns true on success', () async {
    BlueberryPrinter blueberryPrinterPlugin = BlueberryPrinter();
    MockBlueberryPrinterPlatform fakePlatform = MockBlueberryPrinterPlatform();
    BlueberryPrinterPlatform.instance = fakePlatform;

    final result = await blueberryPrinterPlugin.printReceipt('[TITLE]Test[/TITLE]');
    expect(result, true);
  });

  test('disconnect returns true on success', () async {
    BlueberryPrinter blueberryPrinterPlugin = BlueberryPrinter();
    MockBlueberryPrinterPlatform fakePlatform = MockBlueberryPrinterPlatform();
    BlueberryPrinterPlatform.instance = fakePlatform;

    final result = await blueberryPrinterPlugin.disconnect();
    expect(result, true);
  });
}
