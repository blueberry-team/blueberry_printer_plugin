//
//  PrintConstants.m
//  blueberry_printer
//
//  프린트 관련 상수 정의
//

#import "PrintConstants.h"

@implementation PrintConstants

// MARK: - 폰트 크기
+ (CGFloat)storeLabelFontSize { return 24.0f; }
+ (CGFloat)titleFontSize { return 60.0f; }
+ (CGFloat)storeInfoFontSize { return 20.0f; }
+ (CGFloat)separatorFontSize { return 20.0f; }
+ (CGFloat)orderInfoFontSize { return 20.0f; }
+ (CGFloat)menuListFontSize { return 20.0f; }
+ (CGFloat)totalFontSize { return 20.0f; }
+ (CGFloat)thankYouFontSize { return 20.0f; }
+ (CGFloat)textDefaultFontSize { return 20.0f; }

// MARK: - 줄바꿈 설정
+ (NSInteger)lineFeedAfterLabel { return 1; }
+ (NSInteger)lineFeedAfterTitle { return 1; }
+ (NSInteger)lineFeedAfterStoreInfo { return 1; }
+ (NSInteger)lineFeedAfterSeparator { return 1; }
+ (NSInteger)lineFeedAfterOrderInfo { return 1; }
+ (NSInteger)lineFeedBeforeTotal { return 2; }
+ (NSInteger)lineFeedAfterTotal { return 2; }
+ (NSInteger)lineFeedBeforeThankYou { return 2; }
+ (NSInteger)lineFeedAfterThankYou { return 3; }
+ (NSInteger)lineFeedBeforeCut { return 200; }

// MARK: - 점포용 라벨 설정
+ (NSString*)storeLabelText {
    return @"┌────────────────────┐\n│        점포용        │\n└────────────────────┘";
}

+ (BOOL)storeLabelIsBold {
    return YES;
}

// MARK: - 구분선
+ (NSString*)separatorLine {
    return @"================================";
}

// MARK: - 기본 UUID
+ (NSString*)defaultPrinterUUID {
    return @"00001101-0000-1000-8000-00805F9B34FB";
}

@end
