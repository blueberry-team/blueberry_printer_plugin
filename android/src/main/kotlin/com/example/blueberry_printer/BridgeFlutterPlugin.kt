package com.example.blueberry_printer

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import android.bluetooth.BluetoothSocket
import java.io.OutputStream
import android.util.Log
import com.example.blueberry_printer.sample_receipt.SimpleTextPrinter
import com.example.blueberry_printer.printer_connection.RealtimeConnectionChecker
import com.example.blueberry_printer.single_order.SingleOrderDirectPrinter
import com.example.blueberry_printer.multiple_order.MultipleOrderDirectPrinter
import com.example.blueberry_printer.order_notification.OrderNotificationPrinter
import com.example.blueberry_printer.bluetooth_search.BluetoothDeviceSearcher
import com.example.blueberry_printer.common.DisconnectReason
import io.flutter.plugin.common.EventChannel
import android.os.Handler
import android.os.Looper

/** BridgeFlutterPlugin */
class BridgeFlutterPlugin: FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var eventChannel : EventChannel
  private var eventSink: EventChannel.EventSink? = null

  // 현재 연결된 블루투스 소켓과 출력 스트림
  private var currentSocket: BluetoothSocket? = null
  private var outputStream: OutputStream? = null

  // 연결 상태 모니터링
  private var connectionChecker: RealtimeConnectionChecker? = null

  // UI 스레드 핸들러
  private val mainHandler = Handler(Looper.getMainLooper())

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "blueberry_printer")
    channel.setMethodCallHandler(this)

    // EventChannel 설정 (연결 상태 스트림)
    eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "blueberry_printer/connection_status")
    eventChannel.setStreamHandler(this)
  }

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    eventSink = events
  }

  override fun onCancel(arguments: Any?) {
    eventSink = null
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "getPlatformVersion" -> {
        result.success("Android ${android.os.Build.VERSION.RELEASE}")
      }
      "searchDevices" -> {
        try {
          val deviceList = BluetoothDeviceSearcher.searchPairedDevices()
          result.success(deviceList)
        } catch (e: BluetoothDeviceSearcher.BluetoothNotSupportedException) {
          result.error("NO_ADAPTER", e.message, null)
        } catch (e: BluetoothDeviceSearcher.BluetoothNotEnabledException) {
          result.error("NOT_ENABLED", e.message, null)
        } catch (e: BluetoothDeviceSearcher.BluetoothSearchException) {
          result.error("SEARCH_FAIL", e.message, null)
        } catch (e: Exception) {
          result.error("SEARCH_FAIL", "검색 실패: ${e.message}", null)
        }
      }
      "connectDevice" -> {
        val address = call.argument<String>("address")
        if (address == null) {
          result.error("NO_ADDRESS", "기기 주소가 필요합니다", null)
          return
        }

        try {
          // BluetoothDeviceSearcher를 사용하여 기기 찾기
          val device = BluetoothDeviceSearcher.findDeviceByAddress(address)
          val bluetoothAdapter = BluetoothDeviceSearcher.getBluetoothAdapter()

          // 소켓 연결
          val uuid = device.uuids?.firstOrNull()?.uuid
            ?: java.util.UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
          val socket = device.createRfcommSocketToServiceRecord(uuid)
          bluetoothAdapter.cancelDiscovery()
          socket.connect()

          // 연결 성공 시 소켓과 출력 스트림 저장
          currentSocket = socket
          outputStream = socket.outputStream

          // 연결 상태 모니터링 시작
          startConnectionMonitoring(socket)

          result.success(true)
        } catch (e: BluetoothDeviceSearcher.BluetoothNotSupportedException) {
          result.error("NO_ADAPTER", e.message, null)
        } catch (e: BluetoothDeviceSearcher.BluetoothNotEnabledException) {
          result.error("NOT_ENABLED", e.message, null)
        } catch (e: BluetoothDeviceSearcher.DeviceNotFoundException) {
          result.error("NOT_FOUND", e.message, null)
        } catch (e: Exception) {
          result.error("CONNECT_FAIL", "연결 실패: ${e.message}", null)
        }
      }
      "printReceipt" -> {
        val receiptText = call.argument<String>("receiptText")
        if (receiptText == null) {
          result.error("NO_TEXT", "출력할 텍스트가 필요합니다", null)
          return
        }
        
        val stream = outputStream
        if (stream == null) {
          result.error("NOT_CONNECTED", "프린터가 연결되지 않았습니다", null)
          return
        }
        
        try {
          Log.d("BridgeFlutterPlugin", "커스텀 영수증 출력 시작: $receiptText")
          SimpleTextPrinter.print(stream, receiptText)
          result.success(true)
        } catch (e: Exception) {
          Log.e("BridgeFlutterPlugin", "커스텀 영수증 출력 실패", e)
          result.error("PRINT_FAIL", "출력 실패: ${e.message}", e.stackTrace.toString())
        }
      }
      "printText" -> {
        val text = call.argument<String>("text")
        val fontSize = call.argument<Double>("fontSize")?.toFloat() ?: 20f
        val isBold = call.argument<Boolean>("isBold") ?: false
        val alignString = call.argument<String>("align") ?: "LEFT"

        if (text == null) {
          result.error("NO_TEXT", "출력할 텍스트가 필요합니다", null)
          return
        }

        val stream = outputStream
        if (stream == null) {
          result.error("NOT_CONNECTED", "프린터가 연결되지 않았습니다", null)
          return
        }

        try {
          Log.d("BridgeFlutterPlugin", "텍스트 출력 시작: $text")

          // 정렬 방식 변환
          val align = when (alignString.uppercase()) {
            "CENTER" -> com.example.blueberry_printer.common.KoreanTextRenderer.TextAlign.CENTER
            "RIGHT" -> com.example.blueberry_printer.common.KoreanTextRenderer.TextAlign.RIGHT
            else -> com.example.blueberry_printer.common.KoreanTextRenderer.TextAlign.LEFT
          }

          SimpleTextPrinter.print(stream, text, fontSize, isBold, align)
          result.success(true)
        } catch (e: Exception) {
          Log.e("BridgeFlutterPlugin", "텍스트 출력 실패", e)
          result.error("PRINT_FAIL", "텍스트 출력 실패: ${e.message}", e.stackTrace.toString())
        }
      }
      "printSingleOrder" -> {
        val orderData = call.argument<Map<String, Any>>("orderData")
        val storeName = call.argument<String>("storeName")
        val tableNumber = call.argument<String>("tableNumber")
        val storeAddress = call.argument<String>("storeAddress")
        val phoneNumber = call.argument<String>("phoneNumber")
        val businessNumber = call.argument<String>("businessNumber")
        val thankYouMessage = call.argument<String>("thankYouMessage")
        val language = call.argument<String>("language") ?: "kor"
        val currency = call.argument<String>("currency") ?: "KRW"
        val showStoreLabel = call.argument<Boolean>("showStoreLabel") ?: true
        
        if (orderData == null || storeName == null) {
          result.error("NO_DATA", "주문 데이터와 매장명이 필요합니다", null)
          return
        }
        
        Log.d("BridgeFlutterPlugin", "전달받은 주문 데이터: $orderData")
        Log.d("BridgeFlutterPlugin", "매장 정보 - 이름: $storeName, 주소: $storeAddress, 전화: $phoneNumber")
        Log.d("BridgeFlutterPlugin", "Android printSingleOrder 호출 - 매장명: $storeName, 언어: $language, 화폐: $currency, 점포용 라벨: $showStoreLabel")
        
        val stream = outputStream
        if (stream == null) {
          result.error("NOT_CONNECTED", "프린터가 연결되지 않았습니다", null)
          return
        }
        
        try {
          Log.d("BridgeFlutterPlugin", "단일 주문 영수증 출력 시작 (Direct Printer)")
          // 새로운 직접 출력 방식 사용
          SingleOrderDirectPrinter.print(
            stream, orderData, storeName, tableNumber, storeAddress, phoneNumber, businessNumber, thankYouMessage, language, currency, showStoreLabel
          )
          result.success(true)
        } catch (e: Exception) {
          Log.e("BridgeFlutterPlugin", "단일 주문 영수증 출력 실패", e)
          result.error("PRINT_FAIL", "출력 실패: ${e.message}", e.stackTrace.toString())
        }
      }
      "printTotalOrder" -> {
        val orderData = call.argument<Map<String, Any>>("orderData")
        val storeName = call.argument<String>("storeName")
        val tableNumber = call.argument<String>("tableNumber")
        val storeAddress = call.argument<String>("storeAddress")
        val phoneNumber = call.argument<String>("phoneNumber")
        val businessNumber = call.argument<String>("businessNumber")
        val thankYouMessage = call.argument<String>("thankYouMessage")
        val language = call.argument<String>("language") ?: "kor"
        val currency = call.argument<String>("currency") ?: "KRW"
        
        if (orderData == null || storeName == null) {
          result.error("NO_DATA", "주문 데이터와 매장명이 필요합니다", null)
          return
        }
        
        Log.d("BridgeFlutterPlugin", "전달받은 전체 주문 데이터: $orderData")
        Log.d("BridgeFlutterPlugin", "매장 정보 - 이름: $storeName, 주소: $storeAddress, 전화: $phoneNumber")
        Log.d("BridgeFlutterPlugin", "Android printTotalOrder 호출 - 매장명: $storeName, 언어: $language, 화폐: $currency")
        
        val stream = outputStream
        if (stream == null) {
          result.error("NOT_CONNECTED", "프린터가 연결되지 않았습니다", null)
          return
        }
        
        try {
          Log.d("BridgeFlutterPlugin", "전체 주문 영수증 출력 시작 (Direct Printer)")
          // 새로운 직접 출력 방식 사용
          MultipleOrderDirectPrinter.print(
            stream, orderData, storeName, tableNumber, storeAddress, phoneNumber, businessNumber, thankYouMessage, language, currency
          )
          result.success(true)
        } catch (e: Exception) {
          Log.e("BridgeFlutterPlugin", "전체 주문 영수증 출력 실패", e)
          result.error("PRINT_FAIL", "출력 실패: ${e.message}", e.stackTrace.toString())
        }
      }
      "printOrderFromSocket" -> {
        val orderData = call.argument<Map<String, Any>>("orderData")
        val language = call.argument<String>("language") ?: "kor"
        val currency = call.argument<String>("currency") ?: "KRW"

        if (orderData == null) {
          result.error("NO_DATA", "주문 알림 데이터가 필요합니다", null)
          return
        }

        Log.d("BridgeFlutterPlugin", "전달받은 주문 알림 데이터: $orderData")
        Log.d("BridgeFlutterPlugin", "언어: $language, 화폐: $currency")

        val stream = outputStream
        if (stream == null) {
          result.error("NOT_CONNECTED", "프린터가 연결되지 않았습니다", null)
          return
        }

        try {
          Log.d("BridgeFlutterPlugin", "주문 알림 영수증 출력 시작")
          OrderNotificationPrinter.print(stream, orderData, language, currency)
          result.success(true)
        } catch (e: Exception) {
          Log.e("BridgeFlutterPlugin", "주문 알림 영수증 출력 실패", e)
          result.error("PRINT_FAIL", "출력 실패: ${e.message}", e.stackTrace.toString())
        }
      }
      "disconnect" -> {
        try {
          stopConnectionMonitoring()
          currentSocket?.close()
          currentSocket = null
          outputStream = null
          result.success(true)
        } catch (e: Exception) {
          result.error("DISCONNECT_FAIL", "연결 해제 실패: ${e.message}", null)
        }
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)

    // 플러그인 해제 시 연결 정리
    stopConnectionMonitoring()
    try {
      currentSocket?.close()
    } catch (e: Exception) {
      // 무시
    }
    currentSocket = null
    outputStream = null
    eventSink = null
  }

  /**
   * 연결 상태 모니터링 시작
   */
  private fun startConnectionMonitoring(socket: BluetoothSocket) {
    // 기존 모니터링 중지
    stopConnectionMonitoring()

    try {
      connectionChecker = RealtimeConnectionChecker(
        socket = socket,
        heartbeatIntervalMs = 5000, // 5초마다 Heartbeat
        socketTimeoutMs = 3000, // 3초 타임아웃
        onConnectionLost = { reason ->
          Log.w("BridgeFlutterPlugin", "Printer connection lost: ${reason.code}")
          // UI 스레드에서 Flutter로 연결 끊김 알림
          mainHandler.post {
            eventSink?.success(mapOf(
              "status" to "disconnected",
              "message" to "", // 빈 문자열 - 앱에서 다국어 처리
              "reason" to reason.code
            ))
          }
        },
        onConnectionRestored = {
          Log.i("BridgeFlutterPlugin", "Printer connection restored")
          // UI 스레드에서 Flutter로 연결 복구 알림
          mainHandler.post {
            eventSink?.success(mapOf(
              "status" to "connected",
              "message" to "" // 빈 문자열 - 앱에서 다국어 처리
            ))
          }
        }
      )
      connectionChecker?.start()

      Log.i("BridgeFlutterPlugin", "연결 상태 모니터링이 시작되었습니다")

      // UI 스레드에서 초기 연결 성공 알림
      mainHandler.post {
        eventSink?.success(mapOf(
          "status" to "connected",
          "message" to "" // 빈 문자열 - 앱에서 다국어 처리
        ))
      }
    } catch (e: Exception) {
      Log.e("BridgeFlutterPlugin", "연결 모니터링 시작 실패: ${e.message}", e)
    }
  }

  /**
   * 연결 상태 모니터링 중지
   */
  private fun stopConnectionMonitoring() {
    connectionChecker?.stop()
    connectionChecker = null
    Log.i("BridgeFlutterPlugin", "연결 상태 모니터링이 중지되었습니다")
  }
} 