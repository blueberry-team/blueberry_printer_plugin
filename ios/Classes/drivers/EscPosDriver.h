//
//  EscPosDriver.h
//  blueberry_printer
//
//  ESC/POS 프린터 드라이버 구현
//

#import <Foundation/Foundation.h>
#import "PrinterDriver.h"
#import <blueberry_printer/PrinterSDK.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * ESC/POS 프린터 드라이버
 * 기존 블루투스 소켓 기반의 ESC/POS 프린터를 지원
 */
@interface EscPosDriver : NSObject <PrinterDriver>

/**
 * 초기화
 */
- (instancetype)init;

/**
 * 프린터 객체 미리 설정 (연결 시 스캔 생략)
 * @param printer 검색된 Printer 객체
 */
- (void)setPrinter:(Printer*)printer;

@end

NS_ASSUME_NONNULL_END
