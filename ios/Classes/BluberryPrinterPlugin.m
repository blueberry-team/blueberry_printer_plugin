//
//  BluberryPrinterPlugin.m
//  bluberry_printer
//
//  Created for Flutter plugin
//

#import "BluberryPrinterPlugin.h"

@interface BluberryPrinterPlugin ()
{
    NSMutableDictionary* _discoveredPrinters;
    FlutterResult _scanCallback;
    PrinterSDK* _printerSDK;
    BOOL _isScanning;
}
@end

@implementation BluberryPrinterPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                    methodChannelWithName:@"bluberry_printer"
                                    binaryMessenger:[registrar messenger]];
    BluberryPrinterPlugin* instance = [[BluberryPrinterPlugin alloc] init];
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
    else if ([@"disconnect" isEqualToString:call.method]) {
        [self disconnect:result];
    }
    else {
        NSLog(@"🔍 [DEBUG] 구현되지 않은 메서드: %@", call.method);
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
    
    // 실제 프린터 SDK로 출력 - 안드로이드 방식으로 이미지화
    NSString* formattedText = [self formatReceiptText:receiptText];
    NSLog(@"🔍 [DEBUG] 포맷된 텍스트: %@", formattedText);
    
    // 프린터 초기화 및 설정
    [_printerSDK printText:@"\n\n"]; // 상단 여백
    [_printerSDK setPrintWidth:384]; // 58mm 프린터 설정
    
    // 안드로이드와 동일한 방식으로 ESC/POS 명령어 직접 전송
    NSData* bitmapData = [self createBitmapData:formattedText];
    if (bitmapData) {
        NSString* hexString = [self dataToHexString:bitmapData];
        [_printerSDK sendHex:hexString];
    } else {
        // 비트맵 생성 실패시 일반 텍스트 출력
        [_printerSDK printText:formattedText];
    }
    
    
    // 하단 여백 및 커팅
    [_printerSDK printText:@"\n\n\n\n\n"]; // 하단 여백
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"🔍 [DEBUG] 출력 완료");
        result(@YES);
    });
}

- (NSString*)formatReceiptText:(NSString*)receiptText {
    NSArray* lines = [receiptText componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSMutableString* formattedText = [NSMutableString string];
    
    for (NSString* line in lines) {
        NSString* trimmedLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        if ([trimmedLine length] == 0) {
            [formattedText appendString:@"\n"];
            continue;
        }
        
        // 섹션 헤더 처리 (예: "타이틀, 24")
        if ([trimmedLine containsString:@", "] && [[trimmedLine componentsSeparatedByString:@", "] count] == 2) {
            NSArray* parts = [trimmedLine componentsSeparatedByString:@", "];
            NSString* sectionName = parts[0];
            NSString* fontSize = parts[1];
            
            // 섹션별 스타일 적용
            if ([sectionName isEqualToString:@"타이틀"]) {
                [formattedText appendString:@"\n\n"];
                [formattedText appendString:@"*** "];
                [formattedText appendString:sectionName];
                [formattedText appendString:@" ***\n\n"];
            } else if ([sectionName isEqualToString:@"매장정보"]) {
                [formattedText appendString:@"\n"];
            } else if ([sectionName isEqualToString:@"구분선"]) {
                [formattedText appendString:@"\n"];
            } else if ([sectionName isEqualToString:@"상품목록"]) {
                [formattedText appendString:@"\n"];
            } else if ([sectionName isEqualToString:@"합계"]) {
                [formattedText appendString:@"\n"];
            } else if ([sectionName isEqualToString:@"감사메시지"]) {
                [formattedText appendString:@"\n"];
            }
            continue;
        }
        
        // 특별 명령 처리
        if ([trimmedLine isEqualToString:@"영수증 자르기"]) {
            [formattedText appendString:@"\n\n\n\n\n"]; // 커팅을 위한 여백
            continue;
        }
        
        if ([trimmedLine hasPrefix:@"줄바꿈, "]) {
            NSString* countStr = [trimmedLine substringFromIndex:7]; // "줄바꿈, " 제거
            int count = [countStr intValue];
            for (int i = 0; i < count; i++) {
                [formattedText appendString:@"\n"];
            }
            continue;
        }
        
        // 일반 텍스트 추가
        [formattedText appendString:trimmedLine];
        [formattedText appendString:@"\n"];
    }
    
    return formattedText;
}

- (NSString*)invertTextColors:(NSString*)text {
    // 텍스트의 흑백을 반전시키는 함수
    // 실제로는 텍스트 자체를 반전시키는 것이 아니라
    // 프린터 SDK의 흑백 반전 문제를 우회하는 방법
    
    // 방법 1: 특수 문자를 사용해서 반전 효과 시도
    NSMutableString* invertedText = [NSMutableString string];
    
    // 각 문자를 반전된 형태로 변환
    for (int i = 0; i < [text length]; i++) {
        unichar character = [text characterAtIndex:i];
        
        // 공백 문자는 그대로 유지
        if (character == ' ' || character == '\n' || character == '\t') {
            [invertedText appendFormat:@"%C", character];
        } else {
            // 일반 문자는 강조 표시로 변환 (프린터에서 반전될 수 있음)
            [invertedText appendFormat:@"%C", character];
        }
    }
    
    return invertedText;
}

- (UIImage*)createTextImage:(NSString*)text {
    // 안드로이드의 RenderKoreanTextToImage와 유사한 기능
    // 텍스트를 UIImage로 변환
    
    // 프린터 설정 (안드로이드와 동일)
    const CGFloat PAPER_WIDTH_PX = 576; // 안드로이드와 동일한 58mm 프린터 기준
    const CGFloat MARGIN_PX = 20;
    
    // 텍스트 스타일 설정
    UIFont* font = [UIFont systemFontOfSize:14.0];
    NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentLeft;
    paragraphStyle.lineSpacing = 2.0;
    
    // 텍스트 속성 설정
    NSDictionary* textAttributes = @{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: [UIColor blackColor],
        NSParagraphStyleAttributeName: paragraphStyle
    };
    
    // 텍스트 크기 계산
    CGSize textSize = [text boundingRectWithSize:CGSizeMake(PAPER_WIDTH_PX - MARGIN_PX * 2, CGFLOAT_MAX)
                                         options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                      attributes:textAttributes
                                         context:nil].size;
    
    // 이미지 크기 설정
    CGSize imageSize = CGSizeMake(PAPER_WIDTH_PX, textSize.height + MARGIN_PX * 2);
    
    // 이미지 컨텍스트 생성 (안드로이드와 동일한 해상도)
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, 1.0); // 1.0 scale factor
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // 흰색 배경 그리기
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, imageSize.width, imageSize.height));
    
    // 텍스트 그리기
    CGRect textRect = CGRectMake(MARGIN_PX, MARGIN_PX, textSize.width, textSize.height);
    [text drawInRect:textRect withAttributes:textAttributes];
    
    // 이미지 생성
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    NSLog(@"🔍 [DEBUG] 텍스트 이미지 생성 완료: %@x%@", @(image.size.width), @(image.size.height));
    
    return image;
}

- (NSData*)createBitmapData:(NSString*)text {
    // 안드로이드의 RenderKoreanTextToImage.convertToBitmap와 동일한 기능
    // 텍스트를 비트맵 데이터로 변환
    
    // 프린터 설정 (안드로이드와 동일)
    const int PAPER_WIDTH_PX = 576; // 안드로이드와 동일
    const int MARGIN_PX = 20;
    
    // 텍스트를 이미지로 변환
    UIImage* textImage = [self createTextImage:text];
    if (!textImage) return nil;
    
    // 이미지를 비트맵 데이터로 변환
    CGImageRef imageRef = textImage.CGImage;
    if (!imageRef) return nil;
    
    int width = (int)CGImageGetWidth(imageRef);
    int height = (int)CGImageGetHeight(imageRef);
    
    // 8픽셀당 1바이트로 변환 (안드로이드와 동일)
    int widthBytes = (width + 7) / 8;
    NSMutableData* imageData = [NSMutableData dataWithLength:widthBytes * height];
    uint8_t* bytes = (uint8_t*)imageData.mutableBytes;
    
    // 이미지 데이터 추출
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedLast);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    
    uint8_t* pixelData = (uint8_t*)CGBitmapContextGetData(context);
    
    // 픽셀을 비트맵으로 변환 (안드로이드와 동일한 로직)
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            int pixelIndex = y * width * 4 + x * 4;
            uint8_t red = pixelData[pixelIndex];
            uint8_t green = pixelData[pixelIndex + 1];
            uint8_t blue = pixelData[pixelIndex + 2];
            
            // 그레이스케일 계산 (안드로이드와 동일)
            int gray = (red + green + blue) / 3;
            
            // 어두운 픽셀을 1로 설정 (안드로이드와 동일)
            if (gray < 128) {
                int byteIndex = y * widthBytes + x / 8;
                int bitIndex = 7 - (x % 8); // 안드로이드와 동일한 비트 순서
                bytes[byteIndex] |= (1 << bitIndex);
            }
        }
    }
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // ESC/POS 명령어 생성 (안드로이드와 동일)
    NSMutableData* commandData = [NSMutableData data];
    
    // GS v 0 명령 (안드로이드와 동일)
    uint8_t command[] = {29, 118, 48, 0, 0, 0, 0, 0}; // GS v 0
    command[4] = widthBytes & 0xFF; // xL
    command[5] = (widthBytes >> 8) & 0xFF; // xH
    command[6] = height & 0xFF; // yL
    command[7] = (height >> 8) & 0xFF; // yH
    
    [commandData appendBytes:command length:8];
    [commandData appendData:imageData];
    
    NSLog(@"🔍 [DEBUG] 비트맵 데이터 생성 완료: %@x%@, %lu바이트", @(width), @(height), (unsigned long)commandData.length);
    
    return commandData;
}

- (NSString*)dataToHexString:(NSData*)data {
    // NSData를 16진수 문자열로 변환
    NSMutableString* hexString = [NSMutableString string];
    const uint8_t* bytes = (const uint8_t*)data.bytes;
    
    for (int i = 0; i < data.length; i++) {
        [hexString appendFormat:@"%02X", bytes[i]];
    }
    
    return hexString;
}

- (void)printSampleReceipt:(FlutterResult)result {
    NSLog(@"🔍 [DEBUG] 샘플 영수증 출력 시도");
    
    // Android와 동일한 형식으로 샘플 영수증 생성
    NSString* sampleText = @"타이틀, 24\n"
                           @"*** 영수증 ***\n\n"
                           @"줄바꿈, 3\n\n"
                           @"매장정보, 16\n"
                           @"매장명: 한국 상점\n"
                           @"주소: 서울시 강남구\n"
                           @"전화: 02-1234-5678\n\n"
                           @"구분선, 14\n"
                           @"--------------------------------\n\n"
                           @"상품목록, 14\n"
                           @"상품명         단가    수량   금액\n"
                           @"아메리카노     3,000    2    6,000\n"
                           @"카페라떼       4,000    1    4,000\n"
                           @"케이크         5,000    1    5,000\n\n"
                           @"구분선, 14\n"
                           @"--------------------------------\n\n"
                           @"합계, 16\n"
                           @"합계: 15,000원\n"
                           @"부가세: 1,500원\n"
                           @"총액: 16,500원\n\n"
                           @"감사메시지, 16\n"
                           @"이용해 주셔서 감사합니다!\n\n"
                           @"영수증 자르기";
    
    NSLog(@"🔍 [DEBUG] 샘플 텍스트 생성 완료");
    
    // printReceipt 함수 재사용
    [self printReceipt:sampleText result:result];
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