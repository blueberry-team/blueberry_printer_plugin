package com.example.bluberry_printer

class Command {

    companion object {
        private const val ESC: Byte = 0x1B
        private const val FS: Byte = 0x1C
        private const val GS: Byte = 0x1D
        private const val US: Byte = 0x1F
        private const val DLE: Byte = 0x10
        private const val DC4: Byte = 0x14
        private const val DC1: Byte = 0x11
        private const val SP: Byte = 0x20
        private const val NL: Byte = 0x0A
        private const val FF: Byte = 0x0C
        const val PIECE: Byte = 0xFF.toByte()
        const val NUL: Byte = 0x00.toByte()

        // 프린터 초기화
        val ESC_Init = byteArrayOf(ESC, '@'.toByte())

        /**
         * 출력 명령
         */
        // 출력 후 줄바꿈
        val LF = byteArrayOf(NL)

        // 자동 검사 페이지
        val US_vt_eot = byteArrayOf(US, DC1, 0x04)

        // 벨 명령
        val ESC_B_m_n = byteArrayOf(ESC, 'B'.toByte(), 0x00, 0x00)

        // 커터 명령
        val GS_V_n = byteArrayOf(GS, 'V'.toByte(), 0x00)
        val GS_V_m_n = byteArrayOf(GS, 'V'.toByte(), 'B'.toByte(), 0x00)
        val GS_i = byteArrayOf(ESC, 'i'.toByte())
        val GS_m = byteArrayOf(ESC, 'm'.toByte())

        /**
         * 문자 설정 명령
         */
        // 문자 오른쪽 간격 설정
        val ESC_SP = byteArrayOf(ESC, SP, 0x00)

        // 문자 인쇄 글꼴 형식 설정
        val ESC_ExclamationMark = byteArrayOf(ESC, '!'.toByte(), 0x00)

        // 글꼴 배율 설정
        val GS_ExclamationMark = byteArrayOf(GS, '!'.toByte(), 0x00)

        // 반전 출력 설정
        val GS_B = byteArrayOf(GS, 'B'.toByte(), 0x00)

        // 90도 회전 출력 선택/취소
        val ESC_V = byteArrayOf(ESC, 'V'.toByte(), 0x00)

        // 글꼴 글형 선택(주로 ASCII 코드)
        val ESC_M = byteArrayOf(ESC, 'M'.toByte(), 0x00)

        // 굵게 선택/취소 명령
        val ESC_G = byteArrayOf(ESC, 'G'.toByte(), 0x00)
        val ESC_E = byteArrayOf(ESC, 'E'.toByte(), 0x00)

        // 반전 출력 모드 선택/취소
        val ESC_LeftBrace = byteArrayOf(ESC, '{'.toByte(), 0x00)

        // 밑줄 점 높이 설정(문자)
        val ESC_Minus = byteArrayOf(ESC, 45, 0x00)

        // 문자 모드
        val FS_dot = byteArrayOf(FS, 46)

        // 한자 모드
        val FS_and = byteArrayOf(FS, '&'.toByte())

        // 한자 인쇄 모드 설정
        val FS_ExclamationMark = byteArrayOf(FS, '!'.toByte(), 0x00)

        // 밑줄 점 높이 설정(한자)
        val FS_Minus = byteArrayOf(FS, 45, 0x00)

        // 한자 좌우 간격 설정
        val FS_S = byteArrayOf(FS, 'S'.toByte(), 0x00, 0x00)

        // 문자 코드 페이지 선택
        val ESC_t = byteArrayOf(ESC, 't'.toByte(), 0x00)

        /**
         * 형식 설정 명령
         */
        // 기본 줄 간격 설정
        val ESC_Two = byteArrayOf(ESC, 50)

        // 줄 간격 설정
        val ESC_Three = byteArrayOf(ESC, 51, 0x00)

        // 정렬 모드 설정
        val ESC_Align = byteArrayOf(ESC, 'a'.toByte(), 0x00)

        // 왼쪽 간격 설정
        val GS_LeftSp = byteArrayOf(GS, 'L'.toByte(), 0x00, 0x00)

        // 절대 출력 위치 설정
        // 현재 위치를 행의 시작점에서 (nL + nH x 256) 위치로 설정합니다.
        // 설정 위치가 지정된 출력 영역을 벗어나면 이 명령은 무시됩니다.
        val ESC_Relative = byteArrayOf(ESC, '$'.toByte(), 0x00, 0x00)

        // 상대 출력 위치 설정
        val ESC_Absolute = byteArrayOf(ESC, 92, 0x00, 0x00)

        // 출력 영역 너비 설정
        val GS_W = byteArrayOf(GS, 'W'.toByte(), 0x00, 0x00)

        /**
         * 상태 명령
         */
        // 실시간 상태 전송 명령
        val DLE_eot = byteArrayOf(DLE, 0x04, 0x00)

        // 실시간 현금 상자 명령
        val DLE_DC4 = byteArrayOf(DLE, DC4, 0x00, 0x00, 0x00)

        // 표준 현금 상자 명령
        val ESC_p = byteArrayOf(ESC, 'F'.toByte(), 0x00, 0x00, 0x00)

        /**
         * 바코드 설정 명령
         */
        // HRI 인쇄 방식 선택
        val GS_H = byteArrayOf(GS, 'H'.toByte(), 0x00)

        // 바코드 높이 설정
        val GS_h = byteArrayOf(GS, 'h'.toByte(), 0xa2.toByte())

        // 바코드 너비 설정
        val GS_w = byteArrayOf(GS, 'w'.toByte(), 0x00)

        // HRI 문자 글꼴 글형 설정
        val GS_f = byteArrayOf(GS, 'f'.toByte(), 0x00)

        // 바코드 왼쪽 오프셋 명령
        val GS_x = byteArrayOf(GS, 'x'.toByte(), 0x00)

        // 바코드 인쇄 명령
        val GS_k = byteArrayOf(GS, 'k'.toByte(), 'A'.toByte(), FF)

        // QR 코드 관련 명령
        val GS_k_m_v_r_nL_nH = byteArrayOf(ESC, 'Z'.toByte(), 0x03, 0x03, 0x08, 0x00, 0x00)

        // 출력 후 이동 명령
        val ESC_J = byteArrayOf(ESC, 'J'.toByte(), 0x00)
    }
} 