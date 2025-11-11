//
//  BlueberryPrinterPlugin.m
//  blueberry_printer
//
//  Created for Flutter plugin (드라이버 패턴 리팩토링 버전)
//

#import "BlueberryPrinterPlugin.h"
#import "drivers/PrinterDriver.h"
#import "drivers/EscPosDriver.h"
#import "drivers/StarIoDriver.h"
#import "bluetooth_search/BluetoothDeviceSearcher.h"
#import "common/DisconnectReason.h"

@interface BlueberryPrinterPlugin () <FlutterStreamHandler>
{
    NSMutableDictionary* _discoveredPrinters;
    FlutterResult _scanCallback;
    PrinterSDK* _printerSDK;
    BOOL _isScanning;
}

@property (nonatomic, strong) id<PrinterDriver> currentDriver;
@property (nonatomic, strong) Printer* connectedPrinter;
@property (nonatomic, strong) FlutterEventSink eventSink;

@end

@implementation BlueberryPrinterPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                    methodChannelWithName:@"blueberry_printer"
                                    binaryMessenger:[registrar messenger]];

    FlutterEventChannel* eventChannel = [FlutterEventChannel
                                        eventChannelWithName:@"blueberry_printer/connection_status"
                                        binaryMessenger:[registrar messenger]];

    BlueberryPrinterPlugin* instance = [[BlueberryPrinterPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
    [eventChannel setStreamHandler:instance];
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

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - FlutterStreamHandler

- (FlutterError*)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)events {
    self.eventSink = events;
    return nil;
}

- (FlutterError*)onCancelWithArguments:(id)arguments {
    self.eventSink = nil;
    return nil;
}

#pragma mark - Method Call Handler

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSLog(@"🔍 Flutter 메서드 호출: %@", call.method);

    if ([@"getPlatformVersion" isEqualToString:call.method]) {
        result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
    }
    else if ([@"searchDevices" isEqualToString:call.method]) {
        [self searchDevices:result];
    }
    else if ([@"connectDevice" isEqualToString:call.method]) {
        NSString* address = call.arguments[@"address"];
        if (!address) {
            result([FlutterError errorWithCode:@"NO_ADDRESS" message:@"기기 주소가 필요합니다" details:nil]);
            return;
        }
        [self connectDevice:address result:result];
    }
    else if ([@"printSingleOrder" isEqualToString:call.method]) {
        [self printSingleOrder:call.arguments result:result];
    }
    else if ([@"printTotalOrder" isEqualToString:call.method]) {
        [self printTotalOrder:call.arguments result:result];
    }
    else if ([@"printOrderFromSocket" isEqualToString:call.method]) {
        [self printOrderFromSocket:call.arguments result:result];
    }
    else if ([@"printText" isEqualToString:call.method]) {
        [self printText:call.arguments result:result];
    }
    else if ([@"disconnect" isEqualToString:call.method]) {
        [self disconnect:result];
    }
    else {
        result(FlutterMethodNotImplemented);
    }
}

#pragma mark - Device Management

- (void)searchDevices:(FlutterResult)result {
    NSLog(@"🔍 searchDevices() 시작");

    _scanCallback = result;
    [_discoveredPrinters removeAllObjects];

    [_printerSDK scanPrintersWithCompletion:^(Printer* printer) {
        if (printer) {
            NSString* name = printer.name ?: @"Unknown Printer";
            NSString* address = printer.UUIDString ?: @"";

            // Printer 객체를 Dictionary에 저장
            [_discoveredPrinters setObject:printer forKey:address];

            NSLog(@"🔍 프린터 발견: %@ (%@)", name, address);
        }
    }];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [_printerSDK stopScanPrinters];

        NSMutableArray* deviceList = [NSMutableArray array];
        for (NSString* address in _discoveredPrinters) {
            Printer* printer = _discoveredPrinters[address];
            [deviceList addObject:@{
                @"name": printer.name ?: @"Unknown",
                @"address": printer.UUIDString ?: @""
            }];
        }

        NSLog(@"✅ 검색 완료: %lu개 기기", (unsigned long)deviceList.count);
        _scanCallback(deviceList);
        _scanCallback = nil;
    });
}

- (void)connectDevice:(NSString*)address result:(FlutterResult)result {
    NSLog(@"🔌 프린터 연결 시작: %@", address);

    Printer* printer = [_discoveredPrinters objectForKey:address];
    if (!printer) {
        NSLog(@"❌ 프린터를 찾을 수 없음");
        result([FlutterError errorWithCode:@"NOT_FOUND" message:@"프린터를 찾을 수 없습니다" details:nil]);
        return;
    }

    // 프린터 타입 자동 감지
    NSString* deviceName = printer.name ?: @"Unknown";
    NSString* printerType = [BluetoothDeviceSearcher detectPrinterType:deviceName];

    NSLog(@"🔍 감지된 프린터 타입: %@ (기기명: %@)", printerType, deviceName);

    // 드라이버 선택
    id<PrinterDriver> driver;
    if ([printerType isEqualToString:@"star_micronics"]) {
        NSLog(@"📌 StarIoDriver 선택");
        driver = [[StarIoDriver alloc] init];
    } else {
        NSLog(@"📌 EscPosDriver 선택");
        driver = [[EscPosDriver alloc] init];
    }

    // 드라이버로 연결
    NSError* error = nil;
    BOOL connected = [driver connectWithAddress:address error:&error];

    if (connected) {
        self.currentDriver = driver;
        self.connectedPrinter = printer;

        // 연결 모니터링 시작
        __weak typeof(self) weakSelf = self;
        [driver startConnectionMonitoringWithCallback:^(NSString* status) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf) {
                [strongSelf sendConnectionStatus:status message:@"" reason:@""];
            }
        }];

        NSLog(@"✅ 프린터 연결 완료");
        [self sendConnectionStatus:@"connected" message:@"" reason:@""];
        result(@YES);
    } else {
        NSLog(@"❌ 프린터 연결 실패: %@", error.localizedDescription);
        result([FlutterError errorWithCode:@"CONNECTION_FAILED"
                                   message:error.localizedDescription ?: @"프린터 연결 실패"
                                   details:nil]);
    }
}

- (void)disconnect:(FlutterResult)result {
    NSLog(@"🔌 프린터 연결 해제");

    if (self.currentDriver) {
        [self.currentDriver disconnect];
        [self.currentDriver cleanup];
        self.currentDriver = nil;
    }

    self.connectedPrinter = nil;

    [self sendConnectionStatus:@"disconnected" message:@"" reason:[DisconnectReasonHelper codeFromReason:DisconnectReasonManualDisconnect]];

    result(@YES);
}

#pragma mark - Printing

- (void)printSingleOrder:(NSDictionary*)args result:(FlutterResult)result {
    if (!self.currentDriver) {
        result([FlutterError errorWithCode:@"NOT_CONNECTED" message:@"프린터가 연결되지 않았습니다" details:nil]);
        return;
    }

    NSLog(@"📄 단일 주문 영수증 출력 시작");

    NSError* error = nil;
    BOOL success = [self.currentDriver printSingleOrderWithData:args[@"orderData"]
                                                       storeName:args[@"storeName"]
                                                     tableNumber:args[@"tableNumber"]
                                                    storeAddress:args[@"storeAddress"]
                                                     phoneNumber:args[@"phoneNumber"]
                                                  businessNumber:args[@"businessNumber"]
                                                thankYouMessage:args[@"thankYouMessage"]
                                                        language:args[@"language"] ?: @"kor"
                                                        currency:args[@"currency"] ?: @"KRW"
                                                  showStoreLabel:[args[@"showStoreLabel"] boolValue]
                                                           error:&error];

    if (success) {
        NSLog(@"✅ 출력 완료");
        result(@YES);
    } else {
        NSLog(@"❌ 출력 실패: %@", error.localizedDescription);
        result([FlutterError errorWithCode:@"PRINT_FAIL" message:error.localizedDescription details:nil]);
    }
}

- (void)printTotalOrder:(NSDictionary*)args result:(FlutterResult)result {
    if (!self.currentDriver) {
        result([FlutterError errorWithCode:@"NOT_CONNECTED" message:@"프린터가 연결되지 않았습니다" details:nil]);
        return;
    }

    NSLog(@"📄 전체 주문 영수증 출력 시작");

    NSError* error = nil;
    BOOL success = [self.currentDriver printTotalOrderWithData:args[@"orderData"]
                                                      storeName:args[@"storeName"]
                                                    tableNumber:args[@"tableNumber"]
                                                   storeAddress:args[@"storeAddress"]
                                                    phoneNumber:args[@"phoneNumber"]
                                                 businessNumber:args[@"businessNumber"]
                                               thankYouMessage:args[@"thankYouMessage"]
                                                       language:args[@"language"] ?: @"kor"
                                                       currency:args[@"currency"] ?: @"KRW"
                                                          error:&error];

    if (success) {
        NSLog(@"✅ 출력 완료");
        result(@YES);
    } else {
        NSLog(@"❌ 출력 실패: %@", error.localizedDescription);
        result([FlutterError errorWithCode:@"PRINT_FAIL" message:error.localizedDescription details:nil]);
    }
}

- (void)printOrderFromSocket:(NSDictionary*)args result:(FlutterResult)result {
    if (!self.currentDriver) {
        result([FlutterError errorWithCode:@"NOT_CONNECTED" message:@"프린터가 연결되지 않았습니다" details:nil]);
        return;
    }

    NSLog(@"📄 주문 알림 출력 시작");

    NSString* language = args[@"language"] ?: @"kor";
    NSString* currency = args[@"currency"] ?: @"KRW";

    NSError* error = nil;
    BOOL success = [self.currentDriver printOrderFromSocketWithData:args[@"orderData"]
                                                            language:language
                                                            currency:currency
                                                               error:&error];

    if (success) {
        NSLog(@"✅ 출력 완료");
        result(@YES);
    } else {
        NSLog(@"❌ 출력 실패: %@", error.localizedDescription);
        result([FlutterError errorWithCode:@"PRINT_FAIL" message:error.localizedDescription details:nil]);
    }
}

- (void)printText:(NSDictionary*)args result:(FlutterResult)result {
    if (!self.currentDriver) {
        result([FlutterError errorWithCode:@"NOT_CONNECTED" message:@"프린터가 연결되지 않았습니다" details:nil]);
        return;
    }

    NSString* text = args[@"text"];
    if (!text) {
        result([FlutterError errorWithCode:@"INVALID_ARGUMENT" message:@"텍스트가 필요합니다" details:nil]);
        return;
    }

    NSLog(@"📄 텍스트 출력: %@", text);

    CGFloat fontSize = [args[@"fontSize"] floatValue] ?: 40.0f;
    BOOL isBold = [args[@"isBold"] boolValue];
    NSString* align = args[@"align"] ?: @"left";

    NSError* error = nil;
    BOOL success = [self.currentDriver printTextWithText:text
                                                 fontSize:fontSize
                                                   isBold:isBold
                                                    align:align
                                                    error:&error];

    if (success) {
        NSLog(@"✅ 텍스트 출력 완료");
        result(@YES);
    } else {
        NSLog(@"❌ 텍스트 출력 실패: %@", error.localizedDescription);
        result([FlutterError errorWithCode:@"PRINT_FAIL" message:error.localizedDescription details:nil]);
    }
}

#pragma mark - Connection Status

- (void)sendConnectionStatus:(NSString*)status message:(NSString*)message reason:(NSString*)reason {
    if (self.eventSink) {
        self.eventSink(@{
            @"status": status,
            @"message": message ?: @"",
            @"reason": reason ?: @""
        });
    }
}

#pragma mark - Printer Notifications

- (void)handlePrinterConnected:(NSNotification*)notification {
    NSLog(@"✅ 프린터 연결됨 (Notification)");
    [self sendConnectionStatus:@"connected" message:@"" reason:@""];
}

- (void)handlePrinterDisconnected:(NSNotification*)notification {
    NSLog(@"⚠️ 프린터 연결 해제됨 (Notification)");
    [self sendConnectionStatus:@"disconnected" message:@"" reason:[DisconnectReasonHelper codeFromReason:DisconnectReasonUnknown]];
}

@end
