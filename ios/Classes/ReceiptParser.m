//
//  ReceiptParser.m
//  blueberry_printer
//
//  Created for Flutter plugin
//

#import "ReceiptParser.h"

@implementation ReceiptParser

// 영수증 텍스트를 파싱하고 비트맵 데이터로 변환
+ (NSData*)parseReceiptText:(NSString*)receiptText {
    NSLog(@"🔍 [DEBUG] 영수증 파싱 시작: %@", receiptText);
    NSLog(@"🔍 [DEBUG] 영수증 텍스트 길이: %lu", (unsigned long)receiptText.length);
    
    // 프린터 설정 (안드로이드와 동일)
    const int PAPER_WIDTH_PX = 576; // 안드로이드와 동일
    const int MARGIN_PX = 20;
    
    // ESC/POS 명령어 생성
    NSMutableData* commandData = [NSMutableData data];
    
    // 프린터 초기화 명령 (ESC @)
    uint8_t initCommand[] = {27, 64}; // ESC @
    [commandData appendBytes:initCommand length:2];
    
    // 텍스트를 라인별로 분리
    NSArray* lines = [receiptText componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSLog(@"🔍 [DEBUG] 총 라인 수: %lu", (unsigned long)lines.count);
    
    for (int i = 0; i < lines.count; i++) {
        NSString* line = [lines[i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSLog(@"🔍 [DEBUG] 처리 중인 라인 %d: '%@'", i, line);
        
        if (line.length == 0) {
            NSLog(@"🔍 [DEBUG] 빈 라인 건너뛰기");
            continue;
        }
        
        if ([line isEqualToString:@"영수증 자르기"]) {
            // 영수증 자르기 명령
            uint8_t cutCommand[] = {29, 86, 66, 0}; // GS V B
            [commandData appendBytes:cutCommand length:4];
            NSLog(@"🔍 [DEBUG] 영수증 자르기 완료");
            continue;
        }
        
        if ([line containsString:@", "] && [[line componentsSeparatedByString:@", "] count] == 2) {
            // 섹션 헤더 (예: "타이틀, 24")
            NSArray* parts = [line componentsSeparatedByString:@", "];
            NSString* sectionName = parts[0];
            CGFloat fontSize = [parts[1] floatValue];
            if (fontSize == 0) fontSize = 16.0;
            
            NSLog(@"🔍 [DEBUG] 섹션 처리 시작: %@, 크기: %.1f", sectionName, fontSize);
            
            // 다음 줄부터 해당 섹션의 내용 수집
            i++;
            NSMutableArray* contentLines = [NSMutableArray array];
            
            while (i < lines.count) {
                NSString* contentLine = [lines[i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                if (contentLine.length == 0 || 
                    ([contentLine containsString:@", "] && [[contentLine componentsSeparatedByString:@", "] count] == 2) ||
                    [contentLine isEqualToString:@"영수증 자르기"]) {
                    break;
                }
                [contentLines addObject:contentLine];
                i++;
            }
            i--; // 다음 반복에서 올바른 줄을 처리하기 위해
            
            if (contentLines.count > 0) {
                NSString* content = [contentLines componentsJoinedByString:@"\n"];
                NSLog(@"🔍 [DEBUG] 섹션 내용: '%@'", content);
                
                // 섹션별 기본 설정 (안드로이드와 동일)
                BOOL isBold = NO;
                TextAlign align = TextAlignLeft;
                
                if ([sectionName isEqualToString:@"타이틀"]) {
                    isBold = YES;
                    align = TextAlignCenter;
                    // fontSize는 이미 파싱된 값을 사용
                } else if ([sectionName isEqualToString:@"매장정보"]) {
                    align = TextAlignCenter;
                    // fontSize는 이미 파싱된 값을 사용
                } else if ([sectionName isEqualToString:@"구분선"]) {
                    align = TextAlignCenter;
                    // fontSize는 이미 파싱된 값을 사용
                } else if ([sectionName isEqualToString:@"상품목록"]) {
                    align = TextAlignLeft;
                    // fontSize는 이미 파싱된 값을 사용
                } else if ([sectionName isEqualToString:@"합계"]) {
                    isBold = YES;
                    align = TextAlignRight;
                    // fontSize는 이미 파싱된 값을 사용
                } else if ([sectionName isEqualToString:@"감사메시지"]) {
                    align = TextAlignCenter;
                    // fontSize는 이미 파싱된 값을 사용
                }
                
                NSLog(@"🔍 [DEBUG] 이미지 생성 시작: 굵기=%d, 정렬=%ld, 크기=%.1f", isBold, (long)align, fontSize);
                
                UIImage* image = [self createTextImage:content fontSize:fontSize isBold:isBold align:align];
                if (image) {
                    NSLog(@"🔍 [DEBUG] 이미지 생성 완료: %@x%@", @(image.size.width), @(image.size.height));
                    
                    NSData* bitmapData = [self createBitmapData:image];
                    if (bitmapData) {
                        NSLog(@"🔍 [DEBUG] 비트맵 변환 완료: %lu바이트", (unsigned long)bitmapData.length);
                        [commandData appendData:bitmapData];
                        NSLog(@"🔍 [DEBUG] 섹션 출력 완료: %@", sectionName);
                    }
                }
            } else {
                NSLog(@"🔍 [DEBUG] 섹션 내용이 비어있음: %@", sectionName);
            }
        } else if ([line hasPrefix:@"줄바꿈, "]) {
            // 줄바꿈 명령 (예: "줄바꿈, 3")
            NSString* countStr = [line substringFromIndex:7]; // "줄바꿈, " 제거
            int feedLines = [countStr intValue];
            if (feedLines <= 0) feedLines = 1;
            
            // ESC J 명령 (줄바꿈)
            uint8_t feedCommand[] = {27, 74, feedLines}; // ESC J n
            [commandData appendBytes:feedCommand length:3];
        } else {
            NSLog(@"🔍 [DEBUG] 알 수 없는 라인 형식: '%@'", line);
        }
    }
    
    NSLog(@"🔍 [DEBUG] 영수증 파싱 완료");
    return commandData;
}

// 텍스트를 이미지로 변환 (안드로이드와 동일한 방식)
+ (UIImage*)createTextImage:(NSString*)text 
                   fontSize:(CGFloat)fontSize 
                    isBold:(BOOL)isBold 
                      align:(TextAlign)align {
    
    // 프린터 설정 (안드로이드와 동일)
    const CGFloat PAPER_WIDTH_PX = 576; // 안드로이드와 동일한 58mm 프린터 기준
    const CGFloat MARGIN_PX = 20;
    
    // 폰트 설정 (안드로이드와 동일)
    UIFont* font = isBold ? [UIFont boldSystemFontOfSize:fontSize] : [UIFont systemFontOfSize:fontSize];
    
    // 라인별로 분리 (안드로이드와 동일)
    NSArray* lines = [text componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    // 폰트 메트릭스 계산 (안드로이드와 동일)
    CGFloat lineHeight = font.lineHeight;
    CGFloat totalHeight = lineHeight * lines.count + MARGIN_PX * 2;
    
    // 이미지 크기 설정 (안드로이드와 동일)
    CGSize imageSize = CGSizeMake(PAPER_WIDTH_PX, totalHeight);
    
    // 이미지 컨텍스트 생성 (안드로이드와 동일한 해상도)
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, 1.0); // 1.0 scale factor
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // 흰색 배경 그리기
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, imageSize.width, imageSize.height));
    
    // 텍스트 속성 설정
    NSDictionary* textAttributes = @{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: [UIColor blackColor]
    };
    
    // 각 라인을 개별적으로 그리기 (안드로이드와 동일한 방식)
    CGFloat y = MARGIN_PX;
    for (NSString* line in lines) {
        // 라인 너비 계산 (안드로이드의 measureText와 동일)
        CGSize lineSize = [line sizeWithAttributes:textAttributes];
        CGFloat lineWidth = lineSize.width;
        
        // X 위치 계산 (안드로이드와 동일)
        CGFloat x;
        switch (align) {
            case TextAlignLeft:
                x = MARGIN_PX;
                break;
            case TextAlignCenter:
                x = (PAPER_WIDTH_PX - lineWidth) / 2.0;
                break;
            case TextAlignRight:
                x = PAPER_WIDTH_PX - lineWidth - MARGIN_PX;
                break;
        }
        
        // 텍스트 그리기
        [line drawAtPoint:CGPointMake(x, y) withAttributes:textAttributes];
        y += lineHeight;
    }
    
    // 이미지 생성
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

// 비트맵 데이터 생성 (안드로이드와 동일한 로직)
+ (NSData*)createBitmapData:(UIImage*)image {
    if (!image) return nil;
    
    CGImageRef imageRef = image.CGImage;
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
    
    return commandData;
}

// 데이터를 16진수 문자열로 변환
+ (NSString*)dataToHexString:(NSData*)data {
    NSMutableString* hexString = [NSMutableString string];
    const uint8_t* bytes = (const uint8_t*)data.bytes;
    
    for (int i = 0; i < data.length; i++) {
        [hexString appendFormat:@"%02X", bytes[i]];
    }
    
    return hexString;
}

@end 