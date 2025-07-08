import Foundation

class EscPosConstants {
    // 제어 문자 정의
    private static let ESC: UInt8 = 0x1B
    private static let FS: UInt8 = 0x1C
    private static let GS: UInt8 = 0x1D
    private static let US: UInt8 = 0x1F
    private static let DLE: UInt8 = 0x10
    private static let DC4: UInt8 = 0x14
    private static let DC1: UInt8 = 0x11
    private static let SP: UInt8 = 0x20
    private static let NL: UInt8 = 0x0A
    private static let FF: UInt8 = 0x0C
    static let PIECE: UInt8 = 0xFF
    static let NUL: UInt8 = 0x00
    
    // 프린터 초기화
    static let ESC_Init = Data([ESC, 0x40]) // ESC @
    
    // MARK: - 출력 명령
    // 출력 후 줄바꿈
    static let LF = Data([NL])
    
    // 자동 검사 페이지
    static let US_vt_eot = Data([US, DC1, 0x04])
    
    // 벨 명령
    static var ESC_B_m_n = Data([ESC, 0x42, 0x00, 0x00]) // ESC B
    
    // 커터 명령
    static let GS_V_n = Data([GS, 0x56, 0x00]) // GS V 0
    static let GS_V_m_n = Data([GS, 0x56, 0x42, 0x00]) // GS V B
    static let GS_i = Data([ESC, 0x69]) // ESC i
    static let GS_m = Data([ESC, 0x6D]) // ESC m
    
    // MARK: - 문자 설정 명령
    // 문자 오른쪽 간격 설정
    static var ESC_SP = Data([ESC, SP, 0x00])
    
    // 문자 인쇄 글꼴 형식 설정
    static var ESC_ExclamationMark = Data([ESC, 0x21, 0x00]) // ESC !
    
    // 글꼴 배율 설정
    static var GS_ExclamationMark = Data([GS, 0x21, 0x00]) // GS !
    
    // 반전 출력 설정
    static var GS_B = Data([GS, 0x42, 0x00]) // GS B
    
    // 90도 회전 출력 선택/취소
    static var ESC_V = Data([ESC, 0x56, 0x00]) // ESC V
    
    // 글꼴 글형 선택(주로 ASCII 코드)
    static var ESC_M = Data([ESC, 0x4D, 0x00]) // ESC M
    
    // 굵게 선택/취소 명령
    static var ESC_G = Data([ESC, 0x47, 0x00]) // ESC G
    static var ESC_E = Data([ESC, 0x45, 0x00]) // ESC E
    
    // 반전 출력 모드 선택/취소
    static var ESC_LeftBrace = Data([ESC, 0x7B, 0x00]) // ESC {
    
    // 밑줄 점 높이 설정(문자)
    static var ESC_Minus = Data([ESC, 0x2D, 0x00]) // ESC -
    
    // 문자 모드
    static let FS_dot = Data([FS, 0x2E]) // FS .
    
    // 한자 모드
    static let FS_and = Data([FS, 0x26]) // FS &
    
    // 한자 인쇄 모드 설정
    static var FS_ExclamationMark = Data([FS, 0x21, 0x00]) // FS !
    
    // 밑줄 점 높이 설정(한자)
    static var FS_Minus = Data([FS, 0x2D, 0x00]) // FS -
    
    // 한자 좌우 간격 설정
    static var FS_S = Data([FS, 0x53, 0x00, 0x00]) // FS S
    
    // 문자 코드 페이지 선택
    static var ESC_t = Data([ESC, 0x74, 0x00]) // ESC t
    
    // MARK: - 형식 설정 명령
    // 기본 줄 간격 설정
    static let ESC_Two = Data([ESC, 0x32]) // ESC 2
    
    // 줄 간격 설정
    static var ESC_Three = Data([ESC, 0x33, 0x00]) // ESC 3
    
    // 정렬 모드 설정
    static var ESC_Align = Data([ESC, 0x61, 0x00]) // ESC a
    
    // 왼쪽 간격 설정
    static var GS_LeftSp = Data([GS, 0x4C, 0x00, 0x00]) // GS L
    
    // 절대 출력 위치 설정
    static var ESC_Relative = Data([ESC, 0x24, 0x00, 0x00]) // ESC $
    
    // 상대 출력 위치 설정
    static var ESC_Absolute = Data([ESC, 0x5C, 0x00, 0x00]) // ESC \
    
    // 출력 영역 너비 설정
    static var GS_W = Data([GS, 0x57, 0x00, 0x00]) // GS W
    
    // MARK: - 상태 명령
    // 실시간 상태 전송 명령
    static var DLE_eot = Data([DLE, 0x04, 0x00])
    
    // 실시간 현금 상자 명령
    static var DLE_DC4 = Data([DLE, DC4, 0x00, 0x00, 0x00])
    
    // 표준 현금 상자 명령
    static var ESC_p = Data([ESC, 0x46, 0x00, 0x00, 0x00]) // ESC F
    
    // MARK: - 바코드 설정 명령
    // HRI 인쇄 방식 선택
    static var GS_H = Data([GS, 0x48, 0x00]) // GS H
    
    // 바코드 높이 설정
    static let GS_h = Data([GS, 0x68, 0xA2]) // GS h
    
    // 바코드 너비 설정
    static var GS_w = Data([GS, 0x77, 0x00]) // GS w
    
    // HRI 문자 글꼴 글형 설정
    static var GS_f = Data([GS, 0x66, 0x00]) // GS f
    
    // 바코드 왼쪽 오프셋 명령
    static var GS_x = Data([GS, 0x78, 0x00]) // GS x
    
    // 바코드 인쇄 명령
    static let GS_k = Data([GS, 0x6B, 0x41, PIECE]) // GS k A
    
    // QR 코드 관련 명령
    static let GS_k_m_v_r_nL_nH = Data([ESC, 0x5A, 0x03, 0x03, 0x08, 0x00, 0x00]) // ESC Z
    
    // 출력 후 이동 명령
    static var ESC_J = Data([ESC, 0x4A, 0x00]) // ESC J
} 