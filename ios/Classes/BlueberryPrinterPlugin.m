//
//  BlueberryPrinterPlugin.m
//  blueberry_printer
//
//  Created for Flutter plugin (리팩토링 버전)
//

#import "BlueberryPrinterPlugin.h"
#import "single_order/SingleOrderDirectPrinter.h"
#import "multiple_order/MultipleOrderDirectPrinter.h"
#import "order_notification/OrderNotificationPrinter.h"
#import "common/DisconnectReason.h"
#import "common/KoreanTextRenderer.h"
#import "common/PrinterCommands.h"
#import "common/PrinterUtilities.h"
#import "common/EscPosConstants.h"

@interface BlueberryPrinterPlugin () <FlutterStreamHandler>
{
    NSMutableDictionary* _discoveredPrinters;
    FlutterResult _scanCallback;
    PrinterSDK* _printerSDK;
    BOOL _isScanning;
}

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
    
    self.connectedPrinter = printer;
    [_printerSDK connectBT:printer];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"✅ 프린터 연결 완료");
        [self sendConnectionStatus:@"connected" message:@"" reason:@""];
        result(@YES);
    });
}

- (void)disconnect:(FlutterResult)result {
    NSLog(@"🔌 프린터 연결 해제");
    
    [_printerSDK disconnect];
    self.connectedPrinter = nil;
    
    [self sendConnectionStatus:@"disconnected" message:@"" reason:[DisconnectReasonHelper codeFromReason:DisconnectReasonManualDisconnect]];
    
    result(@YES);
}

#pragma mark - Printing

- (void)printSingleOrder:(NSDictionary*)args result:(FlutterResult)result {
    if (!_printerSDK) {
        result([FlutterError errorWithCode:@"NOT_CONNECTED" message:@"프린터가 연결되지 않았습니다" details:nil]);
        return;
    }
    
    NSLog(@"📄 단일 주문 영수증 출력 시작");
    
    NSError* error = nil;
    BOOL success = [SingleOrderDirectPrinter printOrder:args[@"orderData"]
                                              storeName:args[@"storeName"]
                                           storeAddress:args[@"storeAddress"]
                                            phoneNumber:args[@"phoneNumber"]
                                         businessNumber:args[@"businessNumber"]
                                        thankYouMessage:args[@"thankYouMessage"]
                                               language:args[@"language"] ?: @"kor"
                                               currency:args[@"currency"] ?: @"KRW"
                                            tableNumber:args[@"tableNumber"]
                                         showStoreLabel:[args[@"showStoreLabel"] boolValue]
                                             printerSDK:_printerSDK
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
    if (!_printerSDK) {
        result([FlutterError errorWithCode:@"NOT_CONNECTED" message:@"프린터가 연결되지 않았습니다" details:nil]);
        return;
    }

    NSLog(@"📄 전체 주문 영수증 출력 시작");

    NSError* error = nil;
    BOOL success = [MultipleOrderDirectPrinter printOrder:args[@"orderData"]
                                                storeName:args[@"storeName"]
                                             storeAddress:args[@"storeAddress"]
                                              phoneNumber:args[@"phoneNumber"]
                                           businessNumber:args[@"businessNumber"]
                                          thankYouMessage:args[@"thankYouMessage"]
                                                 language:args[@"language"] ?: @"kor"
                                                 currency:args[@"currency"] ?: @"KRW"
                                              tableNumber:args[@"tableNumber"]
                                               printerSDK:_printerSDK
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
    if (!_printerSDK) {
        result([FlutterError errorWithCode:@"NOT_CONNECTED" message:@"프린터가 연결되지 않았습니다" details:nil]);
        return;
    }

    NSLog(@"📄 주문 알림 출력 시작");

    NSString* language = args[@"language"] ?: @"kor";
    NSString* currency = args[@"currency"] ?: @"KRW";

    NSError* error = nil;
    BOOL success = [OrderNotificationPrinter printNotification:args[@"orderData"]
                                                       language:language
                                                       currency:currency
                                                     printerSDK:_printerSDK
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
    if (!_printerSDK) {
        result([FlutterError errorWithCode:@"NOT_CONNECTED" message:@"프린터가 연결되지 않았습니다" details:nil]);
        return;
    }

    NSString* text = args[@"text"];
    if (!text) {
        result([FlutterError errorWithCode:@"INVALID_ARGUMENT" message:@"텍스트가 필요합니다" details:nil]);
        return;
    }

    NSLog(@"📄 텍스트 출력: %@", text);

    @try {
        // 프린터 초기화
        NSData* initCommand = [PrinterCommands POS_Set_PrtInit];
        [_printerSDK sendHex:[PrinterUtilities dataToHexString:initCommand]];

        // 텍스트를 이미지로 렌더링하여 출력
        UIImage* image = [KoreanTextRenderer createTextImage:text
                                                     textSize:40.0f
                                                       isBold:NO
                                                        align:TextAlignLeft];
        NSData* bitmap = [KoreanTextRenderer convertToBitmap:image];
        NSString* hexString = [PrinterUtilities dataToHexString:bitmap];
        [_printerSDK sendHex:hexString];

        // 줄바꿈 및 용지 자르기
        NSData* feedCommand = [PrinterCommands POS_Set_PrtAndFeedPaper:100];
        [_printerSDK sendHex:[PrinterUtilities dataToHexString:feedCommand]];

        NSData* cutCommand = [EscPosConstants GS_V_n];
        [_printerSDK sendHex:[PrinterUtilities dataToHexString:cutCommand]];

        result(@YES);
    } @catch (NSException* exception) {
        NSLog(@"❌ 텍스트 출력 실패: %@", exception.reason);
        result([FlutterError errorWithCode:@"PRINT_FAIL" message:exception.reason details:nil]);
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
