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
        if (!orderData) {
            NSLog(@" [DEBUG] 출력 실패: 주문 데이터 없음");
            result([FlutterError errorWithCode:@"NO_DATA" 
                                     message:@"주문 데이터가 필요합니다" 
                                     details:nil]);
            return;
        }
        [self printOrderReceipt:orderData result:result];
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

- (void)printOrderReceipt:(NSDictionary*)orderData result:(FlutterResult)result {
    NSLog(@"🔍 [DEBUG] 구조화된 주문 영수증 출력 시도");
    
    @try {
        // 주문 기본 정보 추출
        NSString* orderNumber = orderData[@"orderNumber"] ?: @"주문번호 없음";
        NSString* tableName = orderData[@"tableName"] ?: @"테이블 정보 없음";
        NSNumber* totalPriceNum = orderData[@"totalPrice"];
        NSInteger totalPrice = totalPriceNum ? [totalPriceNum integerValue] : 0;
        
        // 영수증 포맷 생성
        NSMutableString* receiptText = [[NSMutableString alloc] init];
        
        // 타이틀 섹션 (커스텀 영수증과 동일한 포맷)
        [receiptText appendString:@"타이틀, 80\n"];
        [receiptText appendString:@"카페 블루베리\n\n"];
        
        // 매장정보 섹션
        [receiptText appendString:@"매장정보, 20\n"];
        [receiptText appendString:@"서울특별시 강남구 테헤란로 123\n"];
        [receiptText appendString:@"전화: 02-1234-5678\n"];
        [receiptText appendString:@"사업자등록번호: 123-45-67890\n\n"];
        
        // 구분선 섹션
        [receiptText appendString:@"구분선, 20\n"];
        [receiptText appendString:@"================================\n\n"];
        
        // 주문 정보 섹션
        [receiptText appendString:@"주문정보, 20\n"];
        [receiptText appendFormat:@"주문번호: %@\n", orderNumber];
        [receiptText appendFormat:@"테이블: %@\n\n", tableName];
        
        // 상품 목록 섹션
        [receiptText appendString:@"상품목록, 20\n"];
        
        NSArray* orderVersions = orderData[@"orderVersion"];
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
                        
                        [receiptText appendFormat:@"%@ x%ld = %@원\n", 
                         menuName, (long)quantity, [self formatPrice:price]];
                        
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
                                            [receiptText appendFormat:@"  + %@ x%ld = %@원\n", 
                                             itemName, (long)itemQuantity, [self formatPrice:itemPrice]];
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
        [receiptText appendString:@"합계, 20\n"];
        [receiptText appendFormat:@"소계: %@원\n", [self formatPrice:totalPrice]];
        NSInteger tax = (NSInteger)(totalPrice * 0.1);
        NSInteger totalWithTax = totalPrice + tax;
        [receiptText appendFormat:@"부가세: %@원\n", [self formatPrice:tax]];
        [receiptText appendFormat:@"합계: %@원\n\n", [self formatPrice:totalWithTax]];
        
        // 줄바꿈 명령
        [receiptText appendString:@"줄바꿈, 2\n\n"];
        
        // 감사 메시지 섹션
        [receiptText appendString:@"감사메시지, 20\n"];
        [receiptText appendString:@"감사합니다!\n"];
        [receiptText appendString:@"다음에 또 방문해 주세요.\n\n"];
        
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
        NSString* fallbackText = @"타이틀, 80\n카페 블루베리\n\n감사메시지, 20\n감사합니다!\n\n영수증 자르기";
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