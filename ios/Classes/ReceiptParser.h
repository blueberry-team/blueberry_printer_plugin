//
//  ReceiptParser.h
//  bluberry_printer
//
//  Created for Flutter plugin
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ReceiptParser : NSObject

// 텍스트 정렬 enum
typedef NS_ENUM(NSInteger, TextAlign) {
    TextAlignLeft,
    TextAlignCenter,
    TextAlignRight
};

// 영수증 텍스트를 파싱하고 비트맵 데이터로 변환
+ (NSData*)parseReceiptText:(NSString*)receiptText;

// 텍스트를 이미지로 변환
+ (UIImage*)createTextImage:(NSString*)text 
                   fontSize:(CGFloat)fontSize 
                    isBold:(BOOL)isBold 
                      align:(TextAlign)align;

// 비트맵 데이터 생성
+ (NSData*)createBitmapData:(UIImage*)image;

// 데이터를 16진수 문자열로 변환
+ (NSString*)dataToHexString:(NSData*)data;

@end 