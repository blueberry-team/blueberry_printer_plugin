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
  Future<bool> printOrderReceipt(OrderDetailResponse orderData) {
    return BlueberryPrinterPlatform.instance.printOrderReceipt(orderData);
  }
}
