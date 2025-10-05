package com.example.blueberry_printer.common

/**
 * 프린트 관련 상수 정의
 */
object PrintConstants {

    // 폰트 크기
    object FontSize {
        const val STORE_LABEL = 24f      // 점포용 라벨
        const val TITLE = 60f            // 타이틀 (매장명)
        const val STORE_INFO = 20f       // 매장 정보
        const val SEPARATOR = 20f        // 구분선
        const val ORDER_INFO = 20f       // 주문 정보
        const val MENU_LIST = 20f        // 메뉴 목록
        const val TOTAL = 20f            // 합계
        const val THANK_YOU = 20f        // 감사 메시지
        const val TEXT_DEFAULT = 20f     // 기본 텍스트
    }

    // 줄바꿈 설정
    object LineFeed {
        const val AFTER_LABEL = 1        // 점포용 라벨 후
        const val AFTER_TITLE = 1        // 타이틀 후
        const val AFTER_STORE_INFO = 1   // 매장정보 후
        const val AFTER_SEPARATOR = 1    // 구분선 후
        const val AFTER_ORDER_INFO = 1   // 주문정보 후
        const val BEFORE_TOTAL = 2       // 합계 전
        const val AFTER_TOTAL = 2        // 합계 후
        const val BEFORE_THANK_YOU = 2   // 감사메시지 전
        const val AFTER_THANK_YOU = 3    // 감사메시지 후
        const val BEFORE_CUT = 200       // 영수증 자르기 전
    }

    // 점포용 라벨 설정
    object StoreLabel {
        const val TEXT = """
┌────────────────────┐
│        점포용        │
└────────────────────┘
        """
        const val IS_BOLD = true
    }

    // 구분선
    const val SEPARATOR_LINE = "================================"

    // 기본 UUID (블루투스 프린터)
    const val DEFAULT_PRINTER_UUID = "00001101-0000-1000-8000-00805F9B34FB"
}
