//
//  DisconnectReason.m
//  blueberry_printer
//
//  프린터 연결 끊김 이유
//

#import "DisconnectReason.h"

@implementation DisconnectReasonHelper

+ (NSString*)codeFromReason:(DisconnectReason)reason {
    switch (reason) {
        case DisconnectReasonUnknown:
            return @"UNKNOWN";
        case DisconnectReasonSocketTimeout:
            return @"SOCKET_TIMEOUT";
        case DisconnectReasonIOError:
            return @"IO_ERROR";
        case DisconnectReasonSocketClosed:
            return @"SOCKET_CLOSED";
        case DisconnectReasonPrinterOffline:
            return @"PRINTER_OFFLINE";
        case DisconnectReasonOutOfPaper:
            return @"OUT_OF_PAPER";
        case DisconnectReasonManualDisconnect:
            return @"MANUAL_DISCONNECT";
        case DisconnectReasonBluetoothDisabled:
            return @"BLUETOOTH_DISABLED";
        case DisconnectReasonConnectionFailed:
            return @"CONNECTION_FAILED";
        default:
            return @"UNKNOWN";
    }
}

+ (DisconnectReason)reasonFromCode:(NSString*)code {
    if ([code isEqualToString:@"UNKNOWN"]) return DisconnectReasonUnknown;
    if ([code isEqualToString:@"SOCKET_TIMEOUT"]) return DisconnectReasonSocketTimeout;
    if ([code isEqualToString:@"IO_ERROR"]) return DisconnectReasonIOError;
    if ([code isEqualToString:@"SOCKET_CLOSED"]) return DisconnectReasonSocketClosed;
    if ([code isEqualToString:@"PRINTER_OFFLINE"]) return DisconnectReasonPrinterOffline;
    if ([code isEqualToString:@"OUT_OF_PAPER"]) return DisconnectReasonOutOfPaper;
    if ([code isEqualToString:@"MANUAL_DISCONNECT"]) return DisconnectReasonManualDisconnect;
    if ([code isEqualToString:@"BLUETOOTH_DISABLED"]) return DisconnectReasonBluetoothDisabled;
    if ([code isEqualToString:@"CONNECTION_FAILED"]) return DisconnectReasonConnectionFailed;
    return DisconnectReasonUnknown;
}

+ (DisconnectReason)reasonFromErrorMessage:(NSString*)message {
    NSString* lowercaseMsg = [message lowercaseString];

    if ([lowercaseMsg containsString:@"timeout"]) {
        return DisconnectReasonSocketTimeout;
    } else if ([lowercaseMsg containsString:@"closed"]) {
        return DisconnectReasonSocketClosed;
    } else if ([lowercaseMsg containsString:@"offline"]) {
        return DisconnectReasonPrinterOffline;
    } else if ([lowercaseMsg containsString:@"paper"]) {
        return DisconnectReasonOutOfPaper;
    } else if ([lowercaseMsg containsString:@"bluetooth"]) {
        return DisconnectReasonBluetoothDisabled;
    } else if ([lowercaseMsg containsString:@"io"]) {
        return DisconnectReasonIOError;
    } else {
        return DisconnectReasonUnknown;
    }
}

@end
