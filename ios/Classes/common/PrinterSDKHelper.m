//
//  PrinterSDKHelper.m
//  blueberry_printer
//
//  PrinterSDK 래퍼 헬퍼
//

#import "PrinterSDKHelper.h"

@implementation PrinterSDKHelper

+ (void)printImage:(UIImage*)image withPrinterSDK:(PrinterSDK*)printerSDK {
    if (image && printerSDK) {
        [printerSDK printImage:image];
    }
}

+ (void)feedPaper:(NSInteger)lines withPrinterSDK:(PrinterSDK*)printerSDK {
    if (!printerSDK) return;

    // 줄바꿈을 위해 빈 공간 텍스트 출력
    for (NSInteger i = 0; i < lines; i++) {
        [printerSDK printText:@"\n"];
    }
}

+ (void)cutPaper:(PrinterSDK*)printerSDK {
    if (printerSDK) {
        // 용지 자르기 전에 충분한 공간 확보
        for (NSInteger i = 0; i < 5; i++) {
            [printerSDK printText:@"\n"];
        }
        [printerSDK cutPaper];
    }
}

@end
