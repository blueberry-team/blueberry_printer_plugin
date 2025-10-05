//
//  SingleOrderDirectPrinter.h
//  blueberry_printer
//
//  단일 주문 영수증을 텍스트 파싱 없이 직접 출력하는 클래스
//

#import <Foundation/Foundation.h>
#import "PrinterSDK.h"

@interface SingleOrderDirectPrinter : NSObject

/**
 * 단일 주문 데이터를 직접 출력 (텍스트 파싱 방식 없이)
 * @param orderData 주문 데이터 (NSDictionary)
 * @param storeName 매장명
 * @param storeAddress 매장 주소 (선택사항)
 * @param phoneNumber 전화번호 (선택사항)
 * @param businessNumber 사업자등록번호 (선택사항)
 * @param thankYouMessage 감사 메시지 (선택사항)
 * @param language 언어 (기본값: "kor")
 * @param currency 화폐 단위 (기본값: "KRW")
 * @param tableNumber 테이블 번호 (선택사항)
 * @param showStoreLabel 점포용 라벨 표시 여부 (기본값: YES)
 * @param printerSDK PrinterSDK 인스턴스
 * @param error 에러 정보 (실패 시)
 * @return 성공 여부
 */
+ (BOOL)printOrder:(NSDictionary*)orderData
         storeName:(NSString*)storeName
      storeAddress:(NSString* _Nullable)storeAddress
       phoneNumber:(NSString* _Nullable)phoneNumber
    businessNumber:(NSString* _Nullable)businessNumber
   thankYouMessage:(NSString* _Nullable)thankYouMessage
          language:(NSString*)language
          currency:(NSString*)currency
       tableNumber:(NSString* _Nullable)tableNumber
    showStoreLabel:(BOOL)showStoreLabel
        printerSDK:(PrinterSDK*)printerSDK
             error:(NSError**)error;

@end
