package com.example.bluberry_printer

object SampleMockData {
    
    // 개별 섹션 텍스트 데이터
    const val TITLE_TEXT = "*** 영수증 ***"
    
    const val STORE_INFO_TEXT = """매장명: 한국 상점
주소: 서울시 강남구
전화: 02-1234-5678"""
    
    const val SEPARATOR_TEXT = "--------------------------------"
    
    const val ITEMS_TEXT = """상품명         단가    수량   금액
아메리카노     3,000    2    6,000
카페라떼       4,000    1    4,000
케이크         5,000    1    5,000"""
    
    const val TOTAL_TEXT = """합계: 15,000원
부가세: 1,500원
총액: 16,500원"""
    
    const val THANK_YOU_TEXT = "이용해 주셔서 감사합니다!"
    
    // 기존 샘플 영수증 데이터 (호환성을 위해 유지)
    val sampleReceiptData = """
        타이틀, 24
        $TITLE_TEXT
        
        줄바꿈, 3
        
        매장정보, 16
        $STORE_INFO_TEXT
        
        구분선, 14
        $SEPARATOR_TEXT
        
        상품목록, 14
        $ITEMS_TEXT
        
        구분선, 14
        $SEPARATOR_TEXT
        
        합계, 16
        $TOTAL_TEXT
        
        감사메시지, 16
        $THANK_YOU_TEXT
        
        영수증 자르기
    """.trimIndent()
} 