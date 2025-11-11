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

@end

NS_ASSUME_NONNULL_END
