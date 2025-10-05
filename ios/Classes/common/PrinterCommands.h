//
//  PrinterCommands.h
//  blueberry_printer
//
//  프린터 명령어 생성
//

#import <Foundation/Foundation.h>

@interface PrinterCommands : NSObject

/**
 * 한국어 인코딩
 */
+ (NSStringEncoding)koreanEncoding;

/**
 * 프린터 초기화
 */
+ (NSData*)POS_Set_PrtInit;

/**
 * 출력 후 이동 (0~255)
 */
+ (NSData*)POS_Set_PrtAndFeedPaper:(NSInteger)feed;

/**
 * 비트맵 이미지 출력 (GS v 0 방식)
 * @param bitmapData 비트맵 데이터
 * @param width 이미지 폭
 * @param height 이미지 높이
 * @return ESC/POS 명령 바이트 배열
 */
+ (NSData*)POS_Print_Bitmap:(NSData*)bitmapData width:(NSInteger)width height:(NSInteger)height;

@end
