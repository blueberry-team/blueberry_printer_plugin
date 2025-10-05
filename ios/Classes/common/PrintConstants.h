//
//  PrintConstants.h
//  blueberry_printer
//
//  프린트 관련 상수 정의
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@interface PrintConstants : NSObject

// MARK: - 폰트 크기
+ (CGFloat)storeLabelFontSize;      // 24.0 - 점포용 라벨
+ (CGFloat)titleFontSize;           // 60.0 - 타이틀 (매장명)
+ (CGFloat)storeInfoFontSize;       // 20.0 - 매장 정보
+ (CGFloat)separatorFontSize;       // 20.0 - 구분선
+ (CGFloat)orderInfoFontSize;       // 20.0 - 주문 정보
+ (CGFloat)menuListFontSize;        // 20.0 - 메뉴 목록
+ (CGFloat)totalFontSize;           // 20.0 - 합계
+ (CGFloat)thankYouFontSize;        // 20.0 - 감사 메시지
+ (CGFloat)textDefaultFontSize;     // 20.0 - 기본 텍스트

// MARK: - 줄바꿈 설정
+ (NSInteger)lineFeedAfterLabel;        // 1  - 점포용 라벨 후
+ (NSInteger)lineFeedAfterTitle;        // 1  - 타이틀 후
+ (NSInteger)lineFeedAfterStoreInfo;    // 1  - 매장정보 후
+ (NSInteger)lineFeedAfterSeparator;    // 1  - 구분선 후
+ (NSInteger)lineFeedAfterOrderInfo;    // 1  - 주문정보 후
+ (NSInteger)lineFeedBeforeTotal;       // 2  - 합계 전
+ (NSInteger)lineFeedAfterTotal;        // 2  - 합계 후
+ (NSInteger)lineFeedBeforeThankYou;    // 2  - 감사메시지 전
+ (NSInteger)lineFeedAfterThankYou;     // 3  - 감사메시지 후
+ (NSInteger)lineFeedBeforeCut;         // 200 - 영수증 자르기 전

// MARK: - 점포용 라벨 설정
+ (NSString*)storeLabelText;
+ (BOOL)storeLabelIsBold;

// MARK: - 구분선
+ (NSString*)separatorLine;

// MARK: - 기본 UUID (블루투스 프린터)
+ (NSString*)defaultPrinterUUID;

@end
