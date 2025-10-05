//
//  PrinterCommands.m
//  blueberry_printer
//
//  프린터 명령어 생성
//

#import "PrinterCommands.h"
#import "EscPosConstants.h"
#import "PrinterUtilities.h"

@implementation PrinterCommands

+ (NSStringEncoding)koreanEncoding {
    return CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingEUC_KR);
}

+ (NSData*)POS_Set_PrtInit {
    return [EscPosConstants ESC_Init];
}

+ (NSData*)POS_Set_PrtAndFeedPaper:(NSInteger)feed {
    if (feed > 255 || feed < 0) return nil;

    NSMutableData* command = [[EscPosConstants ESC_J] mutableCopy];
    Byte* bytes = (Byte*)[command mutableBytes];
    bytes[2] = (Byte)feed;

    return command;
}

+ (NSData*)POS_Print_Bitmap:(NSData*)bitmapData width:(NSInteger)width height:(NSInteger)height {
    NSInteger widthBytes = (width + 7) / 8; // 8픽셀당 1바이트
    NSMutableData* command = [NSMutableData dataWithCapacity:(8 + bitmapData.length)];

    // GS v 0 명령 구성
    Byte header[8];
    header[0] = 29;  // GS
    header[1] = 118; // v
    header[2] = 48;  // 0
    header[3] = 0;   // m (normal mode)
    header[4] = (Byte)(widthBytes & 0xFF);         // xL
    header[5] = (Byte)((widthBytes >> 8) & 0xFF);  // xH
    header[6] = (Byte)(height & 0xFF);             // yL
    header[7] = (Byte)((height >> 8) & 0xFF);      // yH

    [command appendBytes:header length:8];
    [command appendData:bitmapData];

    return command;
}

@end
