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

/**
 * ESC/POS 프린터 드라이버
 *
 * 기존 블루투스 소켓 기반의 ESC/POS 프린터를 지원합니다.
 */
class EscPosDriver : PrinterDriver {
    companion object {
        private const val TAG = "EscPosDriver"
    }

    // 현재 연결된 블루투스 소켓과 출력 스트림
    private var currentSocket: BluetoothSocket? = null
    private var outputStream: OutputStream? = null

    // 연결 상태 모니터링
    private var connectionChecker: RealtimeConnectionChecker? = null

    override fun getType(): PrinterDriver.PrinterType {
        return PrinterDriver.PrinterType.ESC_POS
    }

    override fun connect(address: String): Boolean {
        return try {
            Log.d(TAG, "ESC/POS 프린터 연결 시작: $address")

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

            Log.d(TAG, "ESC/POS 프린터 연결 성공")
            true
        } catch (e: Exception) {
            Log.e(TAG, "ESC/POS 프린터 연결 실패: ${e.message}", e)
            false
        }
    }

    override fun disconnect(): Boolean {
        return try {
            Log.d(TAG, "ESC/POS 프린터 연결 해제")
            stopConnectionMonitoring()
            currentSocket?.close()
            currentSocket = null
            outputStream = null
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
            SingleOrderDirectPrinter.print(
                stream, orderData, storeName, tableNumber, storeAddress,
                phoneNumber, businessNumber, thankYouMessage, language, currency, showStoreLabel
            )
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
            MultipleOrderDirectPrinter.print(
                stream, orderData, storeName, tableNumber, storeAddress,
                phoneNumber, businessNumber, thankYouMessage, language, currency
            )
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
            OrderNotificationPrinter.print(stream, orderData, language, currency)
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

            SimpleTextPrinter.print(stream, text, fontSize, isBold, textAlign)
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
