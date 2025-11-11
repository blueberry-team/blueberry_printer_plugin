package com.example.blueberry_printer.drivers

import io.flutter.plugin.common.EventChannel

/**
 * 프린터 드라이버 인터페이스
 *
 * ESC/POS 프린터와 Star Micronics 프린터 등 다양한 프린터를 지원하기 위한
 * 공통 인터페이스입니다.
 */
interface PrinterDriver {
    /**
     * 프린터 타입
     */
    enum class PrinterType {
        ESC_POS,        // ESC/POS 호환 프린터
        STAR_MICRONICS, // Star Micronics 프린터
        AUTO            // 자동 감지
    }

    /**
     * 프린터 타입 반환
     */
    fun getType(): PrinterType

    /**
     * 프린터 연결
     * @param address 프린터 블루투스 주소
     * @return 연결 성공 여부
     */
    fun connect(address: String): Boolean

    /**
     * 프린터 연결 해제
     * @return 연결 해제 성공 여부
     */
    fun disconnect(): Boolean

    /**
     * 연결 상태 확인
     * @return 연결 여부
     */
    fun isConnected(): Boolean

    /**
     * 단일 주문 영수증 출력
     *
     * @param orderData 주문 데이터
     * @param storeName 매장명
     * @param tableNumber 테이블 번호 (선택)
     * @param storeAddress 매장 주소 (선택)
     * @param phoneNumber 전화번호 (선택)
     * @param businessNumber 사업자등록번호 (선택)
     * @param thankYouMessage 감사 메시지 (선택)
     * @param language 언어 (kor, eng, jpn)
     * @param currency 화폐 (KRW, USD, JPY)
     * @param showStoreLabel 점포용 라벨 표시 여부
     * @return 출력 성공 여부
     */
    fun printSingleOrder(
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
    ): Boolean

    /**
     * 전체 주문 영수증 출력 (모든 주문 버전 누적)
     *
     * @param orderData 주문 데이터
     * @param storeName 매장명
     * @param tableNumber 테이블 번호 (선택)
     * @param storeAddress 매장 주소 (선택)
     * @param phoneNumber 전화번호 (선택)
     * @param businessNumber 사업자등록번호 (선택)
     * @param thankYouMessage 감사 메시지 (선택)
     * @param language 언어 (kor, eng, jpn)
     * @param currency 화폐 (KRW, USD, JPY)
     * @return 출력 성공 여부
     */
    fun printTotalOrder(
        orderData: Map<String, Any>,
        storeName: String,
        tableNumber: String?,
        storeAddress: String?,
        phoneNumber: String?,
        businessNumber: String?,
        thankYouMessage: String?,
        language: String,
        currency: String
    ): Boolean

    /**
     * 소켓 주문 알림 출력
     *
     * @param orderData 주문 알림 데이터
     * @param language 언어 (kor, eng, jpn)
     * @param currency 화폐 (KRW, USD, JPY)
     * @return 출력 성공 여부
     */
    fun printOrderFromSocket(
        orderData: Map<String, Any>,
        language: String,
        currency: String
    ): Boolean

    /**
     * 간단한 텍스트 출력
     *
     * @param text 출력할 텍스트
     * @param fontSize 폰트 크기
     * @param isBold 굵게 표시 여부
     * @param align 정렬 (LEFT, CENTER, RIGHT)
     * @return 출력 성공 여부
     */
    fun printText(
        text: String,
        fontSize: Float,
        isBold: Boolean,
        align: String
    ): Boolean

    /**
     * 연결 상태 모니터링 시작
     *
     * @param eventSink Flutter EventChannel Sink
     * @param onConnectionLost 연결 끊김 콜백
     * @param onConnectionRestored 연결 복구 콜백
     */
    fun startConnectionMonitoring(
        eventSink: EventChannel.EventSink?,
        onConnectionLost: ((reason: String) -> Unit)?,
        onConnectionRestored: (() -> Unit)?
    )

    /**
     * 연결 상태 모니터링 중지
     */
    fun stopConnectionMonitoring()

    /**
     * 리소스 정리
     */
    fun cleanup()
}
