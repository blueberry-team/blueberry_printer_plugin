//
//  DisconnectReason.h
//  blueberry_printer
//
//  프린터 연결 끊김 이유
//

#import <Foundation/Foundation.h>

/**
 * 프린터 연결 해제 이유 enum
 */
typedef NS_ENUM(NSInteger, DisconnectReason) {
    DisconnectReasonUnknown,            // 알 수 없는 이유 / Unknown reason / 不明な理由
    DisconnectReasonSocketTimeout,      // 소켓 타임아웃 / Socket timeout / ソケットタイムアウト
    DisconnectReasonIOError,            // I/O 에러 / I/O error / I/Oエラー
    DisconnectReasonSocketClosed,       // 소켓이 닫힘 / Socket closed / ソケットが閉じられました
    DisconnectReasonPrinterOffline,     // 프린터 오프라인 / Printer offline / プリンターがオフライン
    DisconnectReasonOutOfPaper,         // 용지 부족 / Out of paper / 用紙切れ
    DisconnectReasonManualDisconnect,   // 수동 연결 해제 / Manual disconnect / 手動切断
    DisconnectReasonBluetoothDisabled,  // 블루투스 비활성화 / Bluetooth disabled / Bluetooth無効
    DisconnectReasonConnectionFailed    // 연결 실패 / Connection failed / 接続失敗
};

/**
 * DisconnectReason 헬퍼 클래스
 */
@interface DisconnectReasonHelper : NSObject

/**
 * DisconnectReason을 문자열 코드로 변환
 */
+ (NSString*)codeFromReason:(DisconnectReason)reason;

/**
 * 문자열 코드를 DisconnectReason으로 변환
 */
+ (DisconnectReason)reasonFromCode:(NSString*)code;

/**
 * 에러 메시지로부터 적절한 DisconnectReason 추론
 */
+ (DisconnectReason)reasonFromErrorMessage:(NSString*)message;

@end
