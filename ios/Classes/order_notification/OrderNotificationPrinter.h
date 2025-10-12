//
//  OrderNotificationPrinter.h
//  blueberry_printer
//
//  소켓으로 받은 주문 알림을 출력하는 클래스
//

#import <Foundation/Foundation.h>
#import "PrinterSDK.h"

NS_ASSUME_NONNULL_BEGIN

@interface OrderNotificationPrinter : NSObject

/**
 * 주문 알림 데이터를 출력
 * @param orderData 주문 알림 데이터
 * @param language 언어 (기본값: "kor")
 * @param currency 화폐 단위 (기본값: "KRW")
 * @param printerSDK 프린터 SDK 인스턴스
 * @param error 에러 정보
 * @return 출력 성공 여부
 */
+ (BOOL)printNotification:(NSDictionary*)orderData
                 language:(NSString*)language
                 currency:(NSString*)currency
               printerSDK:(PrinterSDK*)printerSDK
                    error:(NSError**)error;

@end

NS_ASSUME_NONNULL_END
