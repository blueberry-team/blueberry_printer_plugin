import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'bluberry_printer_platform_interface.dart';

/// An implementation of [BluberryPrinterPlatform] that uses method channels.
class MethodChannelBluberryPrinter extends BluberryPrinterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('bluberry_printer');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<List<Map<String, String>>> searchDevices() async {
    final List<dynamic> result = await methodChannel.invokeMethod('searchDevices');
    return result.map((device) {
      final Map<dynamic, dynamic> deviceMap = device as Map<dynamic, dynamic>;
      return {
        'name': deviceMap['name']?.toString() ?? '알 수 없는 기기',
        'address': deviceMap['address']?.toString() ?? '',
      };
    }).toList();
  }

  @override
  Future<bool> connectDevice(String address) async {
    final bool result = await methodChannel.invokeMethod('connectDevice', {'address': address});
    return result;
  }

  @override
  Future<bool> printReceipt(String receiptText) async {
    final bool result = await methodChannel.invokeMethod('printReceipt', {'receiptText': receiptText});
    return result;
  }

  @override
  Future<bool> printSampleReceipt() async {
    final bool result = await methodChannel.invokeMethod('printSampleReceipt');
    return result;
  }

  @override
  Future<bool> disconnect() async {
    final bool result = await methodChannel.invokeMethod('disconnect');
    return result;
  }
}
