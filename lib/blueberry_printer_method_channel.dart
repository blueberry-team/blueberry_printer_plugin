import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'blueberry_printer_platform_interface.dart';
import 'models/order_detail_response.dart';

/// An implementation of [BlueberryPrinterPlatform] that uses method channels.
class MethodChannelBlueberryPrinter extends BlueberryPrinterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('blueberry_printer');

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

  @override
  Future<bool> printOrderReceipt(
    OrderDetailResponse orderData, {
    required String storeName,
    String? storeAddress,
    String? phoneNumber,
    String? businessNumber,
    String? thankYouMessage,
  }) async {
    print('🔍 [DEBUG] MethodChannel: printOrderReceipt 호출 시작');
    print('🔍 [DEBUG] MethodChannel: 전달할 JSON 데이터: ${orderData.toJson()}');
    print('🔍 [DEBUG] MethodChannel: 매장명: $storeName');
    
    try {
      final bool result = await methodChannel.invokeMethod('printOrderReceipt', {
        'orderData': orderData.toJson(),
        'storeName': storeName,
        'storeAddress': storeAddress,
        'phoneNumber': phoneNumber,
        'businessNumber': businessNumber,
        'thankYouMessage': thankYouMessage,
      });
      print('🔍 [DEBUG] MethodChannel: 성공 결과: $result');
      return result;
    } catch (e) {
      print('🔍 [DEBUG] MethodChannel: 오류 발생: $e');
      rethrow;
    }
  }
}
