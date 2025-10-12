import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'blueberry_printer_platform_interface.dart';
import 'models/order_detail_response.dart';
import 'models/order_history_total_response.dart';
import 'models/connection_status.dart';

/// An implementation of [BlueberryPrinterPlatform] that uses method channels.
class MethodChannelBlueberryPrinter extends BlueberryPrinterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('blueberry_printer');

  /// The event channel used for connection status stream
  @visibleForTesting
  final eventChannel = const EventChannel('blueberry_printer/connection_status');

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
  Future<bool> printText(
    String text, {
    double fontSize = 20.0,
    bool isBold = false,
    String align = 'LEFT',
  }) async {
    final bool result = await methodChannel.invokeMethod('printText', {
      'text': text,
      'fontSize': fontSize,
      'isBold': isBold,
      'align': align,
    });
    return result;
  }

  @override
  Future<bool> disconnect() async {
    final bool result = await methodChannel.invokeMethod('disconnect');
    return result;
  }

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
  }) async {
    print(' [DEBUG] MethodChannel: printSingleOrder 호출 시작');
    print(' [DEBUG] MethodChannel: 전달할 JSON 데이터: ${orderData.toJson()}');
    print(' [DEBUG] MethodChannel: 매장명: $storeName');
    print(' [DEBUG] MethodChannel: 점포용 라벨 표시: $showStoreLabel');

    // 파라미터의 쉬표를 일본 쉬표로 변경하여 파싱 오류 방지
    String sanitizedStoreName = storeName.replaceAll(',', '、');
    String? sanitizedStoreAddress = storeAddress?.replaceAll(',', '、');
    String? sanitizedPhoneNumber = phoneNumber?.replaceAll(',', '、');
    String? sanitizedBusinessNumber = businessNumber?.replaceAll(',', '、');
    String? sanitizedThankYouMessage = thankYouMessage?.replaceAll(',', '、');

    print(' [DEBUG] MethodChannel: 쉬표 제거 후 - 매장명: $sanitizedStoreName');
    print(' [DEBUG] MethodChannel: 쉬표 제거 후 - 주소: $sanitizedStoreAddress');

    try {
      final bool result = await methodChannel.invokeMethod('printSingleOrder', {
        'orderData': orderData.toJson(),
        'storeName': sanitizedStoreName,
        'tableNumber': tableNumber,
        'storeAddress': sanitizedStoreAddress,
        'phoneNumber': sanitizedPhoneNumber,
        'businessNumber': sanitizedBusinessNumber,
        'thankYouMessage': sanitizedThankYouMessage,
        'language': language,
        'currency': currency,
        'showStoreLabel': showStoreLabel,
      });
      print(' [DEBUG] MethodChannel: 성공 결과: $result');
      return result;
    } catch (e) {
      print(' [DEBUG] MethodChannel: 오류 발생: $e');
      rethrow;
    }
  }

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
  }) async {
    print(' [DEBUG] MethodChannel: printTotalOrder 호출 시작');
    print(' [DEBUG] MethodChannel: 전달할 JSON 데이터: ${orderData.toJson()}');
    print(' [DEBUG] MethodChannel: 매장명: $storeName');
    print(' [DEBUG] MethodChannel: 주문 ID: ${orderData.orderId}');
  
    // 파라미터의 쉬표를 일본 쉬표로 변경하여 파싱 오류 방지
    String sanitizedStoreName = storeName.replaceAll(',', '、');
    String? sanitizedStoreAddress = storeAddress?.replaceAll(',', '、');
    String? sanitizedPhoneNumber = phoneNumber?.replaceAll(',', '、');
    String? sanitizedBusinessNumber = businessNumber?.replaceAll(',', '、');
    String? sanitizedThankYouMessage = thankYouMessage?.replaceAll(',', '、');
  
    print(' [DEBUG] MethodChannel: 쉬표 제거 후 - 매장명: $sanitizedStoreName');
    print(' [DEBUG] MethodChannel: 쉬표 제거 후 - 주소: $sanitizedStoreAddress');
  
    try {
      final bool result = await methodChannel.invokeMethod('printTotalOrder', {
        'orderData': orderData.toJson(),
        'storeName': sanitizedStoreName,
        'tableNumber': tableNumber,
        'storeAddress': sanitizedStoreAddress,
        'phoneNumber': sanitizedPhoneNumber,
        'businessNumber': sanitizedBusinessNumber,
        'thankYouMessage': sanitizedThankYouMessage,
        'language': language,
        'currency': currency,
      });
      print(' [DEBUG] MethodChannel: 성공 결과: $result');
      return result;
    } catch (e) {
      print(' [DEBUG] MethodChannel: 오류 발생: $e');
      rethrow;
    }
  }

  @override
  Stream<ConnectionStatus> get connectionStatusStream {
    return eventChannel.receiveBroadcastStream().map((event) {
      return ConnectionStatus.fromMap(event as Map<dynamic, dynamic>);
    });
  }

  @override
  Future<bool> printOrderFromSocket(
    Map<String, dynamic> orderData, {
    String language = 'kor',
    String currency = 'KRW',
  }) async {
    print(' [DEBUG] MethodChannel: printOrderFromSocket 호출 시작');
    print(' [DEBUG] MethodChannel: 전달할 데이터: $orderData');
    print(' [DEBUG] MethodChannel: 언어: $language, 화폐: $currency');

    try {
      final bool result = await methodChannel.invokeMethod('printOrderFromSocket', {
        'orderData': orderData,
        'language': language,
        'currency': currency,
      });
      print(' [DEBUG] MethodChannel: 성공 결과: $result');
      return result;
    } catch (e) {
      print(' [DEBUG] MethodChannel: 오류 발생: $e');
      rethrow;
    }
  }
}
