//
//  EscPosDriver.m
//  blueberry_printer
//
//  ESC/POS 프린터 드라이버 구현
//

#import "EscPosDriver.h"
#import "../single_order/SingleOrderDirectPrinter.h"
#import "../multiple_order/MultipleOrderDirectPrinter.h"
#import "../order_notification/OrderNotificationPrinter.h"
#import "../common/KoreanTextRenderer.h"
#import "../common/PrinterCommands.h"
#import "../common/PrinterUtilities.h"
#import "../common/EscPosConstants.h"

@interface EscPosDriver ()

@property (nonatomic, strong) PrinterSDK* printerSDK;
@property (nonatomic, strong) Printer* connectedPrinter;
@property (nonatomic, strong) NSMutableDictionary* discoveredPrinters;
@property (nonatomic, copy, nullable) void (^connectionStatusCallback)(NSString* status);

@end

@implementation EscPosDriver

- (instancetype)init {
    self = [super init];
    if (self) {
        _printerSDK = [PrinterSDK defaultPrinterSDK];
        _discoveredPrinters = [[NSMutableDictionary alloc] init];
        [self setupNotifications];
    }
    return self;
}

- (void)setupNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handlePrinterDisconnected:)
                                                 name:PrinterDisconnectedNotification
                                               object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - PrinterDriver Protocol

- (PrinterType)getType {
    return PrinterTypeESCPOS;
}

- (BOOL)connectWithAddress:(NSString *)address error:(NSError **)error {
    NSLog(@"🔌 ESC/POS 프린터 연결 시작: %@", address);

    // 발견된 프린터 목록에서 찾기
    Printer* printer = [self.discoveredPrinters objectForKey:address];
    if (!printer) {
        // 목록에 없으면 스캔 시도
        __block BOOL found = NO;
        __block Printer* foundPrinter = nil;

        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

        [self.printerSDK scanPrintersWithCompletion:^(Printer* scannedPrinter) {
            if (scannedPrinter && [scannedPrinter.UUIDString isEqualToString:address]) {
                foundPrinter = scannedPrinter;
                found = YES;
                [self.printerSDK stopScanPrinters];
                dispatch_semaphore_signal(semaphore);
            }
        }];

        // 3초 대기
        dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC));
        dispatch_semaphore_wait(semaphore, timeout);
        [self.printerSDK stopScanPrinters];

        if (!found) {
            NSLog(@"❌ ESC/POS 프린터를 찾을 수 없음");
            if (error) {
                *error = [NSError errorWithDomain:@"EscPosDriver"
                                             code:1001
                                         userInfo:@{NSLocalizedDescriptionKey: @"프린터를 찾을 수 없습니다"}];
            }
            return NO;
        }
        printer = foundPrinter;
    }

    // 프린터 연결
    self.connectedPrinter = printer;
    [self.printerSDK connectBT:printer];

    // 연결 완료 대기 (1초)
    [NSThread sleepForTimeInterval:1.0];

    NSLog(@"✅ ESC/POS 프린터 연결 성공");
    return YES;
}

- (BOOL)disconnect {
    NSLog(@"🔌 ESC/POS 프린터 연결 해제");

    [self stopConnectionMonitoring];
    [self.printerSDK disconnect];
    self.connectedPrinter = nil;

    return YES;
}

- (BOOL)isConnected {
    return self.connectedPrinter != nil && self.printerSDK != nil;
}

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
                           error:(NSError **)error {
    if (![self isConnected]) {
        NSLog(@"❌ 프린터가 연결되지 않았습니다");
        if (error) {
            *error = [NSError errorWithDomain:@"EscPosDriver"
                                         code:1002
                                     userInfo:@{NSLocalizedDescriptionKey: @"프린터가 연결되지 않았습니다"}];
        }
        return NO;
    }

    NSLog(@"📄 단일 주문 영수증 출력 (ESC/POS)");

    return [SingleOrderDirectPrinter printOrder:orderData
                                      storeName:storeName
                                   storeAddress:storeAddress
                                    phoneNumber:phoneNumber
                                 businessNumber:businessNumber
                                thankYouMessage:thankYouMessage
                                       language:language
                                       currency:currency
                                    tableNumber:tableNumber
                                 showStoreLabel:showStoreLabel
                                     printerSDK:self.printerSDK
                                          error:error];
}

- (BOOL)printTotalOrderWithData:(NSDictionary *)orderData
                      storeName:(NSString *)storeName
                    tableNumber:(nullable NSString *)tableNumber
                   storeAddress:(nullable NSString *)storeAddress
                    phoneNumber:(nullable NSString *)phoneNumber
                 businessNumber:(nullable NSString *)businessNumber
               thankYouMessage:(nullable NSString *)thankYouMessage
                       language:(NSString *)language
                       currency:(NSString *)currency
                          error:(NSError **)error {
    if (![self isConnected]) {
        NSLog(@"❌ 프린터가 연결되지 않았습니다");
        if (error) {
            *error = [NSError errorWithDomain:@"EscPosDriver"
                                         code:1002
                                     userInfo:@{NSLocalizedDescriptionKey: @"프린터가 연결되지 않았습니다"}];
        }
        return NO;
    }

    NSLog(@"📄 전체 주문 영수증 출력 (ESC/POS)");

    return [MultipleOrderDirectPrinter printOrder:orderData
                                        storeName:storeName
                                     storeAddress:storeAddress
                                      phoneNumber:phoneNumber
                                   businessNumber:businessNumber
                                  thankYouMessage:thankYouMessage
                                         language:language
                                         currency:currency
                                      tableNumber:tableNumber
                                       printerSDK:self.printerSDK
                                            error:error];
}

- (BOOL)printOrderFromSocketWithData:(NSDictionary *)orderData
                            language:(NSString *)language
                            currency:(NSString *)currency
                               error:(NSError **)error {
    if (![self isConnected]) {
        NSLog(@"❌ 프린터가 연결되지 않았습니다");
        if (error) {
            *error = [NSError errorWithDomain:@"EscPosDriver"
                                         code:1002
                                     userInfo:@{NSLocalizedDescriptionKey: @"프린터가 연결되지 않았습니다"}];
        }
        return NO;
    }

    NSLog(@"📄 주문 알림 영수증 출력 (ESC/POS)");

    return [OrderNotificationPrinter printNotification:orderData
                                              language:language
                                              currency:currency
                                            printerSDK:self.printerSDK
                                                 error:error];
}

- (BOOL)printTextWithText:(NSString *)text
                 fontSize:(CGFloat)fontSize
                   isBold:(BOOL)isBold
                    align:(NSString *)align
                    error:(NSError **)error {
    if (![self isConnected]) {
        NSLog(@"❌ 프린터가 연결되지 않았습니다");
        if (error) {
            *error = [NSError errorWithDomain:@"EscPosDriver"
                                         code:1002
                                     userInfo:@{NSLocalizedDescriptionKey: @"프린터가 연결되지 않았습니다"}];
        }
        return NO;
    }

    NSLog(@"📄 텍스트 출력 (ESC/POS): %@", text);

    @try {
        // 프린터 초기화
        NSData* initCommand = [PrinterCommands POS_Set_PrtInit];
        [self.printerSDK sendHex:[PrinterUtilities dataToHexString:initCommand]];

        // 정렬 방식 변환
        TextAlign textAlign = TextAlignLeft;
        if ([align.uppercaseString isEqualToString:@"CENTER"]) {
            textAlign = TextAlignCenter;
        } else if ([align.uppercaseString isEqualToString:@"RIGHT"]) {
            textAlign = TextAlignRight;
        }

        // 텍스트를 이미지로 렌더링하여 출력
        UIImage* image = [KoreanTextRenderer createTextImage:text
                                                     textSize:fontSize
                                                       isBold:isBold
                                                        align:textAlign];
        NSData* bitmap = [KoreanTextRenderer convertToBitmap:image];
        NSString* hexString = [PrinterUtilities dataToHexString:bitmap];
        [self.printerSDK sendHex:hexString];

        // 줄바꿈 및 용지 자르기
        NSData* feedCommand = [PrinterCommands POS_Set_PrtAndFeedPaper:100];
        [self.printerSDK sendHex:[PrinterUtilities dataToHexString:feedCommand]];

        NSData* cutCommand = [EscPosConstants GS_V_n];
        [self.printerSDK sendHex:[PrinterUtilities dataToHexString:cutCommand]];

        return YES;
    } @catch (NSException* exception) {
        NSLog(@"❌ 텍스트 출력 실패: %@", exception.reason);
        if (error) {
            *error = [NSError errorWithDomain:@"EscPosDriver"
                                         code:1003
                                     userInfo:@{NSLocalizedDescriptionKey: exception.reason}];
        }
        return NO;
    }
}

- (void)startConnectionMonitoringWithCallback:(void (^)(NSString *status))callback {
    NSLog(@"🔍 ESC/POS 프린터 연결 모니터링 시작");
    self.connectionStatusCallback = callback;
}

- (void)stopConnectionMonitoring {
    NSLog(@"🔍 ESC/POS 프린터 연결 모니터링 중지");
    self.connectionStatusCallback = nil;
}

- (void)cleanup {
    [self stopConnectionMonitoring];
    [self disconnect];
}

#pragma mark - Notifications

- (void)handlePrinterDisconnected:(NSNotification*)notification {
    NSLog(@"⚠️ ESC/POS 프린터 연결 해제됨 (Notification)");
    if (self.connectionStatusCallback) {
        self.connectionStatusCallback(@"disconnected");
    }
}

#pragma mark - Helper Methods

/**
 * 프린터 스캔 및 발견된 프린터 저장 (내부 사용)
 */
- (void)scanAndStoreDevices {
    [self.discoveredPrinters removeAllObjects];

    __block dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    [self.printerSDK scanPrintersWithCompletion:^(Printer* printer) {
        if (printer) {
            NSString* address = printer.UUIDString ?: @"";
            [self.discoveredPrinters setObject:printer forKey:address];
            NSLog(@"🔍 프린터 발견: %@ (%@)", printer.name, address);
        }
    }];

    // 3초 스캔
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.printerSDK stopScanPrinters];
        dispatch_semaphore_signal(semaphore);
    });

    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
}

@end
