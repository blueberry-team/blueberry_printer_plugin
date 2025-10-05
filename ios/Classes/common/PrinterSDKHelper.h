//
//  PrinterSDKHelper.h
//  blueberry_printer
//
//  PrinterSDK 래퍼 헬퍼
//

#import <Foundation/Foundation.h>
#import "PrinterSDK.h"

@interface PrinterSDKHelper : NSObject

/**
 * 이미지 출력
 */
+ (void)printImage:(UIImage*)image withPrinterSDK:(PrinterSDK*)printerSDK;

/**
 * 줄바꿈 (여러 줄)
 */
+ (void)feedPaper:(NSInteger)lines withPrinterSDK:(PrinterSDK*)printerSDK;

/**
 * 용지 자르기
 */
+ (void)cutPaper:(PrinterSDK*)printerSDK;

@end
