//
//  RealtimeConnectionChecker.h
//  blueberry_printer
//
//  프린터 연결 상태를 실시간으로 모니터링하는 클래스
//

#import <Foundation/Foundation.h>
#import <blueberry_printer/PrinterSDK.h>
#import <blueberry_printer/DisconnectReason.h>

/**
 * 연결 끊김 콜백
 * @param reason 연결 해제 이유
 */
typedef void(^ConnectionLostCallback)(DisconnectReason reason);

/**
 * 연결 복구 콜백
 */
typedef void(^ConnectionRestoredCallback)(void);

/**
 * 프린터 연결 상태 실시간 모니터링 클래스
 *
 * 사용 방법:
 * ```
 * RealtimeConnectionChecker* checker = [[RealtimeConnectionChecker alloc]
 *     initWithPrinterSDK:printerSDK
 *     onConnectionLost:^(DisconnectReason reason) {
 *         // 연결 끊김 처리
 *     }
 *     onConnectionRestored:^{
 *         // 연결 복구 처리 (옵션)
 *     }];
 * [checker startChecking];
 *
 * // 사용 종료 시
 * [checker stopChecking];
 * ```
 */
@interface RealtimeConnectionChecker : NSObject

/**
 * 초기화
 * @param printerSDK PrinterSDK 인스턴스
 * @param onConnectionLost 연결 끊김 콜백
 * @param onConnectionRestored 연결 복구 콜백 (옵션)
 */
- (instancetype)initWithPrinterSDK:(PrinterSDK*)printerSDK
                onConnectionLost:(ConnectionLostCallback)onConnectionLost
            onConnectionRestored:(ConnectionRestoredCallback _Nullable)onConnectionRestored;

/**
 * 연결 모니터링 시작
 */
- (void)startChecking;

/**
 * 연결 모니터링 중지
 */
- (void)stopChecking;

/**
 * 현재 연결 상태 반환
 */
- (BOOL)isConnected;

@end
