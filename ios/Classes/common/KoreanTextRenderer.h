//
//  KoreanTextRenderer.h
//  blueberry_printer
//
//  한글 텍스트 비트맵 렌더링
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 * 텍스트 정렬
 */
typedef NS_ENUM(NSInteger, TextAlign) {
    TextAlignLeft,
    TextAlignCenter,
    TextAlignRight
};

@interface KoreanTextRenderer : NSObject

/**
 * 텍스트를 이미지로 변환 (종이 크기 기준 정렬)
 */
+ (UIImage*)createTextImage:(NSString*)text
                   textSize:(CGFloat)textSize
                     isBold:(BOOL)isBold
                      align:(TextAlign)align;

/**
 * 비트맵을 프린터용 바이트 배열로 변환
 */
+ (NSData*)convertToBitmap:(UIImage*)image;

@end
