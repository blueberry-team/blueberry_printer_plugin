package com.example.blueberry_printer.drivers

import android.bluetooth.BluetoothSocket
import android.util.Log
import com.example.blueberry_printer.bluetooth_search.BluetoothDeviceSearcher
import com.example.blueberry_printer.common.DisconnectReason
import com.example.blueberry_printer.common.KoreanTextRenderer
import com.example.blueberry_printer.multiple_order.MultipleOrderDirectPrinter
import com.example.blueberry_printer.order_notification.OrderNotificationPrinter
import com.example.blueberry_printer.printer_connection.RealtimeConnectionChecker
import com.example.blueberry_printer.sample_receipt.SimpleTextPrinter
import com.example.blueberry_printer.single_order.SingleOrderDirectPrinter
import io.flutter.plugin.common.EventChannel
import java.io.OutputStream
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.TimeoutException

/**
 * ESC/POS 프린터 드라이버
 *
 * 기존 블루투스 소켓 기반의 ESC/POS 프린터를 지원합니다.
 */
class EscPosDriver : PrinterDriver {
    companion object {
        private const val TAG = "EscPosDriver"
        private const val CONNECT_TIMEOUT_MS = 10000L // 10초 연결 타임아웃
    }

    // 현재 연결된 블루투스 소켓과 출력 스트림
    @Volatile
    private var currentSocket: BluetoothSocket? = null
    @Volatile
    private var outputStream: OutputStream? = null

    // 연결 상태 모니터링
    private var connectionChecker: RealtimeConnectionChecker? = null

    // 출력 작업 동기화용 락
    private val printLock = Any()

    override fun getType(): PrinterDriver.PrinterType {
        return PrinterDriver.PrinterType.ESC_POS
    }

    override fun connect(address: String): Boolean {
        return try {
            Log.d(TAG, "ESC/POS 프린터 연결 시작: $address")

            // BluetoothDeviceSearcher를 사용하여 기기 찾기
            val device = BluetoothDeviceSearcher.findDeviceByAddress(address)
            val bluetoothAdapter = BluetoothDeviceSearcher.getBluetoothAdapter()

            // 소켓 연결을 타임아웃과 함께 수행
            val uuid = device.uuids?.firstOrNull()?.uuid
                ?: java.util.UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
            val socket = device.createRfcommSocketToServiceRecord(uuid)
            bluetoothAdapter.cancelDiscovery()

            // 타임아웃을 적용하기 위해 별도 스레드에서 연결
            val executor = Executors.newSingleThreadExecutor()
            val future = executor.submit<Boolean> {
                try {
                    socket.connect()
                    true
                } catch (e: Exception) {
                    Log.e(TAG, "소켓 연결 실패: ${e.message}", e)
                    false
                }
            }

            try {
                val connected = future.get(CONNECT_TIMEOUT_MS, TimeUnit.MILLISECONDS)
                if (connected) {
                    // 연결 성공 시 소켓과 출력 스트림 저장
                    currentSocket = socket
                    outputStream = socket.outputStream
                    Log.d(TAG, "ESC/POS 프린터 연결 성공")
                    true
                } else {
                    socket.close()
                    Log.e(TAG, "소켓 연결 실패")
                    false
                }
            } catch (e: TimeoutException) {
                Log.e(TAG, "연결 타임아웃 (${CONNECT_TIMEOUT_MS}ms)")
                future.cancel(true)
                socket.close()
                false
            } finally {
                executor.shutdown()
            }
        } catch (e: Exception) {
            Log.e(TAG, "ESC/POS 프린터 연결 실패: ${e.message}", e)
            false
        }
    }

    override fun disconnect(): Boolean {
        return try {
            Log.d(TAG, "ESC/POS 프린터 연결 해제")
            stopConnectionMonitoring()

            // 스트림과 소켓을 명시적으로 닫기
            synchronized(printLock) {
                try {
                    outputStream?.close()
                } catch (e: Exception) {
                    Log.w(TAG, "OutputStream 닫기 중 오류: ${e.message}")
                }
                try {
                    currentSocket?.close()
                } catch (e: Exception) {
                    Log.w(TAG, "Socket 닫기 중 오류: ${e.message}")
                }
                currentSocket = null
                outputStream = null
            }
            true
        } catch (e: Exception) {
            Log.e(TAG, "ESC/POS 프린터 연결 해제 실패: ${e.message}", e)
            false
        }
    }

    override fun isConnected(): Boolean {
        return currentSocket?.isConnected == true && outputStream != null
    }

    override fun printSingleOrder(
        orderData: Map<String, Any>,
        storeName: String,
        tableNumber: String?,
        storeAddress: String?,
        phoneNumber: String?,
        businessNumber: String?,
        thankYouMessage: String?,
        language: String,
        currency: String,
        showStoreLabel: Boolean
    ): Boolean {
        val stream = outputStream
        if (stream == null) {
            Log.e(TAG, "프린터가 연결되지 않았습니다")
            return false
        }

        return try {
            Log.d(TAG, "단일 주문 영수증 출력 시작 (ESC/POS)")
            synchronized(printLock) {
                SingleOrderDirectPrinter.print(
                    stream, orderData, storeName, tableNumber, storeAddress,
                    phoneNumber, businessNumber, thankYouMessage, language, currency, showStoreLabel
                )
                stream.flush()
            }
            Log.d(TAG, "단일 주문 영수증 출력 완료")
            true
        } catch (e: Exception) {
            Log.e(TAG, "단일 주문 영수증 출력 실패", e)
            false
        }
    }

    override fun printTotalOrder(
        orderData: Map<String, Any>,
        storeName: String,
        tableNumber: String?,
        storeAddress: String?,
        phoneNumber: String?,
        businessNumber: String?,
        thankYouMessage: String?,
        language: String,
        currency: String
    ): Boolean {
        val stream = outputStream
        if (stream == null) {
            Log.e(TAG, "프린터가 연결되지 않았습니다")
            return false
        }

        return try {
            Log.d(TAG, "전체 주문 영수증 출력 시작 (ESC/POS)")
            synchronized(printLock) {
                MultipleOrderDirectPrinter.print(
                    stream, orderData, storeName, tableNumber, storeAddress,
                    phoneNumber, businessNumber, thankYouMessage, language, currency
                )
                stream.flush()
            }
            Log.d(TAG, "전체 주문 영수증 출력 완료")
            true
        } catch (e: Exception) {
            Log.e(TAG, "전체 주문 영수증 출력 실패", e)
            false
        }
    }

    override fun printOrderFromSocket(
        orderData: Map<String, Any>,
        language: String,
        currency: String
    ): Boolean {
        val stream = outputStream
        if (stream == null) {
            Log.e(TAG, "프린터가 연결되지 않았습니다")
            return false
        }

        return try {
            Log.d(TAG, "주문 알림 영수증 출력 시작 (ESC/POS)")
            synchronized(printLock) {
                OrderNotificationPrinter.print(stream, orderData, language, currency)
                stream.flush()
            }
            Log.d(TAG, "주문 알림 영수증 출력 완료")
            true
        } catch (e: Exception) {
            Log.e(TAG, "주문 알림 영수증 출력 실패", e)
            false
        }
    }

    override fun printText(
        text: String,
        fontSize: Float,
        isBold: Boolean,
        align: String
    ): Boolean {
        val stream = outputStream
        if (stream == null) {
            Log.e(TAG, "프린터가 연결되지 않았습니다")
            return false
        }

        return try {
            Log.d(TAG, "텍스트 출력 시작 (ESC/POS): $text")

            // 정렬 방식 변환
            val textAlign = when (align.uppercase()) {
                "CENTER" -> KoreanTextRenderer.TextAlign.CENTER
                "RIGHT" -> KoreanTextRenderer.TextAlign.RIGHT
                else -> KoreanTextRenderer.TextAlign.LEFT
            }

            synchronized(printLock) {
                SimpleTextPrinter.print(stream, text, fontSize, isBold, textAlign)
                stream.flush()
            }
            Log.d(TAG, "텍스트 출력 완료")
            true
        } catch (e: Exception) {
            Log.e(TAG, "텍스트 출력 실패", e)
            false
        }
    }

    override fun startConnectionMonitoring(
        eventSink: EventChannel.EventSink?,
        onConnectionLost: ((reason: String) -> Unit)?,
        onConnectionRestored: (() -> Unit)?
    ) {
        val socket = currentSocket ?: return

        // 기존 모니터링 중지
        stopConnectionMonitoring()

        try {
            connectionChecker = RealtimeConnectionChecker(
                socket = socket,
                outputStreamLock = printLock, // 출력 스트림 동기화 락 전달
                heartbeatIntervalMs = 5000, // 5초마다 Heartbeat
                socketTimeoutMs = 3000, // 3초 타임아웃
                onConnectionLost = { reason ->
                    Log.w(TAG, "ESC/POS 프린터 연결 끊김: ${reason.code}")
                    onConnectionLost?.invoke(reason.code)
                },
                onConnectionRestored = {
                    Log.i(TAG, "ESC/POS 프린터 연결 복구")
                    onConnectionRestored?.invoke()
                }
            )
            connectionChecker?.start()
            Log.i(TAG, "ESC/POS 프린터 연결 모니터링 시작")
        } catch (e: Exception) {
            Log.e(TAG, "연결 모니터링 시작 실패: ${e.message}", e)
        }
    }

    override fun stopConnectionMonitoring() {
        connectionChecker?.stop()
        connectionChecker = null
        Log.i(TAG, "ESC/POS 프린터 연결 모니터링 중지")
    }

    override fun cleanup() {
        stopConnectionMonitoring()
        disconnect()
    }
}
