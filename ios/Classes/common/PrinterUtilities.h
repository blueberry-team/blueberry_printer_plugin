//
//  PrinterUtilities.h
//  blueberry_printer
//
//  프린터 유틸리티 함수
//

#import <Foundation/Foundation.h>

@interface PrinterUtilities : NSObject

/**
 * 여러 NSData를 하나로 합침
 */
+ (NSData*)mergeDataArray:(NSArray<NSData*>*)dataArray;

/**
 * 문자열에서 특정 문자 모두 제거
 */
+ (NSString*)removeChar:(NSString*)str character:(unichar)c;

/**
 * 16진수 문자열을 NSData로 변환
 */
+ (NSData*)hexStringToData:(NSString*)hex;

/**
 * NSData를 16진수 문자열로 변환
 */
+ (NSString*)dataToHexString:(NSData*)data;

@end
