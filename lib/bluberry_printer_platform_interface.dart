import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'bluberry_printer_method_channel.dart';

abstract class BluberryPrinterPlatform extends PlatformInterface {
  /// Constructs a BluberryPrinterPlatform.
  BluberryPrinterPlatform() : super(token: _token);

  static final Object _token = Object();

  static BluberryPrinterPlatform _instance = MethodChannelBluberryPrinter();

  /// The default instance of [BluberryPrinterPlatform] to use.
  ///
  /// Defaults to [MethodChannelBluberryPrinter].
  static BluberryPrinterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [BluberryPrinterPlatform] when
  /// they register themselves.
  static set instance(BluberryPrinterPlatform instance) {
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
}
