//
//  EscPosConstants.h
//  blueberry_printer
//
//  ESC/POS 프린터 명령어 상수
//

#import <Foundation/Foundation.h>

@interface EscPosConstants : NSObject

// MARK: - 기본 제어 문자
+ (const Byte)ESC;
+ (const Byte)FS;
+ (const Byte)GS;
+ (const Byte)US;
+ (const Byte)DLE;
+ (const Byte)DC4;
+ (const Byte)DC1;
+ (const Byte)SP;
+ (const Byte)NL;
+ (const Byte)FF;
+ (const Byte)PIECE;
+ (const Byte)NUL;

// MARK: - 프린터 초기화
+ (NSData*)ESC_Init;

// MARK: - 출력 명령
+ (NSData*)LF;                      // 출력 후 줄바꿈
+ (NSData*)US_vt_eot;               // 자동 검사 페이지
+ (NSData*)ESC_B_m_n;               // 벨 명령
+ (NSData*)GS_V_n;                  // 커터 명령
+ (NSData*)GS_V_m_n;                // 커터 명령
+ (NSData*)GS_i;                    // 커터 명령
+ (NSData*)GS_m;                    // 커터 명령

// MARK: - 문자 설정 명령
+ (NSData*)ESC_SP;                  // 문자 오른쪽 간격 설정
+ (NSData*)ESC_ExclamationMark;     // 문자 인쇄 글꼴 형식 설정
+ (NSData*)GS_ExclamationMark;      // 글꼴 배율 설정
+ (NSData*)GS_B;                    // 반전 출력 설정
+ (NSData*)ESC_V;                   // 90도 회전 출력 선택/취소
+ (NSData*)ESC_M;                   // 글꼴 글형 선택
+ (NSData*)ESC_G;                   // 굵게 선택/취소
+ (NSData*)ESC_E;                   // 굵게 선택/취소
+ (NSData*)ESC_LeftBrace;           // 반전 출력 모드 선택/취소
+ (NSData*)ESC_Minus;               // 밑줄 점 높이 설정(문자)
+ (NSData*)FS_dot;                  // 문자 모드
+ (NSData*)FS_and;                  // 한자 모드
+ (NSData*)FS_ExclamationMark;      // 한자 인쇄 모드 설정
+ (NSData*)FS_Minus;                // 밑줄 점 높이 설정(한자)
+ (NSData*)FS_S;                    // 한자 좌우 간격 설정
+ (NSData*)ESC_t;                   // 문자 코드 페이지 선택

// MARK: - 형식 설정 명령
+ (NSData*)ESC_Two;                 // 기본 줄 간격 설정
+ (NSData*)ESC_Three;               // 줄 간격 설정
+ (NSData*)ESC_Align;               // 정렬 모드 설정
+ (NSData*)GS_LeftSp;               // 왼쪽 간격 설정
+ (NSData*)ESC_Relative;            // 절대 출력 위치 설정
+ (NSData*)ESC_Absolute;            // 상대 출력 위치 설정
+ (NSData*)GS_W;                    // 출력 영역 너비 설정

// MARK: - 상태 명령
+ (NSData*)DLE_eot;                 // 실시간 상태 전송 명령
+ (NSData*)DLE_DC4;                 // 실시간 현금 상자 명령
+ (NSData*)ESC_p;                   // 표준 현금 상자 명령

// MARK: - 바코드 설정 명령
+ (NSData*)GS_H;                    // HRI 인쇄 방식 선택
+ (NSData*)GS_h;                    // 바코드 높이 설정
+ (NSData*)GS_w;                    // 바코드 너비 설정
+ (NSData*)GS_f;                    // HRI 문자 글꼴 글형 설정
+ (NSData*)GS_x;                    // 바코드 왼쪽 오프셋 명령
+ (NSData*)GS_k;                    // 바코드 인쇄 명령
+ (NSData*)GS_k_m_v_r_nL_nH;        // QR 코드 관련 명령

// MARK: - 출력 후 이동 명령
+ (NSData*)ESC_J;                   // 출력 후 이동

@end
