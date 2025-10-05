//
//  PrinterUtilities.m
//  blueberry_printer
//
//  프린터 유틸리티 함수
//

#import "PrinterUtilities.h"

@implementation PrinterUtilities

+ (NSData*)mergeDataArray:(NSArray<NSData*>*)dataArray {
    NSMutableData* result = [NSMutableData data];
    for (NSData* data in dataArray) {
        if (data != nil) {
            [result appendData:data];
        }
    }
    return result;
}

+ (NSString*)removeChar:(NSString*)str character:(unichar)c {
    if (str == nil) return nil;
    NSString* charStr = [NSString stringWithFormat:@"%C", c];
    return [str stringByReplacingOccurrencesOfString:charStr withString:@""];
}

+ (NSData*)hexStringToData:(NSString*)hex {
    if (hex == nil || hex.length == 0) return [NSData data];

    NSMutableData* data = [NSMutableData data];
    NSInteger len = hex.length / 2;

    for (NSInteger i = 0; i < len; i++) {
        NSInteger index = i * 2;
        NSString* byteStr = [hex substringWithRange:NSMakeRange(index, 2)];
        NSScanner* scanner = [NSScanner scannerWithString:byteStr];
        unsigned int byteValue;
        [scanner scanHexInt:&byteValue];
        Byte byte = (Byte)byteValue;
        [data appendBytes:&byte length:1];
    }

    return data;
}

+ (NSString*)dataToHexString:(NSData*)data {
    if (data == nil || data.length == 0) return @"";

    const unsigned char* bytes = (const unsigned char*)data.bytes;
    NSMutableString* hexString = [NSMutableString stringWithCapacity:data.length * 2];

    for (NSInteger i = 0; i < data.length; i++) {
        [hexString appendFormat:@"%02X", bytes[i]];
    }

    return hexString;
}

@end
