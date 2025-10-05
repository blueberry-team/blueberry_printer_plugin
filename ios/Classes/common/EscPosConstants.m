//
//  EscPosConstants.m
//  blueberry_printer
//
//  ESC/POS 프린터 명령어 상수
//

#import "EscPosConstants.h"

@implementation EscPosConstants

// MARK: - 기본 제어 문자
+ (const Byte)ESC { return 0x1B; }
+ (const Byte)FS { return 0x1C; }
+ (const Byte)GS { return 0x1D; }
+ (const Byte)US { return 0x1F; }
+ (const Byte)DLE { return 0x10; }
+ (const Byte)DC4 { return 0x14; }
+ (const Byte)DC1 { return 0x11; }
+ (const Byte)SP { return 0x20; }
+ (const Byte)NL { return 0x0A; }
+ (const Byte)FF { return 0x0C; }
+ (const Byte)PIECE { return 0xFF; }
+ (const Byte)NUL { return 0x00; }

// MARK: - 프린터 초기화
+ (NSData*)ESC_Init {
    Byte bytes[] = {[self ESC], '@'};
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

// MARK: - 출력 명령
+ (NSData*)LF {
    Byte bytes[] = {[self NL]};
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

+ (NSData*)US_vt_eot {
    Byte bytes[] = {[self US], [self DC1], 0x04};
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

+ (NSData*)ESC_B_m_n {
    Byte bytes[] = {[self ESC], 'B', 0x00, 0x00};
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

+ (NSData*)GS_V_n {
    Byte bytes[] = {[self GS], 'V', 0x00};
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

+ (NSData*)GS_V_m_n {
    Byte bytes[] = {[self GS], 'V', 'B', 0x00};
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

+ (NSData*)GS_i {
    Byte bytes[] = {[self ESC], 'i'};
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

+ (NSData*)GS_m {
    Byte bytes[] = {[self ESC], 'm'};
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

// MARK: - 문자 설정 명령
+ (NSData*)ESC_SP {
    Byte bytes[] = {[self ESC], [self SP], 0x00};
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

+ (NSData*)ESC_ExclamationMark {
    Byte bytes[] = {[self ESC], '!', 0x00};
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

+ (NSData*)GS_ExclamationMark {
    Byte bytes[] = {[self GS], '!', 0x00};
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

+ (NSData*)GS_B {
    Byte bytes[] = {[self GS], 'B', 0x00};
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

+ (NSData*)ESC_V {
    Byte bytes[] = {[self ESC], 'V', 0x00};
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

+ (NSData*)ESC_M {
    Byte bytes[] = {[self ESC], 'M', 0x00};
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

+ (NSData*)ESC_G {
    Byte bytes[] = {[self ESC], 'G', 0x00};
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

+ (NSData*)ESC_E {
    Byte bytes[] = {[self ESC], 'E', 0x00};
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

+ (NSData*)ESC_LeftBrace {
    Byte bytes[] = {[self ESC], '{', 0x00};
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

+ (NSData*)ESC_Minus {
    Byte bytes[] = {[self ESC], 45, 0x00};
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

+ (NSData*)FS_dot {
    Byte bytes[] = {[self FS], 46};
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

+ (NSData*)FS_and {
    Byte bytes[] = {[self FS], '&'};
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

+ (NSData*)FS_ExclamationMark {
    Byte bytes[] = {[self FS], '!', 0x00};
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

+ (NSData*)FS_Minus {
    Byte bytes[] = {[self FS], 45, 0x00};
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

+ (NSData*)FS_S {
    Byte bytes[] = {[self FS], 'S', 0x00, 0x00};
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

+ (NSData*)ESC_t {
    Byte bytes[] = {[self ESC], 't', 0x00};
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

// MARK: - 형식 설정 명령
+ (NSData*)ESC_Two {
    Byte bytes[] = {[self ESC], 50};
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

+ (NSData*)ESC_Three {
    Byte bytes[] = {[self ESC], 51, 0x00};
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

+ (NSData*)ESC_Align {
    Byte bytes[] = {[self ESC], 'a', 0x00};
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

+ (NSData*)GS_LeftSp {
    Byte bytes[] = {[self GS], 'L', 0x00, 0x00};
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

+ (NSData*)ESC_Relative {
    Byte bytes[] = {[self ESC], '$', 0x00, 0x00};
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

+ (NSData*)ESC_Absolute {
    Byte bytes[] = {[self ESC], 92, 0x00, 0x00};
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

+ (NSData*)GS_W {
    Byte bytes[] = {[self GS], 'W', 0x00, 0x00};
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

// MARK: - 상태 명령
+ (NSData*)DLE_eot {
    Byte bytes[] = {[self DLE], 0x04, 0x00};
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

+ (NSData*)DLE_DC4 {
    Byte bytes[] = {[self DLE], [self DC4], 0x00, 0x00, 0x00};
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

+ (NSData*)ESC_p {
    Byte bytes[] = {[self ESC], 'F', 0x00, 0x00, 0x00};
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

// MARK: - 바코드 설정 명령
+ (NSData*)GS_H {
    Byte bytes[] = {[self GS], 'H', 0x00};
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

+ (NSData*)GS_h {
    Byte bytes[] = {[self GS], 'h', 0xa2};
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

+ (NSData*)GS_w {
    Byte bytes[] = {[self GS], 'w', 0x00};
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

+ (NSData*)GS_f {
    Byte bytes[] = {[self GS], 'f', 0x00};
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

+ (NSData*)GS_x {
    Byte bytes[] = {[self GS], 'x', 0x00};
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

+ (NSData*)GS_k {
    Byte bytes[] = {[self GS], 'k', 'A', [self FF]};
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

+ (NSData*)GS_k_m_v_r_nL_nH {
    Byte bytes[] = {[self ESC], 'Z', 0x03, 0x03, 0x08, 0x00, 0x00};
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

// MARK: - 출력 후 이동 명령
+ (NSData*)ESC_J {
    Byte bytes[] = {[self ESC], 'J', 0x00};
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

@end
