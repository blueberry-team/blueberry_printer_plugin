//
//  SingleOrderDirectPrinter.m
//  blueberry_printer
//
//  단일 주문 영수증을 텍스트 파싱 없이 직접 출력하는 클래스
//

#import "SingleOrderDirectPrinter.h"
#import "PrintConstants.h"
#import "PrinterCommands.h"
#import "KoreanTextRenderer.h"
#import "EscPosConstants.h"
#import "PrinterUtilities.h"

// 다국어 지원 헬퍼
@interface Localizer : NSObject
@property (nonatomic, strong) NSString* language;
- (instancetype)initWithLanguage:(NSString*)language;
- (NSString*)getText:(NSString*)key;
@end

@implementation SingleOrderDirectPrinter

+ (BOOL)printOrder:(NSDictionary*)orderData
         storeName:(NSString*)storeName
      storeAddress:(NSString*)storeAddress
       phoneNumber:(NSString*)phoneNumber
    businessNumber:(NSString*)businessNumber
   thankYouMessage:(NSString*)thankYouMessage
          language:(NSString*)language
          currency:(NSString*)currency
       tableNumber:(NSString*)tableNumber
    showStoreLabel:(BOOL)showStoreLabel
        printerSDK:(PrinterSDK*)printerSDK
             error:(NSError**)error {

    @try {
        // 다국어 텍스트 가져오기
        Localizer* localizer = [[Localizer alloc] initWithLanguage:language];

        // 주문 기본 정보 추출
        NSString* orderNumber = orderData[@"orderNumber"];
        if (!orderNumber) {
            orderNumber = [localizer getText:@"no_order_number"];
        }

        NSString* tableName = orderData[@"tableName"];
        if (!tableName) {
            tableName = [localizer getText:@"no_table_info"];
        }

        // 총 금액 계산
        double calculatedTotalPrice = 0.0;
        NSArray* orderVersions = orderData[@"orderVersion"];
        if (!orderVersions) {
            orderVersions = @[];
        }

        for (NSDictionary* version in orderVersions) {
            NSArray* orderItems = version[@"orderItems"];
            if (!orderItems) continue;

            for (NSDictionary* item in orderItems) {
                NSNumber* priceNum = item[@"price"];
                double itemPrice = [priceNum doubleValue];
                NSInteger itemQuantity = [item[@"quantity"] integerValue];
                calculatedTotalPrice += (itemPrice * itemQuantity);

                // 옵션 가격 추가
                NSArray* options = item[@"options"];
                if (options) {
                    for (NSDictionary* option in options) {
                        NSArray* selectedItems = option[@"selectedItems"];
                        if (selectedItems) {
                            for (NSDictionary* selectedItem in selectedItems) {
                                NSNumber* optionPriceNum = selectedItem[@"itemPrice"];
                                double optionPrice = [optionPriceNum doubleValue];
                                NSInteger optionQuantity = [selectedItem[@"quantity"] integerValue];
                                calculatedTotalPrice += (optionPrice * optionQuantity);
                            }
                        }
                    }
                }
            }
        }

        NSLog(@"📊 계산된 총 금액: %.2f", calculatedTotalPrice);

        // 점포용 라벨 출력 (요청 시에만)
        if (showStoreLabel) {
            [self printStoreLabel:printerSDK localizer:localizer];
        }

        // 타이틀 출력 (매장명)
        [self printTitle:printerSDK storeName:storeName];

        // 매장정보 출력
        [self printStoreInfo:printerSDK
                storeAddress:storeAddress
                 phoneNumber:phoneNumber
              businessNumber:businessNumber
                   localizer:localizer];

        // 구분선 출력
        [self printSeparator:printerSDK];

        // 주문 정보 출력
        [self printOrderInfo:printerSDK
                 orderNumber:orderNumber
                   tableName:tableName
                   localizer:localizer];

        // 상품 목록 출력
        [self printMenuList:printerSDK
              orderVersions:orderVersions
                   currency:currency
                  localizer:localizer];

        // 줄바꿈
        [self feedPaper:printerSDK lines:[PrintConstants lineFeedBeforeTotal]];

        // 합계 출력
        [self printTotal:printerSDK
              totalPrice:calculatedTotalPrice
                currency:currency
               localizer:localizer];

        // 줄바꿈
        [self feedPaper:printerSDK lines:[PrintConstants lineFeedAfterTotal]];

        // 감사 메시지 출력
        [self printThankYouMessage:printerSDK
                   thankYouMessage:thankYouMessage
                         localizer:localizer];

        // 줄바꿈
        [self feedPaper:printerSDK lines:[PrintConstants lineFeedAfterThankYou]];

        // 영수증 자르기
        [self cutPaper:printerSDK];

        NSLog(@"✅ 단일 주문 영수증 출력 완료");
        return YES;

    } @catch (NSException* exception) {
        NSLog(@"❌ 단일 주문 영수증 출력 실패: %@", exception.reason);
        if (error) {
            *error = [NSError errorWithDomain:@"SingleOrderDirectPrinter"
                                         code:2001
                                     userInfo:@{NSLocalizedDescriptionKey: exception.reason ?: @"출력 실패"}];
        }
        return NO;
    }
}

#pragma mark - Private Methods

+ (void)printStoreLabel:(PrinterSDK*)printerSDK localizer:(Localizer*)localizer {
    UIImage* image = [KoreanTextRenderer createTextImage:[localizer getText:@"store_label"]
                                                textSize:[PrintConstants storeLabelFontSize]
                                                  isBold:[PrintConstants storeLabelIsBold]
                                                   align:TextAlignCenter];
    NSData* bitmap = [KoreanTextRenderer convertToBitmap:image];
    NSString* hexString = [PrinterUtilities dataToHexString:bitmap];
    [printerSDK sendHex:hexString];

    [self feedPaper:printerSDK lines:[PrintConstants lineFeedAfterLabel]];
}

+ (void)printTitle:(PrinterSDK*)printerSDK storeName:(NSString*)storeName {
    UIImage* image = [KoreanTextRenderer createTextImage:storeName
                                                textSize:[PrintConstants titleFontSize]
                                                  isBold:YES
                                                   align:TextAlignCenter];
    NSData* bitmap = [KoreanTextRenderer convertToBitmap:image];
    NSString* hexString = [PrinterUtilities dataToHexString:bitmap];
    [printerSDK sendHex:hexString];

    [self feedPaper:printerSDK lines:[PrintConstants lineFeedAfterTitle]];
}

+ (void)printStoreInfo:(PrinterSDK*)printerSDK
          storeAddress:(NSString*)storeAddress
           phoneNumber:(NSString*)phoneNumber
        businessNumber:(NSString*)businessNumber
             localizer:(Localizer*)localizer {

    if (!storeAddress && !phoneNumber && !businessNumber) {
        return;
    }

    NSMutableString* sb = [NSMutableString string];

    if (storeAddress) {
        [sb appendFormat:@"%@\n", storeAddress];
    }
    if (phoneNumber) {
        [sb appendFormat:@"%@: %@\n", [localizer getText:@"phone"], phoneNumber];
    }
    if (businessNumber) {
        [sb appendFormat:@"%@: %@\n", [localizer getText:@"business_number"], businessNumber];
    }

    NSString* trimmedText = [sb stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    UIImage* image = [KoreanTextRenderer createTextImage:trimmedText
                                                textSize:[PrintConstants storeInfoFontSize]
                                                  isBold:NO
                                                   align:TextAlignCenter];
    NSData* bitmap = [KoreanTextRenderer convertToBitmap:image];
    NSString* hexString = [PrinterUtilities dataToHexString:bitmap];
    [printerSDK sendHex:hexString];

    [self feedPaper:printerSDK lines:[PrintConstants lineFeedAfterStoreInfo]];
}

+ (void)printSeparator:(PrinterSDK*)printerSDK {
    UIImage* image = [KoreanTextRenderer createTextImage:[PrintConstants separatorLine]
                                                textSize:[PrintConstants separatorFontSize]
                                                  isBold:NO
                                                   align:TextAlignCenter];
    NSData* bitmap = [KoreanTextRenderer convertToBitmap:image];
    NSString* hexString = [PrinterUtilities dataToHexString:bitmap];
    [printerSDK sendHex:hexString];

    [self feedPaper:printerSDK lines:[PrintConstants lineFeedAfterSeparator]];
}

+ (void)printOrderInfo:(PrinterSDK*)printerSDK
           orderNumber:(NSString*)orderNumber
             tableName:(NSString*)tableName
             localizer:(Localizer*)localizer {

    NSString* orderInfoText = [NSString stringWithFormat:@"%@: %@\n%@: %@",
                               [localizer getText:@"order_number"], orderNumber,
                               [localizer getText:@"table"], tableName];

    UIImage* image = [KoreanTextRenderer createTextImage:orderInfoText
                                                textSize:[PrintConstants orderInfoFontSize]
                                                  isBold:NO
                                                   align:TextAlignCenter];
    NSData* bitmap = [KoreanTextRenderer convertToBitmap:image];
    NSString* hexString = [PrinterUtilities dataToHexString:bitmap];
    [printerSDK sendHex:hexString];

    [self feedPaper:printerSDK lines:[PrintConstants lineFeedAfterOrderInfo]];
}

+ (void)printMenuList:(PrinterSDK*)printerSDK
        orderVersions:(NSArray*)orderVersions
             currency:(NSString*)currency
            localizer:(Localizer*)localizer {

    NSMutableString* sb = [NSMutableString string];
    NSString* currencySymbol = [self getCurrencySymbol:currency];

    for (NSDictionary* version in orderVersions) {
        NSArray* orderItems = version[@"orderItems"];
        if (!orderItems) continue;

        for (NSDictionary* item in orderItems) {
            NSString* menuName = item[@"menuName"] ?: @"상품명 없음";
            NSInteger quantity = [item[@"quantity"] integerValue];
            NSNumber* basePriceNum = item[@"price"];
            double basePrice = [basePriceNum doubleValue];

            // 메뉴 기본 가격만 표시 (옵션 가격 제외)
            double menuTotalPrice = basePrice * quantity;
            [sb appendFormat:@"%@ x%ld = %@%@\n",
             menuName,
             (long)quantity,
             [self formatPrice:menuTotalPrice currency:currency],
             currencySymbol];

            // 옵션 상세 표시 (가격 포함)
            NSArray* options = item[@"options"];
            if (options) {
                for (NSDictionary* option in options) {
                    NSArray* selectedItems = option[@"selectedItems"];
                    if (selectedItems) {
                        for (NSDictionary* selectedItem in selectedItems) {
                            NSString* itemName = selectedItem[@"itemName"] ?: @"옵션명 없음";
                            NSNumber* itemPriceNum = selectedItem[@"itemPrice"];
                            double itemPrice = [itemPriceNum doubleValue];
                            NSInteger itemQuantity = [selectedItem[@"quantity"] integerValue];

                            // 옵션 총 가격 계산
                            double optionTotalPrice = itemPrice * itemQuantity;

                            // 옵션 이름과 가격 표시
                            if (itemQuantity > 1) {
                                [sb appendFormat:@"  - %@ x%ld = %@%@\n",
                                 itemName,
                                 (long)itemQuantity,
                                 [self formatPrice:optionTotalPrice currency:currency],
                                 currencySymbol];
                            } else {
                                [sb appendFormat:@"  - %@ = %@%@\n",
                                 itemName,
                                 [self formatPrice:optionTotalPrice currency:currency],
                                 currencySymbol];
                            }
                        }
                    }
                }
            }
        }
    }

    NSString* trimmedText = [sb stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    UIImage* image = [KoreanTextRenderer createTextImage:trimmedText
                                                textSize:[PrintConstants menuListFontSize]
                                                  isBold:NO
                                                   align:TextAlignLeft];
    NSData* bitmap = [KoreanTextRenderer convertToBitmap:image];
    NSString* hexString = [PrinterUtilities dataToHexString:bitmap];
    [printerSDK sendHex:hexString];
}

+ (void)printTotal:(PrinterSDK*)printerSDK
        totalPrice:(double)totalPrice
          currency:(NSString*)currency
         localizer:(Localizer*)localizer {

    NSString* currencySymbol = [self getCurrencySymbol:currency];
    NSString* totalText = [NSString stringWithFormat:@"%@: %@%@",
                           [localizer getText:@"total"],
                           [self formatPrice:totalPrice currency:currency],
                           currencySymbol];

    UIImage* image = [KoreanTextRenderer createTextImage:totalText
                                                textSize:[PrintConstants totalFontSize]
                                                  isBold:YES
                                                   align:TextAlignRight];
    NSData* bitmap = [KoreanTextRenderer convertToBitmap:image];
    NSString* hexString = [PrinterUtilities dataToHexString:bitmap];
    [printerSDK sendHex:hexString];
}

+ (void)printThankYouMessage:(PrinterSDK*)printerSDK
             thankYouMessage:(NSString*)thankYouMessage
                   localizer:(Localizer*)localizer {

    NSString* message = thankYouMessage ?: [localizer getText:@"thank_you_default"];

    UIImage* image = [KoreanTextRenderer createTextImage:message
                                                textSize:[PrintConstants thankYouFontSize]
                                                  isBold:NO
                                                   align:TextAlignCenter];
    NSData* bitmap = [KoreanTextRenderer convertToBitmap:image];
    NSString* hexString = [PrinterUtilities dataToHexString:bitmap];
    [printerSDK sendHex:hexString];
}

+ (void)feedPaper:(PrinterSDK*)printerSDK lines:(NSInteger)lines {
    if (!printerSDK || lines <= 0) return;

    // ESC/POS 명령어로 용지 피드 (최대 255 dot씩)
    while (lines > 0) {
        NSInteger feedAmount = MIN(lines, 255);
        NSData* feedCommand = [PrinterCommands POS_Set_PrtAndFeedPaper:feedAmount];
        NSString* hexString = [PrinterUtilities dataToHexString:feedCommand];
        [printerSDK sendHex:hexString];
        lines -= feedAmount;
    }
}

+ (void)cutPaper:(PrinterSDK*)printerSDK {
    if (!printerSDK) return;

    // 용지 자르기 전에 충분한 공간 확보
    [self feedPaper:printerSDK lines:[PrintConstants lineFeedBeforeCut]];

    // ESC/POS 커팅 명령어 전송
    NSData* cutCommand = [EscPosConstants GS_V_n];
    NSString* hexString = [PrinterUtilities dataToHexString:cutCommand];
    [printerSDK sendHex:hexString];
}

#pragma mark - Helper Methods

/**
 * 가격 포맷팅 (천단위 콤마, 통화별 소수점 처리)
 * USD, EUR: 소수점 2자리
 * KRW, JPY: 정수
 */
+ (NSString*)formatPrice:(double)price currency:(NSString*)currency {
    NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    formatter.groupingSeparator = @",";

    if ([currency isEqualToString:@"USD"] || [currency isEqualToString:@"EUR"]) {
        formatter.minimumFractionDigits = 2;
        formatter.maximumFractionDigits = 2;
        return [formatter stringFromNumber:@(price)] ?: @"0.00";
    } else {
        // KRW, JPY는 정수
        formatter.minimumFractionDigits = 0;
        formatter.maximumFractionDigits = 0;
        return [formatter stringFromNumber:@(price)] ?: @"0";
    }
}

/**
 * 화폐 단위 심볼 가져오기
 */
+ (NSString*)getCurrencySymbol:(NSString*)currency {
    if ([currency isEqualToString:@"USD"]) {
        return @"$";
    } else if ([currency isEqualToString:@"JPY"]) {
        return @"¥";
    } else if ([currency isEqualToString:@"EUR"]) {
        return @"€";
    } else {
        return @"원"; // KRW 기본값
    }
}

@end

#pragma mark - Localizer Implementation

@implementation Localizer

- (instancetype)initWithLanguage:(NSString*)language {
    self = [super init];
    if (self) {
        _language = language ?: @"kor";
    }
    return self;
}

- (NSString*)getText:(NSString*)key {
    if ([self.language isEqualToString:@"eng"]) {
        return [self getEnglishText:key];
    } else if ([self.language isEqualToString:@"jpn"]) {
        return [self getJapaneseText:key];
    } else {
        return [self getKoreanText:key];
    }
}

- (NSString*)getEnglishText:(NSString*)key {
    NSDictionary* texts = @{
        @"store_info": @"Store Information",
        @"order_info": @"Order Information",
        @"order_number": @"Order No",
        @"table": @"Table",
        @"menu_list": @"Menu List",
        @"subtotal": @"Subtotal",
        @"tax": @"Tax",
        @"total": @"Total",
        @"thank_you_default": @"Thank you!\nPlease visit us again.",
        @"phone": @"Phone",
        @"business_number": @"Business No",
        @"no_order_number": @"No order number",
        @"no_table_info": @"No table info",
        @"store_label": @"┌────────────────────┐\n│     Store Copy     │\n└────────────────────┘"
    };
    return texts[key] ?: key;
}

- (NSString*)getJapaneseText:(NSString*)key {
    NSDictionary* texts = @{
        @"store_info": @"店舗情報",
        @"order_info": @"注文情報",
        @"order_number": @"注文番号",
        @"table": @"テーブル",
        @"menu_list": @"メニューリスト",
        @"subtotal": @"小計",
        @"tax": @"税金",
        @"total": @"合計",
        @"thank_you_default": @"ありがとうございます！\nまたお越しください。",
        @"phone": @"電話",
        @"business_number": @"事業者番号",
        @"no_order_number": @"注文番号なし",
        @"no_table_info": @"テーブル情報なし",
        @"store_label": @"┌────────────────────┐\n│      店舗用控え      │\n└────────────────────┘"
    };
    return texts[key] ?: key;
}

- (NSString*)getKoreanText:(NSString*)key {
    NSDictionary* texts = @{
        @"store_info": @"매장정보",
        @"order_info": @"주문정보",
        @"order_number": @"주문번호",
        @"table": @"테이블",
        @"menu_list": @"상품목록",
        @"subtotal": @"소계",
        @"tax": @"부가세",
        @"total": @"합계",
        @"thank_you_default": @"감사합니다!\n다음에 또 방문해 주세요.",
        @"phone": @"전화",
        @"business_number": @"사업자등록번호",
        @"no_order_number": @"주문번호 없음",
        @"no_table_info": @"테이블 정보 없음",
        @"store_label": @"┌────────────────────┐\n│        점포용        │\n└────────────────────┘"
    };
    return texts[key] ?: key;
}

@end
