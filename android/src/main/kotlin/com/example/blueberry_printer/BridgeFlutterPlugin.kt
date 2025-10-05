package com.example.blueberry_printer

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import android.bluetooth.BluetoothSocket
import java.io.OutputStream
import android.util.Log
import com.example.blueberry_printer.data.DataSampleReceipts
import com.example.blueberry_printer.logic.LogicReceiptProcessor
import com.example.blueberry_printer.hardware.RealtimeConnectionChecker
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
        val bluetoothAdapter = android.bluetooth.BluetoothAdapter.getDefaultAdapter()
        if (bluetoothAdapter == null) {
          result.error("NO_ADAPTER", "블루투스 미지원 기기", null)
          return
        }
        // 권한 체크 (Android 12 이상)
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
          val context = channel.javaClass.classLoader?.loadClass("io.flutter.embedding.engine.FlutterEngine")
          // 실제 앱에서는 ActivityCompat.checkSelfPermission을 사용해야 함
          // 여기서는 간단히 예시로만 처리
        }
        if (!bluetoothAdapter.isEnabled) {
          result.error("NOT_ENABLED", "블루투스가 비활성화되어 있습니다", null)
          return
        }
        
        try {
          val pairedDevices = bluetoothAdapter.bondedDevices ?: emptySet()
          val deviceList = pairedDevices.map {
            mapOf("name" to (it.name ?: "알 수 없는 기기"), "address" to it.address)
          }
          result.success(deviceList)
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
        val bluetoothAdapter = android.bluetooth.BluetoothAdapter.getDefaultAdapter()
        if (bluetoothAdapter == null) {
          result.error("NO_ADAPTER", "블루투스 미지원 기기", null)
          return
        }
        if (!bluetoothAdapter.isEnabled) {
          result.error("NOT_ENABLED", "블루투스가 비활성화되어 있습니다", null)
          return
        }
        val device = bluetoothAdapter.bondedDevices.firstOrNull { it.address == address }
        if (device == null) {
          result.error("NOT_FOUND", "기기를 찾을 수 없습니다", null)
          return
        }
        try {
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
          LogicReceiptProcessor.parseAndPrint(stream, receiptText)
          result.success(true)
        } catch (e: Exception) {
          Log.e("BridgeFlutterPlugin", "커스텀 영수증 출력 실패", e)
          result.error("PRINT_FAIL", "출력 실패: ${e.message}", e.stackTrace.toString())
        }
      }
      "printSampleReceipt" -> {
        val stream = outputStream
        if (stream == null) {
          result.error("NOT_CONNECTED", "프린터가 연결되지 않았습니다", null)
          return
        }
        
        try {
          Log.d("BridgeFlutterPlugin", "샘플 영수증 출력 시작")
          // 샘플 영수증도 동일한 방식으로 처리
          LogicReceiptProcessor.parseAndPrint(stream, DataSampleReceipts.sampleReceiptData)
          result.success(true)
        } catch (e: Exception) {
          Log.e("BridgeFlutterPlugin", "샘플 영수증 출력 실패", e)
          result.error("PRINT_FAIL", "샘플 영수증 출력 실패: ${e.message}", e.stackTrace.toString())
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
          Log.d("BridgeFlutterPlugin", "단일 주문 영수증 출력 시작")
          val formattedReceipt = LogicReceiptProcessor.formatSingleOrderReceipt(
            orderData, storeName, tableNumber, storeAddress, phoneNumber, businessNumber, thankYouMessage, language, currency, showStoreLabel
          )
          Log.d("BridgeFlutterPlugin", "생성된 영수증 포맷: \n$formattedReceipt")
          Log.d("BridgeFlutterPlugin", "영수증 포맷 길이: ${formattedReceipt.length}")
          LogicReceiptProcessor.parseAndPrint(stream, formattedReceipt)
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
          Log.d("BridgeFlutterPlugin", "전체 주문 영수증 출력 시작")
          val formattedReceipt = LogicReceiptProcessor.formatTotalOrderReceipt(
            orderData, storeName, tableNumber, storeAddress, phoneNumber, businessNumber, thankYouMessage, language, currency
          )
          Log.d("BridgeFlutterPlugin", "생성된 전체 영수증 포맷: \n$formattedReceipt")
          Log.d("BridgeFlutterPlugin", "전체 영수증 포맷 길이: ${formattedReceipt.length}")
          LogicReceiptProcessor.parseAndPrint(stream, formattedReceipt)
          result.success(true)
        } catch (e: Exception) {
          Log.e("BridgeFlutterPlugin", "전체 주문 영수증 출력 실패", e)
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
          Log.w("BridgeFlutterPlugin", "프린터 연결이 끊겼습니다: $reason")
          // UI 스레드에서 Flutter로 연결 끊김 알림
          mainHandler.post {
            eventSink?.success(mapOf(
              "status" to "disconnected",
              "message" to "프린터 연결이 끊겼습니다: $reason",
              "reason" to reason
            ))
          }
        },
        onConnectionRestored = {
          Log.i("BridgeFlutterPlugin", "프린터 연결이 복구되었습니다")
          // UI 스레드에서 Flutter로 연결 복구 알림
          mainHandler.post {
            eventSink?.success(mapOf(
              "status" to "connected",
              "message" to "프린터 연결이 복구되었습니다"
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
          "message" to "프린터가 연결되었습니다"
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