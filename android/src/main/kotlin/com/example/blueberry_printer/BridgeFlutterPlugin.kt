package com.example.blueberry_printer

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import android.util.Log
import com.example.blueberry_printer.drivers.PrinterDriver
import com.example.blueberry_printer.drivers.EscPosDriver
import com.example.blueberry_printer.drivers.StarIoDriver
import com.example.blueberry_printer.bluetooth_search.BluetoothDeviceSearcher
import io.flutter.plugin.common.EventChannel
import android.os.Handler
import android.os.Looper
import java.util.concurrent.Executors
import java.util.concurrent.ExecutorService

/** BridgeFlutterPlugin - 리팩토링 버전 (멀티 드라이버 지원) */
class BridgeFlutterPlugin: FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
    companion object {
        private const val TAG = "BridgeFlutterPlugin"
    }

    private lateinit var channel : MethodChannel
    private lateinit var eventChannel : EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private lateinit var context: Context

    // 현재 사용 중인 프린터 드라이버
    private var currentDriver: PrinterDriver? = null
    private var currentDeviceName: String? = null

    // UI 스레드 핸들러
    private val mainHandler = Handler(Looper.getMainLooper())

    // 백그라운드 작업용 스레드 풀
    private val executorService: ExecutorService = Executors.newSingleThreadExecutor()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext

        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "blueberry_printer")
        channel.setMethodCallHandler(this)

        // EventChannel 설정 (연결 상태 스트림)
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "blueberry_printer/connection_status")
        eventChannel.setStreamHandler(this)

        Log.i(TAG, "BlueberryPrinter 플러그인 초기화 완료 (멀티 드라이버 지원)")
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
                    Log.d(TAG, "검색된 기기 목록: $deviceList")
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

                // 백그라운드 스레드에서 연결 작업 수행
                executorService.execute {
                    try {
                        // 기기 이름으로 프린터 타입 감지
                        val device = BluetoothDeviceSearcher.findDeviceByAddress(address)
                        val deviceName = device.name ?: "Unknown"
                        val printerType = BluetoothDeviceSearcher.detectPrinterType(deviceName)

                        Log.i(TAG, "연결 시도: $deviceName ($address) - 타입: $printerType")

                        // 기존 드라이버 정리
                        currentDriver?.cleanup()

                        // 프린터 타입에 따라 적절한 드라이버 선택
                        val driver: PrinterDriver = when (printerType) {
                            "star_micronics" -> {
                                Log.i(TAG, "Star Micronics 드라이버 사용")
                                StarIoDriver(context)
                            }
                            else -> {
                                Log.i(TAG, "ESC/POS 드라이버 사용")
                                EscPosDriver()
                            }
                        }

                        // 프린터 연결
                        val connected = driver.connect(address)

                        // 메인 스레드에서 결과 반환
                        mainHandler.post {
                            if (connected) {
                                currentDriver = driver
                                currentDeviceName = deviceName

                                // 연결 상태 모니터링 시작
                                startConnectionMonitoring(driver)

                                Log.i(TAG, "프린터 연결 성공: $deviceName (${driver.getType()})")
                                result.success(true)
                            } else {
                                Log.e(TAG, "프린터 연결 실패")
                                result.error("CONNECT_FAIL", "프린터 연결 실패", null)
                            }
                        }
                    } catch (e: BluetoothDeviceSearcher.BluetoothNotSupportedException) {
                        mainHandler.post {
                            result.error("NO_ADAPTER", e.message, null)
                        }
                    } catch (e: BluetoothDeviceSearcher.BluetoothNotEnabledException) {
                        mainHandler.post {
                            result.error("NOT_ENABLED", e.message, null)
                        }
                    } catch (e: BluetoothDeviceSearcher.DeviceNotFoundException) {
                        mainHandler.post {
                            result.error("NOT_FOUND", e.message, null)
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "연결 중 오류 발생", e)
                        mainHandler.post {
                            result.error("CONNECT_FAIL", "연결 실패: ${e.message}", null)
                        }
                    }
                }
            }

            "printReceipt" -> {
                val receiptText = call.argument<String>("receiptText")
                if (receiptText == null) {
                    result.error("NO_TEXT", "출력할 텍스트가 필요합니다", null)
                    return
                }

                val driver = currentDriver
                if (driver == null) {
                    result.error("NOT_CONNECTED", "프린터가 연결되지 않았습니다", null)
                    return
                }

                try {
                    Log.d(TAG, "커스텀 영수증 출력 (${driver.getType()})")
                    val success = driver.printText(receiptText, 20f, false, "LEFT")
                    result.success(success)
                } catch (e: Exception) {
                    Log.e(TAG, "영수증 출력 실패", e)
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

                val driver = currentDriver
                if (driver == null) {
                    result.error("NOT_CONNECTED", "프린터가 연결되지 않았습니다", null)
                    return
                }

                try {
                    Log.d(TAG, "텍스트 출력 (${driver.getType()}): $text")
                    val success = driver.printText(text, fontSize, isBold, alignString)
                    result.success(success)
                } catch (e: Exception) {
                    Log.e(TAG, "텍스트 출력 실패", e)
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

                val driver = currentDriver
                if (driver == null) {
                    result.error("NOT_CONNECTED", "프린터가 연결되지 않았습니다", null)
                    return
                }

                try {
                    Log.d(TAG, "단일 주문 영수증 출력 (${driver.getType()})")
                    val success = driver.printSingleOrder(
                        orderData, storeName, tableNumber, storeAddress,
                        phoneNumber, businessNumber, thankYouMessage, language, currency, showStoreLabel
                    )
                    result.success(success)
                } catch (e: Exception) {
                    Log.e(TAG, "단일 주문 영수증 출력 실패", e)
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

                val driver = currentDriver
                if (driver == null) {
                    result.error("NOT_CONNECTED", "프린터가 연결되지 않았습니다", null)
                    return
                }

                try {
                    Log.d(TAG, "전체 주문 영수증 출력 (${driver.getType()})")
                    val success = driver.printTotalOrder(
                        orderData, storeName, tableNumber, storeAddress,
                        phoneNumber, businessNumber, thankYouMessage, language, currency
                    )
                    result.success(success)
                } catch (e: Exception) {
                    Log.e(TAG, "전체 주문 영수증 출력 실패", e)
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

                val driver = currentDriver
                if (driver == null) {
                    result.error("NOT_CONNECTED", "프린터가 연결되지 않았습니다", null)
                    return
                }

                try {
                    Log.d(TAG, "주문 알림 영수증 출력 (${driver.getType()})")
                    val success = driver.printOrderFromSocket(orderData, language, currency)
                    result.success(success)
                } catch (e: Exception) {
                    Log.e(TAG, "주문 알림 영수증 출력 실패", e)
                    result.error("PRINT_FAIL", "출력 실패: ${e.message}", e.stackTrace.toString())
                }
            }

            "disconnect" -> {
                try {
                    currentDriver?.cleanup()
                    currentDriver = null
                    currentDeviceName = null
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
        currentDriver?.cleanup()
        currentDriver = null
        currentDeviceName = null
        eventSink = null

        // 스레드 풀 종료
        executorService.shutdown()

        Log.i(TAG, "BlueberryPrinter 플러그인 해제")
    }

    /**
     * 연결 상태 모니터링 시작
     */
    private fun startConnectionMonitoring(driver: PrinterDriver) {
        driver.startConnectionMonitoring(
            eventSink = eventSink,
            onConnectionLost = { reason ->
                Log.w(TAG, "프린터 연결 끊김 ($currentDeviceName): $reason")
                mainHandler.post {
                    eventSink?.success(mapOf(
                        "status" to "disconnected",
                        "message" to "",
                        "reason" to reason
                    ))
                }
            },
            onConnectionRestored = {
                Log.i(TAG, "프린터 연결 복구 ($currentDeviceName)")
                mainHandler.post {
                    eventSink?.success(mapOf(
                        "status" to "connected",
                        "message" to ""
                    ))
                }
            }
        )

        // 초기 연결 성공 알림
        mainHandler.post {
            eventSink?.success(mapOf(
                "status" to "connected",
                "message" to ""
            ))
        }
    }
}
