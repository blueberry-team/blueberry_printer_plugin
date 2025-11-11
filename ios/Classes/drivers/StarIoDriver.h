//
//  StarIoDriver.h
//  blueberry_printer
//
//  Star Micronics 프린터 드라이버 구현
//

#import <Foundation/Foundation.h>
#import "PrinterDriver.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Star Micronics 프린터 드라이버
 * StarXpand SDK (StarIO10)를 사용하여 Star Micronics 프린터를 지원
 */
@interface StarIoDriver : NSObject <PrinterDriver>

/**
 * 초기화
 */
- (instancetype)init;

@end

NS_ASSUME_NONNULL_END
