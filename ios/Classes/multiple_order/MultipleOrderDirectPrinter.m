//
//  MultipleOrderDirectPrinter.m
//  blueberry_printer
//
//  전체 주문(누적) 영수증을 텍스트 파싱 없이 직접 출력하는 클래스
//

#import "MultipleOrderDirectPrinter.h"
#import "PrintConstants.h"
#import "PrinterCommands.h"
#import "KoreanTextRenderer.h"
#import "EscPosConstants.h"
#import "PrinterUtilities.h"

// 다국어 지원 헬퍼 (SingleOrderDirectPrinter와 동일)
@interface LocalizerMultiple : NSObject
@property (nonatomic, strong) NSString* language;
- (instancetype)initWithLanguage:(NSString*)language;
- (NSString*)getText:(NSString*)key;
@end

@implementation MultipleOrderDirectPrinter

+ (BOOL)printOrder:(NSDictionary*)orderData
         storeName:(NSString*)storeName
      storeAddress:(NSString*)storeAddress
       phoneNumber:(NSString*)phoneNumber
    businessNumber:(NSString*)businessNumber
   thankYouMessage:(NSString*)thankYouMessage
          language:(NSString*)language
          currency:(NSString*)currency
       tableNumber:(NSString*)tableNumber
        printerSDK:(PrinterSDK*)printerSDK
             error:(NSError**)error {

    @try {
        // 다국어 텍스트 가져오기
        LocalizerMultiple* localizer = [[LocalizerMultiple alloc] initWithLanguage:language];

        // API 응답에서 제공하는 총 금액 사용
        NSNumber* totalPriceNum = orderData[@"totalPrice"];
        double grandTotalPrice = [totalPriceNum doubleValue];
        NSLog(@"📊 응답에서 제공된 총 가격: %.2f", grandTotalPrice);

        // orderVersion이 없고 orderMenus가 있는 경우 (Flutter 모델 구조)
        NSArray* orderVersions = orderData[@"orderVersion"];
        if (!orderVersions && orderData[@"orderMenus"]) {
            NSLog(@"📱 Flutter 모델 구조 감지: orderMenus 필드 처리 중");
            NSArray* orderMenus = orderData[@"orderMenus"];

            // orderMenus를 orderItems로 변환하여 orderVersion 생성
            orderVersions = @[@{@"orderItems": orderMenus}];
        } else if (!orderVersions) {
            orderVersions = @[];
        }

        NSLog(@"📦 누적 주문 처리 시작 - 버전 수: %lu", (unsigned long)orderVersions.count);

        // 날짜/시간 출력 (현재 시간)
        [self printDateTime:printerSDK language:language];

        // 테이블 번호 출력 (박스로 강조) - 파라미터로 받은 값 사용
        if (tableNumber) {
            [self printTableNumber:printerSDK tableNumber:tableNumber localizer:localizer];
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

        // 누적 상품 목록 출력
        [self printMergedMenuList:printerSDK
                    orderVersions:orderVersions
                         currency:currency
                        localizer:localizer];

        // 줄바꿈
        [self feedPaper:printerSDK lines:[PrintConstants lineFeedBeforeTotal]];

        // 총 합계 출력
        [self printGrandTotal:printerSDK
                   totalPrice:grandTotalPrice
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

        NSLog(@"✅ 전체 주문 영수증 출력 완료");
        return YES;

    } @catch (NSException* exception) {
        NSLog(@"❌ 전체 주문 영수증 출력 실패: %@", exception.reason);
        if (error) {
            *error = [NSError errorWithDomain:@"MultipleOrderDirectPrinter"
                                         code:3001
                                     userInfo:@{NSLocalizedDescriptionKey: exception.reason ?: @"출력 실패"}];
        }
        return NO;
    }
}

#pragma mark - Private Methods

/**
 * 날짜/시간 출력 (현재 시간, 다국어)
 */
+ (void)printDateTime:(PrinterSDK*)printerSDK language:(NSString*)language {
    NSDate* currentDate = [NSDate date];
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];

    if ([language isEqualToString:@"eng"]) {
        [dateFormatter setDateFormat:@"MMM d (E) HH:mm"];
        [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
    } else if ([language isEqualToString:@"jpn"]) {
        [dateFormatter setDateFormat:@"M月d日 (E) HH:mm"];
        [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"ja_JP"]];
    } else {
        // "kor" 기본값
        [dateFormatter setDateFormat:@"M월 d일 (E) HH:mm"];
        [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"ko_KR"]];
    }

    NSString* formattedDate = [dateFormatter stringFromDate:currentDate];

    UIImage* image = [KoreanTextRenderer createTextImage:formattedDate
                                                textSize:24.0f // 소켓과 동일한 크기
                                                  isBold:NO
                                                   align:TextAlignLeft];
    NSData* bitmap = [KoreanTextRenderer convertToBitmap:image];
    NSString* hexString = [PrinterUtilities dataToHexString:bitmap];
    [printerSDK sendHex:hexString];

    [self feedPaper:printerSDK lines:2];
}

/**
 * 테이블 번호 출력 (박스로 강조, 다국어)
 */
+ (void)printTableNumber:(PrinterSDK*)printerSDK tableNumber:(NSString*)tableNumber localizer:(LocalizerMultiple*)localizer {
    // 박스 윗부분
    NSString* boxTop = @"┌──────────────┐";
    UIImage* boxTopImage = [KoreanTextRenderer createTextImage:boxTop
                                                      textSize:32.0f
                                                        isBold:NO
                                                         align:TextAlignCenter];
    NSData* boxTopBitmap = [KoreanTextRenderer convertToBitmap:boxTopImage];
    [printerSDK sendHex:[PrinterUtilities dataToHexString:boxTopBitmap]];
    [self feedPaper:printerSDK lines:1];

    // 테이블 번호 (박스 중간) - 다국어 지원
    NSString* tableText = [NSString stringWithFormat:@"│  %@ %@  │", [localizer getText:@"table"], tableNumber];
    UIImage* tableImage = [KoreanTextRenderer createTextImage:tableText
                                                     textSize:42.0f // 소켓 메뉴 크기와 동일
                                                       isBold:YES
                                                        align:TextAlignCenter];
    NSData* tableBitmap = [KoreanTextRenderer convertToBitmap:tableImage];
    [printerSDK sendHex:[PrinterUtilities dataToHexString:tableBitmap]];
    [self feedPaper:printerSDK lines:1];

    // 박스 아랫부분
    NSString* boxBottom = @"└──────────────┘";
    UIImage* boxBottomImage = [KoreanTextRenderer createTextImage:boxBottom
                                                         textSize:32.0f
                                                           isBold:NO
                                                            align:TextAlignCenter];
    NSData* boxBottomBitmap = [KoreanTextRenderer convertToBitmap:boxBottomImage];
    [printerSDK sendHex:[PrinterUtilities dataToHexString:boxBottomBitmap]];

    [self feedPaper:printerSDK lines:2];
}

+ (void)printTitle:(PrinterSDK*)printerSDK storeName:(NSString*)storeName {
    UIImage* image = [KoreanTextRenderer createTextImage:storeName
                                                textSize:42.0f // Android와 동일 (소켓 메뉴 크기)
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
             localizer:(LocalizerMultiple*)localizer {

    // Android와 동일하게 주소만 출력
    if (storeAddress) {
        UIImage* image = [KoreanTextRenderer createTextImage:storeAddress
                                                    textSize:28.0f // Android와 동일 (소켓 옵션 크기)
                                                      isBold:NO
                                                       align:TextAlignCenter];
        NSData* bitmap = [KoreanTextRenderer convertToBitmap:image];
        NSString* hexString = [PrinterUtilities dataToHexString:bitmap];
        [printerSDK sendHex:hexString];

        [self feedPaper:printerSDK lines:[PrintConstants lineFeedAfterStoreInfo]];
    }
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
             localizer:(LocalizerMultiple*)localizer {

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

/**
 * 누적 상품 목록 출력 (모든 버전 합치기)
 */
+ (void)printMergedMenuList:(PrinterSDK*)printerSDK
              orderVersions:(NSArray*)orderVersions
                   currency:(NSString*)currency
                  localizer:(LocalizerMultiple*)localizer {

    NSMutableString* sb = [NSMutableString string];
    NSString* currencySymbol = [self getCurrencySymbol:currency];

    // 모든 버전의 상품을 합치기 위한 Dictionary (메뉴명 + 옵션 조합을 기준으로)
    NSMutableDictionary* mergedItems = [NSMutableDictionary dictionary];

    // 모든 버전의 상품 수집
    for (NSDictionary* version in orderVersions) {
        NSArray* orderItems = version[@"orderItems"];
        if (!orderItems) continue;

        for (NSDictionary* item in orderItems) {
            NSString* menuName = item[@"menuName"] ?: @"상품명 없음";
            NSInteger quantity = [item[@"quantity"] integerValue];
            NSNumber* basePriceNum = item[@"price"];
            double basePrice = [basePriceNum doubleValue];

            // 옵션 정보를 포함한 고유 키 생성
            // Flutter 모델에서는 menuOptionItems 필드를 사용하고 네이티브에서는 options 필드를 사용함
            NSArray* options = item[@"options"] ?: item[@"menuOptionItems"] ?: @[];

            NSLog(@"옵션 처리: 메뉴=%@, 옵션 개수=%lu", menuName, (unsigned long)options.count);

            NSMutableString* optionKey = [NSMutableString string];
            double optionTotalPrice = 0.0;

            for (NSDictionary* option in options) {
                NSArray* selectedItems = option[@"selectedItems"];
                if (!selectedItems) continue;

                for (NSDictionary* selectedItem in selectedItems) {
                    // Flutter 모델과 네이티브 코드 필드명 차이 처리
                    NSString* optionName = selectedItem[@"itemName"]
                                        ?: selectedItem[@"menuOptionItemDetailName"]
                                        ?: @"";

                    NSNumber* optionPriceNum = selectedItem[@"itemPrice"]
                                            ?: selectedItem[@"menuOptionItemDetailPrice"];
                    double optionPrice = [optionPriceNum doubleValue];

                    NSNumber* optionQuantityNum = selectedItem[@"quantity"]
                                               ?: selectedItem[@"menuOptionItemDetailQuantity"];
                    NSInteger optionQuantity = [optionQuantityNum integerValue];

                    NSLog(@"옵션 값 처리: 메뉴=%@, 옵션=%@, 가격=%.2f, 수량=%ld",
                          menuName, optionName, optionPrice, (long)optionQuantity);

                    if (optionPrice > 0) {
                        [optionKey appendFormat:@"|%@:%ld", optionName, (long)optionQuantity];
                        optionTotalPrice += (optionPrice * optionQuantity);
                    }
                }
            }

            // 메뉴명 + 옵션 조합을 기준으로 한 고유 키
            NSString* uniqueKey = [NSString stringWithFormat:@"%@%@", menuName, optionKey];

            // API에서 제공하는 가격 사용
            double totalItemPrice = basePrice;
            NSLog(@"[메뉴: %@] 가격: %.2f", menuName, totalItemPrice);

            // 메뉴 아이템 합치기 (동일한 메뉴 + 옵션 조합인 경우에만)
            NSMutableDictionary* existingItem = mergedItems[uniqueKey];
            if (existingItem) {
                NSInteger existingQuantity = [existingItem[@"quantity"] integerValue];
                double existingTotalPrice = [existingItem[@"totalPrice"] doubleValue];

                existingItem[@"quantity"] = @(existingQuantity + quantity);
                existingItem[@"totalPrice"] = @(existingTotalPrice + totalItemPrice);
            } else {
                mergedItems[uniqueKey] = [@{
                    @"menuName": menuName,
                    @"quantity": @(quantity),
                    @"basePrice": @(basePrice),
                    @"totalPrice": @(totalItemPrice),
                    @"options": options
                } mutableCopy];
            }
        }
    }

    // 다국어 옵션 prefix 가져오기
    NSString* optionPrefix = [localizer getText:@"option"];

    // 합쳐진 상품 출력 (Android와 동일하게 메뉴와 옵션을 분리해서 다른 크기로 출력)
    for (NSString* uniqueKey in mergedItems) {
        NSDictionary* itemData = mergedItems[uniqueKey];
        NSString* menuName = itemData[@"menuName"];
        NSInteger quantity = [itemData[@"quantity"] integerValue];
        double totalPrice = [itemData[@"totalPrice"] doubleValue];
        NSArray* options = itemData[@"options"];

        // 메뉴 라인 출력 (32f)
        NSString* menuLine = [NSString stringWithFormat:@"%@ x%ld = %@%@",
                             menuName,
                             (long)quantity,
                             [self formatPrice:totalPrice currency:currency],
                             currencySymbol];

        UIImage* menuImage = [KoreanTextRenderer createTextImage:menuLine
                                                        textSize:32.0f // Android와 동일 (메뉴 크기)
                                                          isBold:NO
                                                           align:TextAlignLeft];
        [printerSDK sendHex:[PrinterUtilities dataToHexString:[KoreanTextRenderer convertToBitmap:menuImage]]];

        // 옵션 라인 수집
        NSMutableString* optionLines = [NSMutableString string];
        for (NSDictionary* option in options) {
            NSArray* selectedItems = option[@"selectedItems"];
            if (!selectedItems) continue;

            for (NSDictionary* selectedItem in selectedItems) {
                // Flutter 모델과 네이티브 코드 필드명 차이 처리
                NSString* optionName = selectedItem[@"itemName"]
                                    ?: selectedItem[@"menuOptionItemDetailName"]
                                    ?: @"옵션명 없음";

                NSNumber* optionQuantityNum = selectedItem[@"quantity"]
                                           ?: selectedItem[@"menuOptionItemDetailQuantity"];
                NSInteger optionQuantity = [optionQuantityNum integerValue];

                // 옵션 이름만 표시 (가격 제거, Android와 동일)
                if (optionQuantity > 1) {
                    [optionLines appendFormat:@"  %@ %@ x%ld\n", optionPrefix, optionName, (long)optionQuantity];
                } else {
                    [optionLines appendFormat:@"  %@ %@\n", optionPrefix, optionName];
                }
            }
        }

        // 옵션 라인 출력 (24f)
        if (optionLines.length > 0) {
            NSString* trimmedOptions = [optionLines stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            UIImage* optionImage = [KoreanTextRenderer createTextImage:trimmedOptions
                                                            textSize:24.0f // Android와 동일 (옵션 크기)
                                                              isBold:NO
                                                               align:TextAlignLeft];
            [printerSDK sendHex:[PrinterUtilities dataToHexString:[KoreanTextRenderer convertToBitmap:optionImage]]];
        }
    }
}

+ (void)printGrandTotal:(PrinterSDK*)printerSDK
             totalPrice:(double)totalPrice
               currency:(NSString*)currency
              localizer:(LocalizerMultiple*)localizer {

    NSString* currencySymbol = [self getCurrencySymbol:currency];
    NSString* totalText = [NSString stringWithFormat:@"%@: %@%@",
                           [localizer getText:@"grand_total"],  // Android와 동일하게 "grand_total" 사용
                           [self formatPrice:totalPrice currency:currency],
                           currencySymbol];

    UIImage* image = [KoreanTextRenderer createTextImage:totalText
                                                textSize:42.0f // Android와 동일 (소켓 메뉴 크기)
                                                  isBold:YES
                                                   align:TextAlignRight];
    NSData* bitmap = [KoreanTextRenderer convertToBitmap:image];
    NSString* hexString = [PrinterUtilities dataToHexString:bitmap];
    [printerSDK sendHex:hexString];
}

+ (void)printThankYouMessage:(PrinterSDK*)printerSDK
             thankYouMessage:(NSString*)thankYouMessage
                   localizer:(LocalizerMultiple*)localizer {

    NSString* message = thankYouMessage ?: [localizer getText:@"thank_you_default"];

    UIImage* image = [KoreanTextRenderer createTextImage:message
                                                textSize:28.0f // Android와 동일 (소켓 옵션 크기)
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

+ (NSString*)formatPrice:(double)price currency:(NSString*)currency {
    NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    formatter.groupingSeparator = @",";

    if ([currency isEqualToString:@"USD"] || [currency isEqualToString:@"EUR"]) {
        formatter.minimumFractionDigits = 2;
        formatter.maximumFractionDigits = 2;
        return [formatter stringFromNumber:@(price)] ?: @"0.00";
    } else {
        formatter.minimumFractionDigits = 0;
        formatter.maximumFractionDigits = 0;
        return [formatter stringFromNumber:@(price)] ?: @"0";
    }
}

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

#pragma mark - LocalizerMultiple Implementation

@implementation LocalizerMultiple

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
        @"order_number": @"Order No",
        @"table": @"Table",
        @"total": @"Total",
        @"grand_total": @"Grand Total",
        @"option": @"Option/",
        @"thank_you_default": @"Thank you!\nPlease visit us again.",
        @"phone": @"Phone",
        @"business_number": @"Business No",
        @"no_order_number": @"No order number",
        @"no_table_info": @"No table info"
    };
    return texts[key] ?: key;
}

- (NSString*)getJapaneseText:(NSString*)key {
    NSDictionary* texts = @{
        @"order_number": @"注文番号",
        @"table": @"テーブル",
        @"total": @"合計",
        @"grand_total": @"総合計",
        @"option": @"オプション/",
        @"thank_you_default": @"ありがとうございます！\nまたお越しください。",
        @"phone": @"電話",
        @"business_number": @"事業者番号",
        @"no_order_number": @"注文番号なし",
        @"no_table_info": @"テーブル情報なし"
    };
    return texts[key] ?: key;
}

- (NSString*)getKoreanText:(NSString*)key {
    NSDictionary* texts = @{
        @"order_number": @"주문번호",
        @"table": @"테이블",
        @"total": @"합계",
        @"grand_total": @"총 합계",
        @"option": @"옵션/",
        @"thank_you_default": @"감사합니다!\n다음에 또 방문해 주세요.",
        @"phone": @"전화",
        @"business_number": @"사업자등록번호",
        @"no_order_number": @"주문번호 없음",
        @"no_table_info": @"테이블 정보 없음"
    };
    return texts[key] ?: key;
}

@end
