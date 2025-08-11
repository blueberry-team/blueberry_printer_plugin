//
//  BlueberryPrinterPlugin.m
//  blueberry_printer
//
//  Created for Flutter plugin
//

#import "BlueberryPrinterPlugin.h"
#import "ReceiptParser.h"

@interface BlueberryPrinterPlugin ()
{
    NSMutableDictionary* _discoveredPrinters;
    FlutterResult _scanCallback;
    PrinterSDK* _printerSDK;
    BOOL _isScanning;
}
@end

@implementation BlueberryPrinterPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                    methodChannelWithName:@"blueberry_printer"
                                    binaryMessenger:[registrar messenger]];
    BlueberryPrinterPlugin* instance = [[BlueberryPrinterPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _discoveredPrinters = [[NSMutableDictionary alloc] init];
        _printerSDK = [PrinterSDK defaultPrinterSDK];
        [self setupPrinterNotifications];
    }
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSLog(@"🔍 [DEBUG] Flutter 메서드 호출: %@", call.method);
    
    if ([@"getPlatformVersion" isEqualToString:call.method]) {
        result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
    }
    else if ([@"searchDevices" isEqualToString:call.method]) {
        [self searchDevices:result];
    }
    else if ([@"connectDevice" isEqualToString:call.method]) {
        NSDictionary* args = call.arguments;
        NSString* address = args[@"address"];
        if (!address) {
            NSLog(@"🔍 [DEBUG] 연결 실패: 잘못된 인수");
            result([FlutterError errorWithCode:@"INVALID_ARGS" 
                                     message:@"기기 주소가 필요합니다" 
                                     details:nil]);
            return;
        }
        [self connectDevice:address result:result];
    }
    else if ([@"printReceipt" isEqualToString:call.method]) {
        NSDictionary* args = call.arguments;
        NSString* receiptText = args[@"receiptText"];
        if (!receiptText) {
            NSLog(@"🔍 [DEBUG] 출력 실패: 잘못된 인수");
            result([FlutterError errorWithCode:@"NO_TEXT" 
                                     message:@"출력할 텍스트가 필요합니다" 
                                     details:nil]);
            return;
        }
        [self printReceipt:receiptText result:result];
    }
    else if ([@"printSampleReceipt" isEqualToString:call.method]) {
        [self printSampleReceipt:result];
    }
    else if ([@"printOrderReceipt" isEqualToString:call.method]) {
        NSDictionary* args = call.arguments;
        NSDictionary* orderData = args[@"orderData"];
        NSString* storeName = args[@"storeName"];
        NSString* language = args[@"language"] ?: @"kor";
        if (!orderData || !storeName) {
            NSLog(@"🔍 [DEBUG] 출력 실패: 주문 데이터 또는 매장명 없음");
            result([FlutterError errorWithCode:@"NO_DATA" 
                                     message:@"주문 데이터와 매장명이 필요합니다" 
                                     details:nil]);
            return;
        }
        NSLog(@"🔍 [DEBUG] iOS에서 받은 인자: %@", args);
        printf("🔍 [DEBUG] iOS printOrderReceipt 호출 시작\n");
        fflush(stdout);
        [self printOrderReceipt:args result:result];
    }
    else if ([@"disconnect" isEqualToString:call.method]) {
        [self disconnect:result];
    }
    else {
        NSLog(@" [DEBUG] 구현되지 않은 메서드: %@", call.method);
        result(FlutterMethodNotImplemented);
    }
}

- (void)setupPrinterNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handlePrinterConnected:)
                                                 name:PrinterConnectedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handlePrinterDisconnected:)
                                                 name:PrinterDisconnectedNotification
                                               object:nil];
}

- (void)handlePrinterConnected:(NSNotification*)notification {
    NSLog(@"🔍 [DEBUG] 프린터 연결됨");
}

- (void)handlePrinterDisconnected:(NSNotification*)notification {
    NSLog(@"🔍 [DEBUG] 프린터 연결 해제됨");
}

- (void)searchDevices:(FlutterResult)result {
    NSLog(@"🔍 [DEBUG] searchDevices() 시작 - 실제 프린터 SDK 사용");
    
    _scanCallback = result;
    [_discoveredPrinters removeAllObjects];
    
    // 실제 프린터 SDK로 스캔 시작
    [_printerSDK scanPrintersWithCompletion:^(Printer* printer) {
        NSLog(@"🔍 [DEBUG] 프린터 발견: %@ (%@)", printer.name ?: @"Unknown", printer.UUIDString ?: @"No UUID");
        
        // Printer 객체를 UUID로 저장
        if (printer.UUIDString) {
            [self->_discoveredPrinters setObject:printer forKey:printer.UUIDString];
        }
        
        // Flutter에 실시간으로 발견된 프린터 전송
        dispatch_async(dispatch_get_main_queue(), ^{
            NSMutableArray* devices = [[NSMutableArray alloc] init];
            for (NSString* uuid in self->_discoveredPrinters) {
                Printer* printer = [self->_discoveredPrinters objectForKey:uuid];
                NSDictionary* device = @{
                    @"name": printer.name ?: @"Unknown Printer",
                    @"address": uuid
                };
                [devices addObject:device];
            }
            NSLog(@"🔍 [DEBUG] 현재 발견된 프린터: %lu개", (unsigned long)devices.count);
        });
    }];
    
    // 10초 후 스캔 중단
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self->_printerSDK stopScanPrinters];
        
        NSMutableArray* devices = [[NSMutableArray alloc] init];
        for (NSString* uuid in self->_discoveredPrinters) {
            Printer* printer = [self->_discoveredPrinters objectForKey:uuid];
            NSDictionary* device = @{
                @"name": printer.name ?: @"Unknown Printer",
                @"address": uuid
            };
            [devices addObject:device];
        }
        NSLog(@"🔍 [DEBUG] 스캔 완료: %lu개 프린터 발견", (unsigned long)devices.count);
        self->_scanCallback(devices);
        self->_scanCallback = nil;
    });
}

- (void)connectDevice:(NSString*)address result:(FlutterResult)result {
    NSLog(@"🔍 [DEBUG] 연결 시도 시작: %@", address);
    
    // 발견된 프린터 중에서 해당 주소의 프린터 찾기
    Printer* printer = [_discoveredPrinters objectForKey:address];
    if (!printer) {
        NSLog(@"🔍 [DEBUG] 해당 주소의 프린터를 찾을 수 없음: %@", address);
        result([FlutterError errorWithCode:@"PRINTER_NOT_FOUND" 
                                 message:@"해당 주소의 프린터를 찾을 수 없습니다" 
                                 details:nil]);
        return;
    }
    
    NSLog(@"🔍 [DEBUG] 프린터 연결 시도: %@", printer.name ?: @"Unknown");
    
    // 실제 프린터 SDK로 연결
    [_printerSDK connectBT:printer];
    
    // 연결 완료 대기 (실제로는 notification으로 처리됨)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"🔍 [DEBUG] 프린터 연결 완료");
        result(@YES);
    });
}

- (void)printReceipt:(NSString*)receiptText result:(FlutterResult)result {
    NSLog(@"🔍 [DEBUG] 출력 시도 시작");
    NSLog(@"🔍 [DEBUG] 출력할 텍스트: %@", receiptText);
    
    // ReceiptParser를 사용해서 플러터 데이터를 파싱하고 출력
    NSData* commandData = [ReceiptParser parseReceiptText:receiptText];
    if (commandData) {
        NSString* hexString = [ReceiptParser dataToHexString:commandData];
        [_printerSDK sendHex:hexString];
        NSLog(@"🔍 [DEBUG] ESC/POS 명령어 전송 완료: %lu바이트", (unsigned long)commandData.length);
    } else {
        NSLog(@"🔍 [DEBUG] 파싱 실패, 일반 텍스트 출력");
        [_printerSDK printText:receiptText];
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"🔍 [DEBUG] 출력 완료");
        result(@YES);
    });
}





- (void)printSampleReceipt:(FlutterResult)result {
    NSLog(@"🔍 [DEBUG] 샘플 영수증 출력 시도");
    
    // 플러터의 샘플 데이터와 동일한 형식으로 샘플 영수증 생성
    NSString* sampleText = @"타이틀, 40\n"
                           @"카페 블루베리\n\n"
                           @"매장정보, 20\n"
                           @"서울특별시 강남구 테헤란로 123\n"
                           @"전화: 02-1234-5678\n"
                           @"사업자등록번호: 123-45-67890\n\n"
                           @"구분선, 20\n"
                           @"================================\n\n"
                           @"상품목록, 20\n"
                           @"아메리카노 (ICE)        4,500원 x 2\n"
                           @"카페라떼 (HOT)          5,000원 x 1\n"
                           @"블루베리 머핀           3,500원 x 1\n\n"
                           @"줄바꿈, 2\n\n"
                           @"합계, 20\n"
                           @"소계: 17,500원\n"
                           @"부가세: 1,750원\n"
                           @"합계: 19,250원\n\n"
                           @"줄바꿈, 2\n\n"
                           @"감사메시지, 20\n"
                           @"감사합니다!\n"
                           @"다음에 또 방문해 주세요.\n\n"
                           @"줄바꿈, 3\n\n"
                           @"영수증 자르기";
    
    NSLog(@"🔍 [DEBUG] 샘플 텍스트 생성 완료");
    
    // printReceipt 함수 재사용
    [self printReceipt:sampleText result:result];
}

- (void)printOrderReceipt:(NSDictionary*)arguments result:(FlutterResult)result {
    NSLog(@"🔍 [DEBUG] 구조화된 주문 영수증 출력 시도");
    printf("🔍 [DEBUG] iOS printOrderReceipt 메서드 시작\n");
    fflush(stdout);
    
    // 인자에서 데이터 추출 (에러 처리에서도 사용하기 위해 @try 밖에 선언)
    NSDictionary* orderData = arguments[@"orderData"];
    NSString* storeName = arguments[@"storeName"] ?: @"매장명 없음";
    NSString* language = arguments[@"language"] ?: @"kor";
    NSString* currency = arguments[@"currency"] ?: @"KRW";
    
    NSLog(@"🔍 [DEBUG] iOS 매장명: %@, 언어: %@", storeName, language);
    printf("🔍 [DEBUG] iOS 매장명: %s, 언어: %s\n", [storeName UTF8String], [language UTF8String]);
    fflush(stdout);
    
    // 다국어 텍스트 헬퍼 함수
    NSString* (^getLocalizedText)(NSString*) = ^NSString*(NSString* key) {
        if ([language isEqualToString:@"eng"]) {
            if ([key isEqualToString:@"store_info"]) return @"Store Information";
            if ([key isEqualToString:@"order_info"]) return @"Order Information";
            if ([key isEqualToString:@"order_number"]) return @"Order No";
            if ([key isEqualToString:@"table"]) return @"Table";
            if ([key isEqualToString:@"menu_list"]) return @"Menu List";
            if ([key isEqualToString:@"subtotal"]) return @"Subtotal";
            if ([key isEqualToString:@"tax"]) return @"Tax";
            if ([key isEqualToString:@"total"]) return @"Total";
            if ([key isEqualToString:@"thank_you_default"]) return @"Thank you!\nPlease visit us again.";
            if ([key isEqualToString:@"thank_you_message"]) return @"Thank You Message";
            if ([key isEqualToString:@"phone"]) return @"Phone";
            if ([key isEqualToString:@"business_number"]) return @"Business No";
            if ([key isEqualToString:@"no_order_number"]) return @"No order number";
            if ([key isEqualToString:@"no_table_info"]) return @"No table info";
        } else if ([language isEqualToString:@"jpn"]) {
            if ([key isEqualToString:@"store_info"]) return @"店舗情報";
            if ([key isEqualToString:@"order_info"]) return @"注文情報";
            if ([key isEqualToString:@"order_number"]) return @"注文番号";
            if ([key isEqualToString:@"table"]) return @"テーブル";
            if ([key isEqualToString:@"menu_list"]) return @"メニューリスト";
            if ([key isEqualToString:@"subtotal"]) return @"小計";
            if ([key isEqualToString:@"tax"]) return @"税金";
            if ([key isEqualToString:@"total"]) return @"合計";
            if ([key isEqualToString:@"thank_you_default"]) return @"ありがとうございます！\nまたお越しください。";
            if ([key isEqualToString:@"thank_you_message"]) return @"メッセージ";
            if ([key isEqualToString:@"phone"]) return @"電話";
            if ([key isEqualToString:@"business_number"]) return @"事業者番号";
            if ([key isEqualToString:@"no_order_number"]) return @"注文番号なし";
            if ([key isEqualToString:@"no_table_info"]) return @"テーブル情報なし";
        } else { // kor (기본값)
            if ([key isEqualToString:@"store_info"]) return @"매장정보";
            if ([key isEqualToString:@"order_info"]) return @"주문정보";
            if ([key isEqualToString:@"order_number"]) return @"주문번호";
            if ([key isEqualToString:@"table"]) return @"테이블";
            if ([key isEqualToString:@"menu_list"]) return @"상품목록";
            if ([key isEqualToString:@"subtotal"]) return @"소계";
            if ([key isEqualToString:@"tax"]) return @"부가세";
            if ([key isEqualToString:@"total"]) return @"합계";
            if ([key isEqualToString:@"thank_you_default"]) return @"감사합니다!\n다음에 또 방문해 주세요.";
            if ([key isEqualToString:@"thank_you_message"]) return @"감사메시지";
            if ([key isEqualToString:@"phone"]) return @"전화";
            if ([key isEqualToString:@"business_number"]) return @"사업자등록번호";
            if ([key isEqualToString:@"no_order_number"]) return @"주문번호 없음";
            if ([key isEqualToString:@"no_table_info"]) return @"테이블 정보 없음";
        }
        return key;
    };
    
    // 화폐 단위 헬퍼 함수
    NSString* (^getCurrencySymbol)(void) = ^NSString*(void) {
        if ([currency isEqualToString:@"USD"]) return @"$";
        if ([currency isEqualToString:@"JPY"]) return @"¥";
        if ([currency isEqualToString:@"EUR"]) return @"€";
        return @"원"; // KRW 기본값
    };
    
    @try {
        NSString* storeAddress = arguments[@"storeAddress"];
        NSString* phoneNumber = arguments[@"phoneNumber"];
        NSString* businessNumber = arguments[@"businessNumber"];
        NSString* thankYouMessage = arguments[@"thankYouMessage"];
        
        // 주문 기본 정보 추출
        NSString* orderNumber = orderData[@"orderNumber"] ?: getLocalizedText(@"no_order_number");
        NSString* tableName = orderData[@"tableName"] ?: getLocalizedText(@"no_table_info");
        
        // 주문 데이터에서 총 금액 자동 계산
        NSInteger calculatedTotalPrice = 0;
        NSArray* orderVersions = orderData[@"orderVersion"];
        if (orderVersions && [orderVersions isKindOfClass:[NSArray class]]) {
            for (NSDictionary* version in orderVersions) {
                NSArray* orderItems = version[@"orderItems"];
                if (orderItems && [orderItems isKindOfClass:[NSArray class]]) {
                    for (NSDictionary* item in orderItems) {
                        NSNumber* itemPriceNum = item[@"price"];
                        NSNumber* itemQuantityNum = item[@"quantity"];
                        NSInteger itemPrice = itemPriceNum ? [itemPriceNum integerValue] : 0;
                        NSInteger itemQuantity = itemQuantityNum ? [itemQuantityNum integerValue] : 0;
                        calculatedTotalPrice += (itemPrice * itemQuantity);
                        
                        // 옵션 가격도 추가
                        NSArray* options = item[@"options"];
                        if (options && [options isKindOfClass:[NSArray class]]) {
                            for (NSDictionary* option in options) {
                                NSArray* selectedItems = option[@"selectedItems"];
                                if (selectedItems && [selectedItems isKindOfClass:[NSArray class]]) {
                                    for (NSDictionary* selectedItem in selectedItems) {
                                        NSNumber* optionPriceNum = selectedItem[@"itemPrice"];
                                        NSNumber* optionQuantityNum = selectedItem[@"quantity"];
                                        NSInteger optionPrice = optionPriceNum ? [optionPriceNum integerValue] : 0;
                                        NSInteger optionQuantity = optionQuantityNum ? [optionQuantityNum integerValue] : 0;
                                        calculatedTotalPrice += (optionPrice * optionQuantity);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        NSLog(@"🔍 [DEBUG] 계산된 총 금액: %ld", (long)calculatedTotalPrice);
        
        // 영수증 포맷 생성
        NSMutableString* receiptText = [[NSMutableString alloc] init];
        
        // 타이틀 섹션 (커스텀 영수증과 동일한 포맷)
        [receiptText appendString:@"타이틀, 80\n"];
        [receiptText appendFormat:@"%@\n\n", storeName];
        
        // 매장정보 섹션
        [receiptText appendFormat:@"%@, 20\n", getLocalizedText(@"store_info")];
        if (storeAddress) {
            [receiptText appendFormat:@"%@\n", storeAddress];
        }
        if (phoneNumber) {
            [receiptText appendFormat:@"%@: %@\n", getLocalizedText(@"phone"), phoneNumber];
        }
        if (businessNumber) {
            [receiptText appendFormat:@"%@: %@\n", getLocalizedText(@"business_number"), businessNumber];
        }
        [receiptText appendString:@"\n"];
        
        // 구분선 섹션
        [receiptText appendString:@"구분선, 20\n"];
        [receiptText appendString:@"================================\n\n"];
        
        // 주문 정보 섹션
        [receiptText appendFormat:@"%@, 20\n", getLocalizedText(@"order_info")];
        [receiptText appendFormat:@"%@: %@\n", getLocalizedText(@"order_number"), orderNumber];
        [receiptText appendFormat:@"%@: %@\n\n", getLocalizedText(@"table"), tableName];
        
        // 상품 목록 섹션
        [receiptText appendFormat:@"%@, 20\n", getLocalizedText(@"menu_list")];
        if (orderVersions && [orderVersions isKindOfClass:[NSArray class]]) {
            for (NSDictionary* version in orderVersions) {
                NSArray* orderItems = version[@"orderItems"];
                if (orderItems && [orderItems isKindOfClass:[NSArray class]]) {
                    for (NSDictionary* item in orderItems) {
                        NSString* menuName = item[@"menuName"] ?: @"상품명 없음";
                        NSNumber* quantityNum = item[@"quantity"];
                        NSNumber* priceNum = item[@"price"];
                        NSInteger quantity = quantityNum ? [quantityNum integerValue] : 0;
                        NSInteger price = priceNum ? [priceNum integerValue] : 0;
                        
                        [receiptText appendFormat:@"%@ x%ld = %@%@\n", 
                         menuName, (long)quantity, [self formatPrice:price], getCurrencySymbol()];
                        
                        // 옵션 처리
                        NSArray* options = item[@"options"];
                        if (options && [options isKindOfClass:[NSArray class]]) {
                            for (NSDictionary* option in options) {
                                NSArray* selectedItems = option[@"selectedItems"];
                                if (selectedItems && [selectedItems isKindOfClass:[NSArray class]]) {
                                    for (NSDictionary* selectedItem in selectedItems) {
                                        NSString* itemName = selectedItem[@"itemName"] ?: @"옵션명 없음";
                                        NSNumber* itemPriceNum = selectedItem[@"itemPrice"];
                                        NSNumber* itemQuantityNum = selectedItem[@"quantity"];
                                        NSInteger itemPrice = itemPriceNum ? [itemPriceNum integerValue] : 0;
                                        NSInteger itemQuantity = itemQuantityNum ? [itemQuantityNum integerValue] : 0;
                                        
                                        if (itemPrice > 0) {
                                            [receiptText appendFormat:@"  + %@ x%ld = %@%@\n", 
                                             itemName, (long)itemQuantity, [self formatPrice:itemPrice], getCurrencySymbol()];
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        
        // 줄바꿈 명령
        [receiptText appendString:@"줄바꿈, 2\n\n"];
        
        // 합계 섹션
        [receiptText appendFormat:@"%@, 20\n", getLocalizedText(@"total")];
        [receiptText appendFormat:@"%@: %@%@\n\n", getLocalizedText(@"total"), [self formatPrice:calculatedTotalPrice], getCurrencySymbol()];
        
        // 줄바꿈 명령
        [receiptText appendString:@"줄바꿈, 2\n\n"];
        
        // 감사 메시지 섹션
        [receiptText appendFormat:@"%@, 20\n", getLocalizedText(@"thank_you_message")];
        if (thankYouMessage) {
            [receiptText appendFormat:@"%@\n\n", thankYouMessage];
        } else {
            [receiptText appendFormat:@"%@\n\n", getLocalizedText(@"thank_you_default")];
        }
        
        // 줄바꿈 명령
        [receiptText appendString:@"줄바꿈, 3\n\n"];
        
        // 영수증 자르기 명령
        [receiptText appendString:@"영수증 자르기"];
        
        NSLog(@"🔍 [DEBUG] 영수증 포맷팅 완료");
        
        // 기존 printReceipt 메서드 재사용
        [self printReceipt:receiptText result:result];
        
    } @catch (NSException *exception) {
        NSLog(@"🔍 [DEBUG] 구조화된 영수증 처리 오류: %@", exception.reason);
        // 에러 시 기본 영수증 출력
        NSString* fallbackText = [NSString stringWithFormat:@"타이틀, 80\n%@\n\n감사메시지, 20\n감사합니다!\n\n영수증 자르기", storeName ?: @"매장"];
        [self printReceipt:fallbackText result:result];
    }
}

/**
 * 가격 포맷팅 (천단위 콤마)
 */
- (NSString*)formatPrice:(NSInteger)price {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [formatter setGroupingSeparator:@","];
    return [formatter stringFromNumber:@(price)];
}

- (void)disconnect:(FlutterResult)result {
    NSLog(@"🔍 [DEBUG] 연결 해제 시도");
    
    [_printerSDK disconnect];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"🔍 [DEBUG] 연결 해제 완료");
        result(@YES);
    });
}

@end 