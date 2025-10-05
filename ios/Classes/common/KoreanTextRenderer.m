//
//  KoreanTextRenderer.m
//  blueberry_printer
//
//  한글 텍스트 비트맵 렌더링
//

#import "KoreanTextRenderer.h"
#import "PrinterCommands.h"

// 종이(프린터) 설정
static const NSInteger PAPER_WIDTH_PX = 576;  // 일반적인 58mm 프린터 기준 (약 576픽셀)
static const NSInteger MARGIN_PX = 20;

@implementation KoreanTextRenderer

+ (UIImage*)createTextImage:(NSString*)text
                   textSize:(CGFloat)textSize
                     isBold:(BOOL)isBold
                      align:(TextAlign)align {
    // 폰트 설정
    UIFont* font;
    if (isBold) {
        font = [UIFont boldSystemFontOfSize:textSize];
    } else {
        font = [UIFont systemFontOfSize:textSize];
    }

    NSArray* lines = [text componentsSeparatedByString:@"\n"];
    CGFloat lineHeight = font.lineHeight;

    // 종이 너비를 고정으로 사용
    NSInteger width = PAPER_WIDTH_PX;
    NSInteger height = (NSInteger)(lineHeight * lines.count + MARGIN_PX * 2);

    // 비트맵 컨텍스트 생성
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), YES, 1.0);
    CGContextRef context = UIGraphicsGetCurrentContext();

    // 흰색 배경
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, width, height));

    // 텍스트 속성
    NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;

    NSDictionary* attributes = @{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: [UIColor blackColor],
        NSParagraphStyleAttributeName: paragraphStyle
    };

    CGFloat y = MARGIN_PX;
    for (NSString* line in lines) {
        CGSize lineSize = [line sizeWithAttributes:attributes];
        CGFloat x;

        switch (align) {
            case TextAlignLeft:
                x = MARGIN_PX;
                break;
            case TextAlignCenter:
                x = (width - lineSize.width) / 2.0;
                break;
            case TextAlignRight:
                x = width - lineSize.width - MARGIN_PX;
                break;
            default:
                x = MARGIN_PX;
                break;
        }

        [line drawAtPoint:CGPointMake(x, y) withAttributes:attributes];
        y += lineHeight;
    }

    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}

+ (NSData*)convertToBitmap:(UIImage*)image {
    NSInteger width = (NSInteger)image.size.width;
    NSInteger height = (NSInteger)image.size.height;

    // CGImage 가져오기
    CGImageRef cgImage = image.CGImage;
    if (!cgImage) return [NSData data];

    // 비트맵 컨텍스트 생성
    NSInteger bytesPerRow = width * 4;
    unsigned char* rawData = (unsigned char*)malloc(height * bytesPerRow);

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(rawData,
                                                   width,
                                                   height,
                                                   8,
                                                   bytesPerRow,
                                                   colorSpace,
                                                   kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);

    CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImage);
    CGContextRelease(context);

    // 8픽셀당 1바이트로 변환 (흑백)
    NSInteger widthBytes = (width + 7) / 8;
    NSMutableData* imageData = [NSMutableData dataWithLength:(widthBytes * height)];
    Byte* imageBytes = (Byte*)[imageData mutableBytes];

    for (NSInteger y = 0; y < height; y++) {
        for (NSInteger x = 0; x < width; x++) {
            NSInteger pixelIndex = (y * width + x) * 4;
            unsigned char r = rawData[pixelIndex];
            unsigned char g = rawData[pixelIndex + 1];
            unsigned char b = rawData[pixelIndex + 2];

            // 그레이스케일 변환
            NSInteger gray = (r + g + b) / 3;

            if (gray < 128) { // 어두운 픽셀을 1로 설정
                NSInteger byteIndex = y * widthBytes + x / 8;
                NSInteger bitIndex = 7 - (x % 8);
                imageBytes[byteIndex] |= (1 << bitIndex);
            }
        }
    }

    free(rawData);

    return [PrinterCommands POS_Print_Bitmap:imageData width:width height:height];
}

@end
