//
//  RealtimeConnectionChecker.m
//  blueberry_printer
//
//  프린터 연결 상태를 실시간으로 모니터링하는 클래스
//

#import "RealtimeConnectionChecker.h"

// ESC/POS 명령어: DLE EOT n (프린터 상태 확인)
static const Byte STATUS_CHECK_COMMAND[] = {0x10, 0x04, 0x01}; // DLE EOT 1

@interface RealtimeConnectionChecker()

@property (nonatomic, strong) PrinterSDK* printerSDK;
@property (nonatomic, copy) ConnectionLostCallback onConnectionLost;
@property (nonatomic, copy, nullable) ConnectionRestoredCallback onConnectionRestored;
@property (nonatomic, assign) BOOL isRunning;
@property (nonatomic, assign) BOOL isConnected;

@end

@implementation RealtimeConnectionChecker

- (instancetype)initWithPrinterSDK:(PrinterSDK*)printerSDK
                onConnectionLost:(ConnectionLostCallback)onConnectionLost
            onConnectionRestored:(ConnectionRestoredCallback)onConnectionRestored {
    self = [super init];
    if (self) {
        _printerSDK = printerSDK;
        _onConnectionLost = [onConnectionLost copy];
        _onConnectionRestored = [onConnectionRestored copy];
        _isRunning = NO;
        _isConnected = YES;

        // PrinterSDK 알림 리스너 등록
        [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(printerDidDisconnect:)
                                                   name:PrinterDisconnectedNotification
                                                 object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(printerDidConnect:)
                                                   name:PrinterConnectedNotification
                                                 object:nil];
    }
    return self;
}

- (void)startChecking {
    if (self.isRunning) {
        NSLog(@"⚠️ RealtimeConnectionChecker is already running");
        return;
    }

    self.isRunning = YES;
    self.isConnected = YES;

    NSLog(@"✅ RealtimeConnectionChecker started (notification-based)");
}

- (void)stopChecking {
    if (!self.isRunning) {
        return;
    }

    self.isRunning = NO;

    NSLog(@"🛑 RealtimeConnectionChecker stopped");
}

- (BOOL)isConnected {
    return self.isConnected;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopChecking];
}

#pragma mark - Private Methods

#pragma mark - Notification Handlers

- (void)printerDidConnect:(NSNotification*)notification {
    if (!self.isRunning) return;

    NSLog(@"✅ Printer connected notification received");
    [self handleConnectionRestored];
}

- (void)printerDidDisconnect:(NSNotification*)notification {
    if (!self.isRunning) return;

    NSLog(@"⚠️ Printer disconnected notification received");
    [self handleConnectionLost:DisconnectReasonPrinterOffline];
}

- (void)handleConnectionLost:(DisconnectReason)reason {
    if (self.isConnected) {
        self.isConnected = NO;
        NSLog(@"⚠️ Connection lost: %@", [DisconnectReasonHelper codeFromReason:reason]);

        if (self.onConnectionLost) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.onConnectionLost(reason);
            });
        }
    }
}

- (void)handleConnectionRestored {
    if (!self.isConnected) {
        self.isConnected = YES;
        NSLog(@"✅ Connection restored");

        if (self.onConnectionRestored) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.onConnectionRestored();
            });
        }
    }
}

@end
