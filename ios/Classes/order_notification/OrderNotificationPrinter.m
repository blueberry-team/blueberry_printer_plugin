//
//  OrderNotificationPrinter.m
//  blueberry_printer
//
//  소켓으로 받은 주문 알림을 출력하는 클래스
//

#import "OrderNotificationPrinter.h"
#import "PrintConstants.h"
#import "PrinterCommands.h"
#import "KoreanTextRenderer.h"
#import "EscPosConstants.h"
#import "PrinterUtilities.h"

// 다국어 지원 헬퍼
@interface LocalizerNotification : NSObject
@property (nonatomic, strong) NSString* language;
- (instancetype)initWithLanguage:(NSString*)language;
- (NSString*)getText:(NSString*)key;
@end

@implementation OrderNotificationPrinter

+ (BOOL)printNotification:(NSDictionary*)orderData
                 language:(NSString*)language
                 currency:(NSString*)currency
               printerSDK:(PrinterSDK*)printerSDK
                    error:(NSError**)error {

    @try {
        // 다국어 텍스트 가져오기
        LocalizerNotification* localizer = [[LocalizerNotification alloc] initWithLanguage:language ?: @"kor"];

        // 주문 기본 정보 추출
        NSString* orderBy = orderData[@"orderBy"] ?: @"ADMIN";
        NSNumber* tableNumberNum = orderData[@"tableNumber"];
        NSInteger tableNumber = [tableNumberNum integerValue];
        NSString* orderAt = orderData[@"orderAt"] ?: @"";
        NSString* orderType = orderData[@"orderType"] ?: @"CREATE";
        NSArray* items = orderData[@"items"] ?: @[];

        // 날짜/시간 출력
        [self printDateTime:printerSDK orderAt:orderAt language:language];

        // 테이블 번호 출력 (박스로 강조)
        [self printTableNumber:printerSDK tableNumber:tableNumber localizer:localizer];

        // 주문 타입 출력 (주문 추가, 주문 변경 등)
        [self printOrderType:printerSDK orderType:orderType localizer:localizer];

        // 구분선 출력
        [self printSeparator:printerSDK];

        // 메뉴 아이템 목록 출력
        [self printMenuItems:printerSDK items:items localizer:localizer];

        // 영수증 자르기
        [self cutPaper:printerSDK];

        NSLog(@"✅ 주문 알림 출력 완료");
        return YES;

    } @catch (NSException* exception) {
        NSLog(@"❌ 주문 알림 출력 실패: %@", exception.reason);
        if (error) {
            *error = [NSError errorWithDomain:@"OrderNotificationPrinter"
                                         code:4001
                                     userInfo:@{NSLocalizedDescriptionKey: exception.reason ?: @"출력 실패"}];
        }
        return NO;
    }
}

#pragma mark - Private Methods

/**
 * 날짜/시간 출력 (작은 글씨, 다국어)
 * 예: 10월 9일 (월) 14:43
 */
+ (void)printDateTime:(PrinterSDK*)printerSDK orderAt:(NSString*)orderAt language:(NSString*)language {
    // ISO 8601 형식의 날짜를 파싱하여 원하는 형식으로 변환
    NSString* dateTime = orderAt;

    if (orderAt && orderAt.length > 0) {
        NSDateFormatter* inputFormatter = [[NSDateFormatter alloc] init];
        [inputFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];

        NSDate* date = [inputFormatter dateFromString:orderAt];
        if (date) {
            NSDateFormatter* outputFormatter = [[NSDateFormatter alloc] init];

            if ([language isEqualToString:@"eng"]) {
                [outputFormatter setDateFormat:@"MMM d (E) HH:mm"];
                [outputFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
            } else if ([language isEqualToString:@"jpn"]) {
                [outputFormatter setDateFormat:@"M月d日 (E) HH:mm"];
                [outputFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"ja_JP"]];
            } else {
                [outputFormatter setDateFormat:@"M월 d일 (E) HH:mm"];
                [outputFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"ko_KR"]];
            }
            dateTime = [outputFormatter stringFromDate:date];
        }
    }

    UIImage* image = [KoreanTextRenderer createTextImage:dateTime
                                                textSize:24.0f
                                                  isBold:NO
                                                   align:TextAlignLeft];
    NSData* bitmap = [KoreanTextRenderer convertToBitmap:image];
    NSString* hexString = [PrinterUtilities dataToHexString:bitmap];
    [printerSDK sendHex:hexString];

    [self feedPaper:printerSDK lines:2];
}

/**
 * 주문 타입 출력 (굵게, 큰 글씨, 다국어)
 * CREATE -> "주문 추가" / "Order Added" / "注文追加"
 */
+ (void)printOrderType:(PrinterSDK*)printerSDK orderType:(NSString*)orderType localizer:(LocalizerNotification*)localizer {
    NSString* typeText;

    if ([orderType isEqualToString:@"CREATE"]) {
        typeText = [localizer getText:@"order_create"];
    } else if ([orderType isEqualToString:@"UPDATE"]) {
        typeText = [localizer getText:@"order_update"];
    } else if ([orderType isEqualToString:@"CANCELLED"]) {
        typeText = [localizer getText:@"order_cancelled"];
    } else if ([orderType isEqualToString:@"FULL_CANCELLED"]) {
        typeText = [localizer getText:@"order_full_cancelled"];
    } else if ([orderType isEqualToString:@"CALCULATED"]) {
        typeText = [localizer getText:@"order_calculated"];
    } else {
        typeText = [NSString stringWithFormat:@"%@  %@", [localizer getText:@"order"], orderType];
    }

    UIImage* image = [KoreanTextRenderer createTextImage:typeText
                                                textSize:42.0f
                                                  isBold:YES
                                                   align:TextAlignLeft];
    NSData* bitmap = [KoreanTextRenderer convertToBitmap:image];
    NSString* hexString = [PrinterUtilities dataToHexString:bitmap];
    [printerSDK sendHex:hexString];

    [self feedPaper:printerSDK lines:2];
}

/**
 * 테이블 번호 출력 (박스로 강조, 다국어)
 */
+ (void)printTableNumber:(PrinterSDK*)printerSDK tableNumber:(NSInteger)tableNumber localizer:(LocalizerNotification*)localizer {
    // 박스 윗부분
    NSString* boxTop = @"┌──────────────┐";
    UIImage* boxTopImage = [KoreanTextRenderer createTextImage:boxTop
                                                      textSize:32.0f
                                                        isBold:NO
                                                         align:TextAlignCenter];
    NSData* boxTopBitmap = [KoreanTextRenderer convertToBitmap:boxTopImage];
    [printerSDK sendHex:[PrinterUtilities dataToHexString:boxTopBitmap]];
    [self feedPaper:printerSDK lines:1];

    // 테이블 번호 (박스 중간)
    NSString* tableText = [NSString stringWithFormat:@"│  %@ %ld  │", [localizer getText:@"table"], (long)tableNumber];
    UIImage* tableImage = [KoreanTextRenderer createTextImage:tableText
                                                     textSize:42.0f
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

    [self feedPaper:printerSDK lines:1];
}

/**
 * 구분선 출력
 */
+ (void)printSeparator:(PrinterSDK*)printerSDK {
    UIImage* image = [KoreanTextRenderer createTextImage:[PrintConstants separatorLine]
                                                textSize:[PrintConstants separatorFontSize]
                                                  isBold:NO
                                                   align:TextAlignCenter];
    NSData* bitmap = [KoreanTextRenderer convertToBitmap:image];
    NSString* hexString = [PrinterUtilities dataToHexString:bitmap];
    [printerSDK sendHex:hexString];

    [self feedPaper:printerSDK lines:1];
}

/**
 * 메뉴 아이템 목록 출력 (다국어)
 */
+ (void)printMenuItems:(PrinterSDK*)printerSDK items:(NSArray*)items localizer:(LocalizerNotification*)localizer {
    for (NSDictionary* item in items) {
        NSString* menuName = item[@"menuName"] ?: [localizer getText:@"no_menu_name"];
        NSInteger quantity = [item[@"quantity"] integerValue];
        NSArray* itemOptions = item[@"itemOptions"] ?: @[];

        // 메뉴명과 수량을 한 줄에 출력
        [self printMenuItem:printerSDK menuName:menuName quantity:quantity];

        // 옵션이 있으면 출력
        if (itemOptions.count > 0) {
            [self printMenuItemOptions:printerSDK itemOptions:itemOptions localizer:localizer];
        }

        // 메뉴 아이템 간 간격
        [self feedPaper:printerSDK lines:2];
    }
}

/**
 * 메뉴 아이템 (메뉴명 + 수량) 출력
 * 예: 아메리카노 (ICE) x 2
 */
+ (void)printMenuItem:(PrinterSDK*)printerSDK menuName:(NSString*)menuName quantity:(NSInteger)quantity {
    // 메뉴명과 수량을 같은 줄에 출력
    NSString* menuText = [NSString stringWithFormat:@"%@ x %ld", menuName, (long)quantity];
    UIImage* menuImage = [KoreanTextRenderer createTextImage:menuText
                                                    textSize:36.0f
                                                      isBold:YES
                                                       align:TextAlignLeft];
    NSData* menuBitmap = [KoreanTextRenderer convertToBitmap:menuImage];
    [printerSDK sendHex:[PrinterUtilities dataToHexString:menuBitmap]];

    [self feedPaper:printerSDK lines:1];
}

/**
 * 메뉴 아이템 옵션 목록 출력 (다국어)
 * 예:
 * 옵션/ 맵기 : 중간맛
 * Option/ Spicy : Medium
 */
+ (void)printMenuItemOptions:(PrinterSDK*)printerSDK itemOptions:(NSArray*)itemOptions localizer:(LocalizerNotification*)localizer {
    NSMutableString* sb = [NSMutableString string];
    NSString* optionPrefix = [localizer getText:@"option"];

    for (NSDictionary* option in itemOptions) {
        NSString* optionName = option[@"name"] ?: [localizer getText:@"no_option_name"];
        NSArray* optionDetails = option[@"optionDetails"] ?: @[];

        // 옵션 상세 정보를 콤마로 구분하여 출력
        NSMutableArray* detailNames = [NSMutableArray array];
        for (NSDictionary* detail in optionDetails) {
            NSString* detailName = detail[@"name"];
            NSInteger detailQuantity = [detail[@"quantity"] integerValue];

            if (detailQuantity > 1) {
                [detailNames addObject:[NSString stringWithFormat:@"%@ x%ld", detailName, (long)detailQuantity]];
            } else if (detailName) {
                [detailNames addObject:detailName];
            }
        }

        NSString* joinedDetails = [detailNames componentsJoinedByString:@", "];
        if (joinedDetails.length > 0) {
            [sb appendFormat:@"%@ %@ : %@\n", optionPrefix, optionName, joinedDetails];
        }
    }

    if (sb.length > 0) {
        NSString* trimmedText = [sb stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        UIImage* image = [KoreanTextRenderer createTextImage:trimmedText
                                                    textSize:28.0f
                                                      isBold:NO
                                                       align:TextAlignLeft];
        NSData* bitmap = [KoreanTextRenderer convertToBitmap:image];
        [printerSDK sendHex:[PrinterUtilities dataToHexString:bitmap]];
    }
}

/**
 * 줄바꿈
 */
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

/**
 * 영수증 자르기
 */
+ (void)cutPaper:(PrinterSDK*)printerSDK {
    if (!printerSDK) return;

    // 용지 자르기 전에 충분한 공간 확보
    [self feedPaper:printerSDK lines:[PrintConstants lineFeedBeforeCut]];

    // ESC/POS 커팅 명령어 전송
    NSData* cutCommand = [EscPosConstants GS_V_n];
    NSString* hexString = [PrinterUtilities dataToHexString:cutCommand];
    [printerSDK sendHex:hexString];
}

@end

#pragma mark - LocalizerNotification Implementation

@implementation LocalizerNotification

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
        @"table": @"Table",
        @"order": @"Order",
        @"order_create": @"Order  Added",
        @"order_update": @"Order  Updated",
        @"order_cancelled": @"Order  Cancelled",
        @"order_full_cancelled": @"Full  Cancelled",
        @"order_calculated": @"Payment  Done",
        @"option": @"Option/",
        @"no_menu_name": @"No menu name",
        @"no_option_name": @"No option name"
    };
    return texts[key] ?: key;
}

- (NSString*)getJapaneseText:(NSString*)key {
    NSDictionary* texts = @{
        @"table": @"テーブル",
        @"order": @"注文",
        @"order_create": @"注文  追加",
        @"order_update": @"注文  変更",
        @"order_cancelled": @"注文  取消",
        @"order_full_cancelled": @"全体  取消",
        @"order_calculated": @"会計  完了",
        @"option": @"オプション/",
        @"no_menu_name": @"メニュー名なし",
        @"no_option_name": @"オプション名なし"
    };
    return texts[key] ?: key;
}

- (NSString*)getKoreanText:(NSString*)key {
    NSDictionary* texts = @{
        @"table": @"테이블",
        @"order": @"주문",
        @"order_create": @"주문  추가",
        @"order_update": @"주문  변경",
        @"order_cancelled": @"주문  취소",
        @"order_full_cancelled": @"전체  취소",
        @"order_calculated": @"계산  완료",
        @"option": @"옵션/",
        @"no_menu_name": @"메뉴명 없음",
        @"no_option_name": @"옵션명 없음"
    };
    return texts[key] ?: key;
}

@end
