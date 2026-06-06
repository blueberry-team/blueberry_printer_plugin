//
//  PrinterDriver.h
//  blueberry_printer
//
//  프린터 드라이버 프로토콜
//  모든 프린터 드라이버가 구현해야 하는 공통 인터페이스
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 프린터 타입 열거형
 */
typedef NS_ENUM(NSInteger, PrinterType) {
    PrinterTypeESCPOS,          // ESC/POS 프린터
    PrinterTypeAuto             // 자동 감지
};

/**
 * 프린터 드라이버 프로토콜
 * 모든 프린터 드라이버가 이 프로토콜을 구현해야 함
 */
@protocol PrinterDriver <NSObject>

@required

/**
 * 프린터 타입 반환
 * @return 프린터 타입
 */
- (PrinterType)getType;

/**
 * 프린터 연결
 * @param address 블루투스 주소 또는 식별자
 * @return 연결 성공 여부
 */
- (BOOL)connectWithAddress:(NSString *)address error:(NSError **)error;

/**
 * 프린터 연결 해제
 * @return 연결 해제 성공 여부
 */
- (BOOL)disconnect;

/**
 * 프린터 연결 상태 확인
 * @return 연결 여부
 */
- (BOOL)isConnected;

/**
 * 단일 주문 영수증 출력
 */
- (BOOL)printSingleOrderWithData:(NSDictionary *)orderData
                       storeName:(NSString *)storeName
                     tableNumber:(nullable NSString *)tableNumber
                    storeAddress:(nullable NSString *)storeAddress
                     phoneNumber:(nullable NSString *)phoneNumber
                  businessNumber:(nullable NSString *)businessNumber
                thankYouMessage:(nullable NSString *)thankYouMessage
                        language:(NSString *)language
                        currency:(NSString *)currency
                  showStoreLabel:(BOOL)showStoreLabel
                           error:(NSError **)error;

/**
 * 전체 주문 영수증 출력 (누적)
 */
- (BOOL)printTotalOrderWithData:(NSDictionary *)orderData
                      storeName:(NSString *)storeName
                    tableNumber:(nullable NSString *)tableNumber
                   storeAddress:(nullable NSString *)storeAddress
                    phoneNumber:(nullable NSString *)phoneNumber
                 businessNumber:(nullable NSString *)businessNumber
               thankYouMessage:(nullable NSString *)thankYouMessage
                       language:(NSString *)language
                       currency:(NSString *)currency
                          error:(NSError **)error;

/**
 * 주문 알림 영수증 출력 (소켓)
 */
- (BOOL)printOrderFromSocketWithData:(NSDictionary *)orderData
                            language:(NSString *)language
                            currency:(NSString *)currency
                               error:(NSError **)error;

/**
 * 텍스트 출력
 */
- (BOOL)printTextWithText:(NSString *)text
                 fontSize:(CGFloat)fontSize
                   isBold:(BOOL)isBold
                    align:(NSString *)align
                    error:(NSError **)error;

/**
 * 연결 모니터링 시작
 */
- (void)startConnectionMonitoringWithCallback:(void (^)(NSString *status))callback;

/**
 * 연결 모니터링 중지
 */
- (void)stopConnectionMonitoring;

/**
 * 리소스 정리
 */
- (void)cleanup;

@end

NS_ASSUME_NONNULL_END
