// You have generated a new plugin project without specifying the `--platforms`
// flag. A plugin project with no platform support was generated. To add a
// platform, run `flutter create -t plugin --platforms <platforms> .` under the
// same directory. You can also find a detailed instruction on how to add
// platforms in the `pubspec.yaml` at
// https://flutter.dev/to/pubspec-plugin-platforms.

import 'bluberry_printer_platform_interface.dart';

class BluberryPrinter {
  Future<String?> getPlatformVersion() {
    return BluberryPrinterPlatform.instance.getPlatformVersion();
  }

  Future<List<Map<String, String>>> searchDevices() {
    return BluberryPrinterPlatform.instance.searchDevices();
  }

  Future<bool> connectDevice(String address) {
    return BluberryPrinterPlatform.instance.connectDevice(address);
  }

  Future<bool> printReceipt(String receiptText) {
    return BluberryPrinterPlatform.instance.printReceipt(receiptText);
  }

  Future<bool> printSampleReceipt() {
    return BluberryPrinterPlatform.instance.printSampleReceipt();
  }

  Future<bool> disconnect() {
    return BluberryPrinterPlatform.instance.disconnect();
  }
}
