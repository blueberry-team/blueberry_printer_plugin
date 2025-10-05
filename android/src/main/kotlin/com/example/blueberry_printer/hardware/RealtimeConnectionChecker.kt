package com.example.blueberry_printer.hardware

import android.bluetooth.BluetoothSocket
import android.util.Log
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream
import java.net.SocketException
import java.net.SocketTimeoutException
import java.util.Timer
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.concurrent.scheduleAtFixedRate

/**
 * 프린터 연결 상태를 실시간으로 모니터링하는 클래스
 *
 * 사용 방법:
 * ```
 * val checker = RealtimeConnectionChecker(socket,
 *     onConnectionLost = {
 *         // 연결 끊김 처리
 *     },
 *     onConnectionRestored = {
 *         // 연결 복구 처리 (옵션)
 *     }
 * )
 * checker.start()
 *
 * // 사용 종료 시
 * checker.stop()
 * ```
 */
class RealtimeConnectionChecker(
    private val socket: BluetoothSocket,
    private val heartbeatIntervalMs: Long = 5000, // 5초마다 Heartbeat
    private val socketTimeoutMs: Int = 3000, // 3초 소켓 타임아웃
    private val onConnectionLost: (String) -> Unit, // 이유를 포함한 콜백
    private val onConnectionRestored: (() -> Unit)? = null
) {
    companion object {
        private const val TAG = "RealtimeConnectionChecker"

        // ESC/POS 명령어: DLE EOT n (프린터 상태 확인)
        // n=1: 프린터 상태, n=2: 오프라인 상태, n=3: 에러 상태, n=4: 용지 센서 상태
        private val STATUS_CHECK_COMMAND = byteArrayOf(0x10, 0x04, 0x01) // DLE EOT 1
    }

    private var monitorThread: MonitorThread? = null
    private var heartbeatTimer: Timer? = null
    private val isRunning = AtomicBoolean(false)
    private val isConnected = AtomicBoolean(true)
    private var outputStream: OutputStream? = null
    private var inputStream: InputStream? = null

    /**
     * 연결 모니터링 시작
     */
    fun start() {
        if (isRunning.getAndSet(true)) {
            Log.w(TAG, "Connection checker is already running")
            return
        }

        try {
            // 소켓 스트림 가져오기
            outputStream = socket.outputStream
            inputStream = socket.inputStream

            // 모니터링 스레드 시작
            monitorThread = MonitorThread().apply { start() }

            // Heartbeat 타이머 시작
            heartbeatTimer = Timer("HeartbeatTimer", true).apply {
                scheduleAtFixedRate(heartbeatIntervalMs, heartbeatIntervalMs) {
                    sendHeartbeat()
                }
            }

            Log.i(TAG, "Connection checker started successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start connection checker: ${e.message}", e)
            isRunning.set(false)
            throw e
        }
    }

    /**
     * 연결 모니터링 중지
     */
    fun stop() {
        if (!isRunning.getAndSet(false)) {
            return
        }

        try {
            // Heartbeat 타이머 중지
            heartbeatTimer?.cancel()
            heartbeatTimer = null

            // 모니터링 스레드 중지
            monitorThread?.stopMonitoring()
            monitorThread?.interrupt()
            monitorThread?.join(1000) // 최대 1초 대기
            monitorThread = null

            Log.i(TAG, "Connection checker stopped")
        } catch (e: Exception) {
            Log.e(TAG, "Error while stopping connection checker: ${e.message}", e)
        }
    }

    /**
     * 현재 연결 상태 반환
     */
    fun isConnected(): Boolean = isConnected.get() && socket.isConnected

    /**
     * Heartbeat 전송 (프린터 상태 확인 명령)
     */
    private fun sendHeartbeat() {
        if (!isRunning.get()) return

        try {
            outputStream?.let { out ->
                synchronized(out) {
                    out.write(STATUS_CHECK_COMMAND)
                    out.flush()
                }
                Log.d(TAG, "Heartbeat sent successfully")
            }
        } catch (e: SocketException) {
            Log.e(TAG, "Socket error during heartbeat: ${e.message}")
            // Heartbeat 실패는 영구적 오류로 간주
            handlePermanentConnectionLost("Heartbeat 소켓 오류")
        } catch (e: IOException) {
            Log.e(TAG, "IO error during heartbeat: ${e.message}")
            // Heartbeat 실패는 영구적 오류로 간주
            handlePermanentConnectionLost("Heartbeat I/O 오류")
        } catch (e: Exception) {
            Log.e(TAG, "Unexpected error during heartbeat: ${e.message}", e)
        }
    }

    /**
     * 연결 끊김 처리 (일시적 - 자동 복구 가능)
     */
    private fun handleConnectionLost(reason: String = "연결 끊김") {
        if (isConnected.getAndSet(false)) {
            Log.w(TAG, "Temporary connection lost detected: $reason")

            // Heartbeat는 계속 보내서 자동 복구 감지
            // (일시적 오류: 오프라인, 용지 부족 등)
            Log.i(TAG, "Keeping heartbeat alive for auto-recovery")

            try {
                onConnectionLost(reason)
            } catch (e: Exception) {
                Log.e(TAG, "Error in connection lost callback: ${e.message}", e)
            }
        }
    }

    /**
     * 연결 끊김 처리 (영구적 - Heartbeat도 중지)
     */
    private fun handlePermanentConnectionLost(reason: String = "연결 끊김") {
        if (isConnected.getAndSet(false)) {
            Log.e(TAG, "Permanent connection lost detected: $reason")

            // Heartbeat 타이머도 중지
            heartbeatTimer?.cancel()
            heartbeatTimer = null
            Log.i(TAG, "Heartbeat stopped due to permanent connection loss")

            try {
                onConnectionLost(reason)
            } catch (e: Exception) {
                Log.e(TAG, "Error in connection lost callback: ${e.message}", e)
            }
        } else {
            // 이미 끊긴 상태에서 영구적 오류 발생 - Heartbeat만 중지
            heartbeatTimer?.cancel()
            heartbeatTimer = null
            Log.i(TAG, "Heartbeat stopped due to permanent connection loss (already disconnected)")
        }
    }

    /**
     * 연결 복구 처리
     */
    private fun handleConnectionRestored() {
        if (!isConnected.getAndSet(true)) {
            Log.i(TAG, "Connection restored")
            try {
                onConnectionRestored?.invoke()
            } catch (e: Exception) {
                Log.e(TAG, "Error in connection restored callback: ${e.message}", e)
            }
        }
    }

    /**
     * 소켓 모니터링 스레드
     * InputStream을 지속적으로 읽어서 연결 상태 확인
     */
    private inner class MonitorThread : Thread("ConnectionMonitorThread") {
        @Volatile
        private var running = true
        private val buffer = ByteArray(1024)

        override fun run() {
            Log.d(TAG, "Monitor thread started")

            try {
                while (running && socket.isConnected && isRunning.get()) {
                    try {
                        val bytesRead = inputStream?.read(buffer) ?: -1

                        if (bytesRead == -1) {
                            // 연결 끊김 (EOF) - 영구적 연결 끊김
                            Log.w(TAG, "EOF detected - permanent connection lost")
                            handlePermanentConnectionLost("연결 끊김 (EOF)")
                            break
                        } else if (bytesRead > 0) {
                            // 프린터 응답 수신 (Heartbeat 응답 또는 기타 데이터)
                            Log.d(TAG, "Received $bytesRead bytes from printer")
                            processResponse(buffer, bytesRead)
                        }
                    } catch (e: SocketTimeoutException) {
                        // 타임아웃은 정상 (데이터가 없을 때)
                        // Log.d(TAG, "Socket timeout - no data available")
                    } catch (e: SocketException) {
                        if (running) {
                            Log.e(TAG, "Socket exception in monitor thread: ${e.message}")
                            handlePermanentConnectionLost("소켓 오류: ${e.message}")
                            break
                        }
                    } catch (e: IOException) {
                        if (running) {
                            Log.e(TAG, "IO exception in monitor thread: ${e.message}")
                            handlePermanentConnectionLost("I/O 오류: ${e.message}")
                            break
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Unexpected error in monitor thread: ${e.message}", e)
                handlePermanentConnectionLost("예기치 않은 오류: ${e.message}")
            } finally {
                Log.d(TAG, "Monitor thread stopped")
            }
        }

        /**
         * 프린터 응답 처리
         * @return true if connection is OK, false if should stop monitoring
         */
        private fun processResponse(data: ByteArray, length: Int): Boolean {
            // 프린터 상태 응답 분석
            if (length > 0) {
                val status = data[0].toInt() and 0xFF

                when {
                    (status and 0x08) != 0 -> {
                        Log.w(TAG, "Printer offline - but keeping monitor thread alive for auto-recovery")
                        handleConnectionLost("프린터 오프라인")
                        // 모니터 스레드는 계속 실행 (자동 복구 대기)
                        return true
                    }
                    (status and 0x20) != 0 -> {
                        Log.w(TAG, "Paper out - but keeping monitor thread alive for auto-recovery")
                        handleConnectionLost("용지 부족")
                        // 모니터 스레드는 계속 실행 (자동 복구 대기)
                        return true
                    }
                    (status and 0x40) != 0 -> {
                        Log.w(TAG, "Printer error - but keeping monitor thread alive for auto-recovery")
                        handleConnectionLost("프린터 에러")
                        // 모니터 스레드는 계속 실행 (자동 복구 대기)
                        return true
                    }
                    else -> {
                        Log.d(TAG, "Printer status: OK (0x${status.toString(16)})")
                        // 이전에 끊겼다가 정상으로 돌아온 경우
                        if (!isConnected.get()) {
                            handleConnectionRestored()
                        }
                    }
                }

                // 추가 응답 데이터가 있으면 로그
                if (length > 1) {
                    Log.d(TAG, "Additional response data: ${data.take(length).joinToString(" ") { "0x%02X".format(it) }}")
                }
            }
            return true
        }

        fun stopMonitoring() {
            running = false
        }
    }
}
