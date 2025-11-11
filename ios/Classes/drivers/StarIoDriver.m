//
//  StarIoDriver.m
//  blueberry_printer
//
//  Star Micronics 프린터 드라이버 구현
//

#import "StarIoDriver.h"

// StarIO10 SDK import
@import StarIO10;

@interface StarIoDriver ()

@property (nonatomic, strong, nullable) StarPrinter* starPrinter;
@property (nonatomic, assign) BOOL isConnected;
@property (nonatomic, copy, nullable) void (^connectionStatusCallback)(NSString* status);
@property (nonatomic, strong) dispatch_queue_t connectionQueue;

@end

@implementation StarIoDriver

- (instancetype)init {
    self = [super init];
    if (self) {
        _isConnected = NO;
        _connectionQueue = dispatch_queue_create("com.blueberry.stario.connection", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)dealloc {
    [self cleanup];
}

#pragma mark - PrinterDriver Protocol

- (PrinterType)getType {
    return PrinterTypeStarMicronics;
}

- (BOOL)connectWithAddress:(NSString *)address error:(NSError **)error {
    NSLog(@"🔌 Star Micronics 프린터 연결 시작: %@", address);

    @try {
        // StarPrinter 설정
        StarConnectionSettings* settings = [[StarConnectionSettings alloc] initWithInterfaceType:InterfaceTypeBluetoothLE
                                                                                       identifier:address];
        StarPrinter* printer = [[StarPrinter alloc] initWithConnectionSettings:settings];

        __block NSError* connectionError = nil;
        __block BOOL success = NO;
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

        // 비동기 연결을 동기식으로 대기
        [printer openWithCompletion:^(NSError * _Nullable err) {
            if (err) {
                NSLog(@"❌ StarPrinter open 실패: %@", err.localizedDescription);
                connectionError = err;
                success = NO;
            } else {
                NSLog(@"✅ StarPrinter open 성공");
                success = YES;
            }
            dispatch_semaphore_signal(semaphore);
        }];

        // 10초 타임아웃
        dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC));
        long result = dispatch_semaphore_wait(semaphore, timeout);

        if (result != 0) {
            NSLog(@"❌ 프린터 연결 타임아웃");
            if (error) {
                *error = [NSError errorWithDomain:@"StarIoDriver"
                                             code:2001
                                         userInfo:@{NSLocalizedDescriptionKey: @"프린터 연결 타임아웃"}];
            }
            return NO;
        }

        if (!success) {
            if (error) {
                *error = connectionError ?: [NSError errorWithDomain:@"StarIoDriver"
                                                                code:2002
                                                            userInfo:@{NSLocalizedDescriptionKey: @"프린터 연결 실패"}];
            }
            return NO;
        }

        self.starPrinter = printer;
        self.isConnected = YES;

        NSLog(@"✅ Star Micronics 프린터 연결 성공");
        return YES;

    } @catch (NSException* exception) {
        NSLog(@"❌ 프린터 연결 예외: %@", exception.reason);
        if (error) {
            *error = [NSError errorWithDomain:@"StarIoDriver"
                                         code:2003
                                     userInfo:@{NSLocalizedDescriptionKey: exception.reason}];
        }
        return NO;
    }
}

- (BOOL)disconnect {
    NSLog(@"🔌 Star Micronics 프린터 연결 해제");

    [self stopConnectionMonitoring];

    if (self.starPrinter) {
        @try {
            __block BOOL success = YES;
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

            [self.starPrinter closeWithCompletion:^(NSError * _Nullable error) {
                if (error) {
                    NSLog(@"⚠️ 프린터 close 경고: %@", error.localizedDescription);
                    success = NO;
                }
                dispatch_semaphore_signal(semaphore);
            }];

            // 3초 대기
            dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC));
            dispatch_semaphore_wait(semaphore, timeout);

        } @catch (NSException* exception) {
            NSLog(@"⚠️ 프린터 close 예외: %@", exception.reason);
        }

        self.starPrinter = nil;
    }

    self.isConnected = NO;
    return YES;
}

- (BOOL)isConnected {
    return self.isConnected && self.starPrinter != nil;
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
            *error = [NSError errorWithDomain:@"StarIoDriver"
                                         code:2004
                                     userInfo:@{NSLocalizedDescriptionKey: @"프린터가 연결되지 않았습니다"}];
        }
        return NO;
    }

    NSLog(@"📄 단일 주문 영수증 출력 (Star Micronics)");

    @try {
        // StarXpand 명령어 빌더로 영수증 생성
        NSString* commands = [self buildSingleOrderReceipt:orderData
                                                 storeName:storeName
                                               tableNumber:tableNumber
                                              storeAddress:storeAddress
                                               phoneNumber:phoneNumber
                                            businessNumber:businessNumber
                                           thankYouMessage:thankYouMessage
                                                  language:language
                                                  currency:currency
                                            showStoreLabel:showStoreLabel];

        // 프린터로 전송
        return [self sendCommandsAndWait:commands error:error];

    } @catch (NSException* exception) {
        NSLog(@"❌ 영수증 출력 실패: %@", exception.reason);
        if (error) {
            *error = [NSError errorWithDomain:@"StarIoDriver"
                                         code:2005
                                     userInfo:@{NSLocalizedDescriptionKey: exception.reason}];
        }
        return NO;
    }
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
            *error = [NSError errorWithDomain:@"StarIoDriver"
                                         code:2004
                                     userInfo:@{NSLocalizedDescriptionKey: @"프린터가 연결되지 않았습니다"}];
        }
        return NO;
    }

    NSLog(@"📄 전체 주문 영수증 출력 (Star Micronics)");

    @try {
        // StarXpand 명령어 빌더로 영수증 생성
        NSString* commands = [self buildTotalOrderReceipt:orderData
                                                storeName:storeName
                                              tableNumber:tableNumber
                                             storeAddress:storeAddress
                                              phoneNumber:phoneNumber
                                           businessNumber:businessNumber
                                          thankYouMessage:thankYouMessage
                                                 language:language
                                                 currency:currency];

        // 프린터로 전송
        return [self sendCommandsAndWait:commands error:error];

    } @catch (NSException* exception) {
        NSLog(@"❌ 영수증 출력 실패: %@", exception.reason);
        if (error) {
            *error = [NSError errorWithDomain:@"StarIoDriver"
                                         code:2005
                                     userInfo:@{NSLocalizedDescriptionKey: exception.reason}];
        }
        return NO;
    }
}

- (BOOL)printOrderFromSocketWithData:(NSDictionary *)orderData
                            language:(NSString *)language
                            currency:(NSString *)currency
                               error:(NSError **)error {
    if (![self isConnected]) {
        NSLog(@"❌ 프린터가 연결되지 않았습니다");
        if (error) {
            *error = [NSError errorWithDomain:@"StarIoDriver"
                                         code:2004
                                     userInfo:@{NSLocalizedDescriptionKey: @"프린터가 연결되지 않았습니다"}];
        }
        return NO;
    }

    NSLog(@"📄 주문 알림 영수증 출력 (Star Micronics)");

    @try {
        // StarXpand 명령어 빌더로 소켓 알림 영수증 생성
        NSString* commands = [self buildSocketOrderReceipt:orderData
                                                  language:language
                                                  currency:currency];

        // 프린터로 전송
        return [self sendCommandsAndWait:commands error:error];

    } @catch (NSException* exception) {
        NSLog(@"❌ 영수증 출력 실패: %@", exception.reason);
        if (error) {
            *error = [NSError errorWithDomain:@"StarIoDriver"
                                         code:2005
                                     userInfo:@{NSLocalizedDescriptionKey: exception.reason}];
        }
        return NO;
    }
}

- (BOOL)printTextWithText:(NSString *)text
                 fontSize:(CGFloat)fontSize
                   isBold:(BOOL)isBold
                    align:(NSString *)align
                    error:(NSError **)error {
    if (![self isConnected]) {
        NSLog(@"❌ 프린터가 연결되지 않았습니다");
        if (error) {
            *error = [NSError errorWithDomain:@"StarIoDriver"
                                         code:2004
                                     userInfo:@{NSLocalizedDescriptionKey: @"프린터가 연결되지 않았습니다"}];
        }
        return NO;
    }

    NSLog(@"📄 텍스트 출력 (Star Micronics): %@", text);

    @try {
        StarXpandCommandBuilder* builder = [StarXpandCommandBuilder new];

        [builder addDocument:^(StarXpandCommandDocumentBuilder * _Nonnull document) {
            [document addPrinter:^(StarXpandCommandPrinterBuilder * _Nonnull printer) {
                // 정렬 설정
                Alignment alignment = AlignmentLeft;
                if ([align.uppercaseString isEqualToString:@"CENTER"]) {
                    alignment = AlignmentCenter;
                } else if ([align.uppercaseString isEqualToString:@"RIGHT"]) {
                    alignment = AlignmentRight;
                }

                [printer styleAlignment:alignment];

                // 폰트 크기 설정 (1~8)
                NSInteger fontMagnification = (NSInteger)(fontSize / 10.0);
                if (fontMagnification < 1) fontMagnification = 1;
                if (fontMagnification > 8) fontMagnification = 8;

                [printer styleMagnification:[[MagnificationParameter alloc] initWithWidth:fontMagnification height:fontMagnification]];

                // 볼드 설정
                if (isBold) {
                    [printer styleInvert:YES];
                }

                // 텍스트 출력
                [printer actionPrintText:[NSString stringWithFormat:@"%@\n", text]];

                // 스타일 초기화
                [printer styleInvert:NO];
                [printer styleAlignment:AlignmentLeft];
                [printer styleMagnification:[[MagnificationParameter alloc] initWithWidth:1 height:1]];

                // 용지 컷
                [printer actionCut:CutTypeFull];
            }];
        }];

        NSString* commands = [builder getCommands];
        return [self sendCommandsAndWait:commands error:error];

    } @catch (NSException* exception) {
        NSLog(@"❌ 텍스트 출력 실패: %@", exception.reason);
        if (error) {
            *error = [NSError errorWithDomain:@"StarIoDriver"
                                         code:2005
                                     userInfo:@{NSLocalizedDescriptionKey: exception.reason}];
        }
        return NO;
    }
}

- (void)startConnectionMonitoringWithCallback:(void (^)(NSString *status))callback {
    NSLog(@"🔍 Star Micronics 프린터 연결 모니터링 시작");
    self.connectionStatusCallback = callback;

    // StarPrinter의 delegate 패턴을 사용할 수 있지만, 현재는 기본 구현
    // TODO: StarPrinterDelegate 구현 추가
}

- (void)stopConnectionMonitoring {
    NSLog(@"🔍 Star Micronics 프린터 연결 모니터링 중지");
    self.connectionStatusCallback = nil;
}

- (void)cleanup {
    [self stopConnectionMonitoring];
    [self disconnect];
}

#pragma mark - Helper Methods

/**
 * StarXpand 명령어 전송 및 대기
 */
- (BOOL)sendCommandsAndWait:(NSString*)commands error:(NSError**)error {
    if (!self.starPrinter) {
        if (error) {
            *error = [NSError errorWithDomain:@"StarIoDriver"
                                         code:2004
                                     userInfo:@{NSLocalizedDescriptionKey: @"프린터가 연결되지 않았습니다"}];
        }
        return NO;
    }

    __block NSError* printError = nil;
    __block BOOL success = NO;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    StarXpandCommandStarXpandCommandDocumentBuilder* starPrintJob = [[StarXpandCommandStarXpandCommandDocumentBuilder alloc] init];
    [starPrintJob addRawData:[commands dataUsingEncoding:NSUTF8StringEncoding]];

    [self.starPrinter printWithCommand:commands completion:^(NSError * _Nullable err) {
        if (err) {
            NSLog(@"❌ 프린터 출력 실패: %@", err.localizedDescription);
            printError = err;
            success = NO;
        } else {
            NSLog(@"✅ 프린터 출력 성공");
            success = YES;
        }
        dispatch_semaphore_signal(semaphore);
    }];

    // 30초 타임아웃
    dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30.0 * NSEC_PER_SEC));
    long result = dispatch_semaphore_wait(semaphore, timeout);

    if (result != 0) {
        NSLog(@"❌ 프린터 출력 타임아웃");
        if (error) {
            *error = [NSError errorWithDomain:@"StarIoDriver"
                                         code:2006
                                     userInfo:@{NSLocalizedDescriptionKey: @"프린터 출력 타임아웃"}];
        }
        return NO;
    }

    if (!success && error) {
        *error = printError;
    }

    return success;
}

/**
 * 화폐 포맷팅
 */
- (NSString*)formatCurrency:(double)amount currency:(NSString*)currency {
    if ([currency isEqualToString:@"KRW"]) {
        return [NSString stringWithFormat:@"%.0f원", amount];
    } else if ([currency isEqualToString:@"USD"]) {
        return [NSString stringWithFormat:@"$%.2f", amount];
    } else if ([currency isEqualToString:@"JPY"]) {
        return [NSString stringWithFormat:@"¥%.0f", amount];
    } else {
        return [NSString stringWithFormat:@"%.2f %@", amount, currency];
    }
}

/**
 * 단일 주문 영수증 생성 (StarXpand 명령어)
 */
- (NSString*)buildSingleOrderReceipt:(NSDictionary*)orderData
                           storeName:(NSString*)storeName
                         tableNumber:(NSString*)tableNumber
                        storeAddress:(NSString*)storeAddress
                         phoneNumber:(NSString*)phoneNumber
                      businessNumber:(NSString*)businessNumber
                     thankYouMessage:(NSString*)thankYouMessage
                            language:(NSString*)language
                            currency:(NSString*)currency
                      showStoreLabel:(BOOL)showStoreLabel {

    StarXpandCommandBuilder* builder = [StarXpandCommandBuilder new];

    [builder addDocument:^(StarXpandCommandDocumentBuilder * _Nonnull document) {
        [document addPrinter:^(StarXpandCommandPrinterBuilder * _Nonnull printer) {

            // === 헤더: 점포용 라벨 ===
            if (showStoreLabel) {
                [printer styleAlignment:AlignmentCenter];
                [printer styleMagnification:[[MagnificationParameter alloc] initWithWidth:2 height:2]];
                [printer styleInvert:YES];

                NSString* label = [language isEqualToString:@"kor"] ? @" 점포용 " : @" FOR STORE ";
                [printer actionPrintText:[NSString stringWithFormat:@"%@\n", label]];

                [printer styleInvert:NO];
                [printer styleMagnification:[[MagnificationParameter alloc] initWithWidth:1 height:1]];
                [printer actionFeedLine:1];
            }

            // === 매장 정보 ===
            [printer styleAlignment:AlignmentCenter];
            [printer styleMagnification:[[MagnificationParameter alloc] initWithWidth:2 height:2]];
            [printer actionPrintText:[NSString stringWithFormat:@"%@\n", storeName]];
            [printer styleMagnification:[[MagnificationParameter alloc] initWithWidth:1 height:1]];
            [printer actionFeedLine:1];

            if (storeAddress) {
                [printer actionPrintText:[NSString stringWithFormat:@"%@\n", storeAddress]];
            }
            if (phoneNumber) {
                [printer actionPrintText:[NSString stringWithFormat:@"TEL: %@\n", phoneNumber]];
            }
            if (businessNumber) {
                [printer actionPrintText:[NSString stringWithFormat:@"BIZ NO: %@\n", businessNumber]];
            }
            [printer actionFeedLine:1];

            // === 테이블 정보 ===
            if (tableNumber) {
                [printer styleAlignment:AlignmentCenter];
                [printer styleMagnification:[[MagnificationParameter alloc] initWithWidth:2 height:2]];
                [printer actionPrintText:[NSString stringWithFormat:@"Table %@\n", tableNumber]];
                [printer styleMagnification:[[MagnificationParameter alloc] initWithWidth:1 height:1]];
                [printer actionFeedLine:1];
            }

            // === 구분선 ===
            [printer styleAlignment:AlignmentLeft];
            [printer actionPrintText:@"------------------------------------------------\n"];

            // === 주문 항목 ===
            NSArray* orderVersions = orderData[@"orderVersion"];
            if (orderVersions && orderVersions.count > 0) {
                NSDictionary* firstVersion = orderVersions[0];
                NSArray* orderItems = firstVersion[@"orderItems"];

                double subtotal = 0.0;

                for (NSDictionary* item in orderItems) {
                    NSString* menuName = item[@"menuName"] ?: @"Unknown";
                    NSInteger quantity = [item[@"quantity"] integerValue];
                    double price = [item[@"price"] doubleValue];

                    // 옵션 처리
                    double optionTotal = 0.0;
                    NSArray* options = item[@"options"];
                    if (options && options.count > 0) {
                        for (NSDictionary* option in options) {
                            NSArray* selectedItems = option[@"selectedItems"];
                            for (NSDictionary* selected in selectedItems) {
                                double itemPrice = [selected[@"itemPrice"] doubleValue];
                                NSInteger itemQuantity = [selected[@"quantity"] integerValue];
                                optionTotal += (itemPrice * itemQuantity);
                            }
                        }
                    }

                    double itemTotal = (price * quantity) + optionTotal;
                    subtotal += itemTotal;

                    // 메뉴명 + 수량 (왼쪽 정렬)
                    [printer styleAlignment:AlignmentLeft];
                    [printer actionPrintText:[NSString stringWithFormat:@"%@ x%ld\n", menuName, (long)quantity]];

                    // 가격 (오른쪽 정렬)
                    [printer styleAlignment:AlignmentRight];
                    [printer actionPrintText:[NSString stringWithFormat:@"%@\n", [self formatCurrency:itemTotal currency:currency]]];

                    // 옵션 출력
                    if (options && options.count > 0) {
                        [printer styleAlignment:AlignmentLeft];
                        for (NSDictionary* option in options) {
                            NSArray* selectedItems = option[@"selectedItems"];
                            for (NSDictionary* selected in selectedItems) {
                                NSString* itemName = selected[@"itemName"] ?: @"";
                                [printer actionPrintText:[NSString stringWithFormat:@"  + %@\n", itemName]];
                            }
                        }
                    }
                }

                // === 구분선 ===
                [printer styleAlignment:AlignmentLeft];
                [printer actionPrintText:@"------------------------------------------------\n"];

                // === 총액 ===
                [printer styleAlignment:AlignmentLeft];
                [printer styleMagnification:[[MagnificationParameter alloc] initWithWidth:2 height:2]];
                [printer actionPrintText:@"TOTAL\n"];
                [printer styleAlignment:AlignmentRight];
                [printer actionPrintText:[NSString stringWithFormat:@"%@\n", [self formatCurrency:subtotal currency:currency]]];
                [printer styleMagnification:[[MagnificationParameter alloc] initWithWidth:1 height:1]];
            }

            // === 감사 메시지 ===
            if (thankYouMessage) {
                [printer actionFeedLine:2];
                [printer styleAlignment:AlignmentCenter];
                [printer actionPrintText:[NSString stringWithFormat:@"%@\n", thankYouMessage]];
            }

            // === 용지 자르기 ===
            [printer actionFeedLine:3];
            [printer actionCut:CutTypeFull];
        }];
    }];

    return [builder getCommands];
}

/**
 * 전체 주문 영수증 생성 (누적 데이터)
 */
- (NSString*)buildTotalOrderReceipt:(NSDictionary*)orderData
                          storeName:(NSString*)storeName
                        tableNumber:(NSString*)tableNumber
                       storeAddress:(NSString*)storeAddress
                        phoneNumber:(NSString*)phoneNumber
                     businessNumber:(NSString*)businessNumber
                    thankYouMessage:(NSString*)thankYouMessage
                           language:(NSString*)language
                           currency:(NSString*)currency {

    StarXpandCommandBuilder* builder = [StarXpandCommandBuilder new];

    [builder addDocument:^(StarXpandCommandDocumentBuilder * _Nonnull document) {
        [document addPrinter:^(StarXpandCommandPrinterBuilder * _Nonnull printer) {

            // === 매장 정보 ===
            [printer styleAlignment:AlignmentCenter];
            [printer styleMagnification:[[MagnificationParameter alloc] initWithWidth:2 height:2]];
            [printer actionPrintText:[NSString stringWithFormat:@"%@\n", storeName]];
            [printer styleMagnification:[[MagnificationParameter alloc] initWithWidth:1 height:1]];
            [printer actionFeedLine:1];

            if (storeAddress) {
                [printer actionPrintText:[NSString stringWithFormat:@"%@\n", storeAddress]];
            }
            if (phoneNumber) {
                [printer actionPrintText:[NSString stringWithFormat:@"TEL: %@\n", phoneNumber]];
            }
            if (businessNumber) {
                [printer actionPrintText:[NSString stringWithFormat:@"BIZ NO: %@\n", businessNumber]];
            }
            [printer actionFeedLine:1];

            // === 테이블 정보 ===
            if (tableNumber) {
                [printer styleAlignment:AlignmentCenter];
                [printer styleMagnification:[[MagnificationParameter alloc] initWithWidth:2 height:2]];
                [printer actionPrintText:[NSString stringWithFormat:@"Table %@\n", tableNumber]];
                [printer styleMagnification:[[MagnificationParameter alloc] initWithWidth:1 height:1]];
                [printer actionFeedLine:1];
            }

            // === 구분선 ===
            [printer styleAlignment:AlignmentLeft];
            [printer actionPrintText:@"------------------------------------------------\n"];

            // === 누적 주문 항목 (orderMenus) ===
            NSArray* orderMenus = orderData[@"orderMenus"];
            double totalPrice = [orderData[@"totalPrice"] doubleValue];

            if (orderMenus && orderMenus.count > 0) {
                for (NSDictionary* menu in orderMenus) {
                    NSString* menuName = menu[@"menuName"] ?: @"Unknown";
                    NSInteger quantity = [menu[@"quantity"] integerValue];
                    double price = [menu[@"price"] doubleValue];

                    // 옵션 가격 계산
                    double optionTotal = 0.0;
                    NSArray* menuOptionItems = menu[@"menuOptionItems"];
                    if (menuOptionItems && menuOptionItems.count > 0) {
                        for (NSDictionary* optionGroup in menuOptionItems) {
                            NSArray* selectedItems = optionGroup[@"selectedItems"];
                            for (NSDictionary* selected in selectedItems) {
                                double itemPrice = [selected[@"menuOptionItemDetailPrice"] doubleValue];
                                NSInteger itemQuantity = [selected[@"menuOptionItemDetailQuantity"] integerValue];
                                optionTotal += (itemPrice * itemQuantity);
                            }
                        }
                    }

                    double itemTotal = price + optionTotal;

                    // 메뉴명 + 수량 (왼쪽 정렬)
                    [printer styleAlignment:AlignmentLeft];
                    [printer actionPrintText:[NSString stringWithFormat:@"%@ x%ld\n", menuName, (long)quantity]];

                    // 가격 (오른쪽 정렬)
                    [printer styleAlignment:AlignmentRight];
                    [printer actionPrintText:[NSString stringWithFormat:@"%@\n", [self formatCurrency:itemTotal currency:currency]]];

                    // 옵션 출력
                    if (menuOptionItems && menuOptionItems.count > 0) {
                        [printer styleAlignment:AlignmentLeft];
                        for (NSDictionary* optionGroup in menuOptionItems) {
                            NSArray* selectedItems = optionGroup[@"selectedItems"];
                            for (NSDictionary* selected in selectedItems) {
                                NSString* itemName = selected[@"menuOptionItemDetailName"] ?: @"";
                                [printer actionPrintText:[NSString stringWithFormat:@"  + %@\n", itemName]];
                            }
                        }
                    }
                }
            }

            // === 구분선 ===
            [printer styleAlignment:AlignmentLeft];
            [printer actionPrintText:@"------------------------------------------------\n"];

            // === 총액 ===
            [printer styleAlignment:AlignmentLeft];
            [printer styleMagnification:[[MagnificationParameter alloc] initWithWidth:2 height:2]];
            [printer actionPrintText:@"TOTAL\n"];
            [printer styleAlignment:AlignmentRight];
            [printer actionPrintText:[NSString stringWithFormat:@"%@\n", [self formatCurrency:totalPrice currency:currency]]];
            [printer styleMagnification:[[MagnificationParameter alloc] initWithWidth:1 height:1]];

            // === 감사 메시지 ===
            if (thankYouMessage) {
                [printer actionFeedLine:2];
                [printer styleAlignment:AlignmentCenter];
                [printer actionPrintText:[NSString stringWithFormat:@"%@\n", thankYouMessage]];
            }

            // === 용지 자르기 ===
            [printer actionFeedLine:3];
            [printer actionCut:CutTypeFull];
        }];
    }];

    return [builder getCommands];
}

/**
 * 소켓 주문 알림 영수증 생성
 */
- (NSString*)buildSocketOrderReceipt:(NSDictionary*)orderData
                            language:(NSString*)language
                            currency:(NSString*)currency {

    StarXpandCommandBuilder* builder = [StarXpandCommandBuilder new];

    [builder addDocument:^(StarXpandCommandDocumentBuilder * _Nonnull document) {
        [document addPrinter:^(StarXpandCommandPrinterBuilder * _Nonnull printer) {

            // === 헤더 ===
            [printer styleAlignment:AlignmentCenter];
            [printer styleMagnification:[[MagnificationParameter alloc] initWithWidth:3 height:3]];

            NSString* header = [language isEqualToString:@"kor"] ? @"새 주문" : @"NEW ORDER";
            [printer actionPrintText:[NSString stringWithFormat:@"%@\n", header]];

            [printer styleMagnification:[[MagnificationParameter alloc] initWithWidth:1 height:1]];
            [printer actionFeedLine:2];

            // === 주문 정보 ===
            NSString* orderNumber = orderData[@"orderNumber"] ?: @"";
            NSString* tableName = orderData[@"tableName"] ?: @"";

            if (orderNumber.length > 0) {
                [printer styleAlignment:AlignmentCenter];
                [printer styleMagnification:[[MagnificationParameter alloc] initWithWidth:2 height:2]];
                [printer actionPrintText:[NSString stringWithFormat:@"#%@\n", orderNumber]];
                [printer styleMagnification:[[MagnificationParameter alloc] initWithWidth:1 height:1]];
            }

            if (tableName.length > 0) {
                [printer styleAlignment:AlignmentCenter];
                [printer styleMagnification:[[MagnificationParameter alloc] initWithWidth:2 height:2]];
                [printer actionPrintText:[NSString stringWithFormat:@"%@\n", tableName]];
                [printer styleMagnification:[[MagnificationParameter alloc] initWithWidth:1 height:1]];
                [printer actionFeedLine:1];
            }

            // === 구분선 ===
            [printer styleAlignment:AlignmentLeft];
            [printer actionPrintText:@"================================================\n"];

            // === 주문 항목 ===
            NSArray* orderItems = orderData[@"orderItems"];
            if (orderItems && orderItems.count > 0) {
                for (NSDictionary* item in orderItems) {
                    NSString* menuName = item[@"menuName"] ?: @"Unknown";
                    NSInteger quantity = [item[@"quantity"] integerValue];

                    [printer styleAlignment:AlignmentLeft];
                    [printer styleMagnification:[[MagnificationParameter alloc] initWithWidth:2 height:2]];
                    [printer actionPrintText:[NSString stringWithFormat:@"%@ x%ld\n", menuName, (long)quantity]];
                    [printer styleMagnification:[[MagnificationParameter alloc] initWithWidth:1 height:1]];

                    // 옵션 출력
                    NSArray* options = item[@"options"];
                    if (options && options.count > 0) {
                        for (NSDictionary* option in options) {
                            NSArray* selectedItems = option[@"selectedItems"];
                            for (NSDictionary* selected in selectedItems) {
                                NSString* itemName = selected[@"itemName"] ?: @"";
                                [printer actionPrintText:[NSString stringWithFormat:@"  + %@\n", itemName]];
                            }
                        }
                    }
                    [printer actionFeedLine:1];
                }
            }

            // === 용지 자르기 ===
            [printer actionFeedLine:2];
            [printer actionCut:CutTypeFull];
        }];
    }];

    return [builder getCommands];
}

@end
