package com.example.blueberry_printer.common

/**
 * 프린터 연결 끊김 이유
 */
enum class DisconnectReason(val code: String) {
    /**
     * 알 수 없는 이유
     * Unknown reason
     * 不明な理由
     */
    UNKNOWN("UNKNOWN"),

    /**
     * 소켓 타임아웃
     * Socket timeout
     * ソケットタイムアウト
     */
    SOCKET_TIMEOUT("SOCKET_TIMEOUT"),

    /**
     * I/O 에러
     * I/O error
     * I/Oエラー
     */
    IO_ERROR("IO_ERROR"),

    /**
     * 소켓이 닫힘
     * Socket closed
     * ソケットが閉じられました
     */
    SOCKET_CLOSED("SOCKET_CLOSED"),

    /**
     * 프린터 오프라인
     * Printer offline
     * プリンターがオフライン
     */
    PRINTER_OFFLINE("PRINTER_OFFLINE"),

    /**
     * 용지 부족
     * Out of paper
     * 用紙切れ
     */
    OUT_OF_PAPER("OUT_OF_PAPER"),

    /**
     * 수동 연결 해제
     * Manual disconnect
     * 手動切断
     */
    MANUAL_DISCONNECT("MANUAL_DISCONNECT"),

    /**
     * 블루투스 비활성화
     * Bluetooth disabled
     * Bluetooth無効
     */
    BLUETOOTH_DISABLED("BLUETOOTH_DISABLED"),

    /**
     * 연결 실패
     * Connection failed
     * 接続失敗
     */
    CONNECTION_FAILED("CONNECTION_FAILED");

    companion object {
        /**
         * 문자열 코드로 DisconnectReason 찾기
         */
        fun fromCode(code: String): DisconnectReason {
            return values().find { it.code == code } ?: UNKNOWN
        }

        /**
         * 에러 메시지로부터 적절한 DisconnectReason 추론
         */
        fun fromErrorMessage(message: String): DisconnectReason {
            return when {
                message.contains("timeout", ignoreCase = true) -> SOCKET_TIMEOUT
                message.contains("closed", ignoreCase = true) -> SOCKET_CLOSED
                message.contains("offline", ignoreCase = true) -> PRINTER_OFFLINE
                message.contains("paper", ignoreCase = true) -> OUT_OF_PAPER
                message.contains("bluetooth", ignoreCase = true) -> BLUETOOTH_DISABLED
                message.contains("io", ignoreCase = true) || message.contains("ioexception", ignoreCase = true) -> IO_ERROR
                else -> UNKNOWN
            }
        }
    }
}
