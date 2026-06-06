//
//  BluetoothDeviceSearcher.m
//  blueberry_printer
//
//  블루투스 기기 검색을 담당하는 클래스
//

#import "BluetoothDeviceSearcher.h"
#import <CoreBluetooth/CoreBluetooth.h>

@implementation BluetoothDeviceSearcher

+ (void)searchPairedDevices:(PrinterSDK*)printerSDK
                 completion:(DeviceSearchCompletion)completion {
    if (!printerSDK) {
        NSError* error = [NSError errorWithDomain:@"BluetoothDeviceSearcher"
                                             code:1001
                                         userInfo:@{NSLocalizedDescriptionKey: @"PrinterSDK가 nil입니다"}];
        if (completion) {
            completion(nil, error);
        }
        return;
    }

    NSMutableArray<NSDictionary*>* discoveredDevices = [NSMutableArray array];
    NSMutableSet<NSString*>* foundAddresses = [NSMutableSet set];

    // PrinterSDK를 사용하여 ESC/POS 프린터 스캔
    [printerSDK scanPrintersWithCompletion:^(Printer* printer) {
        if (printer) {
            NSString* name = printer.name ?: @"Unknown Printer";
            NSString* address = printer.UUIDString ?: @"";

            // 중복 제거
            if (![foundAddresses containsObject:address]) {
                NSDictionary* deviceInfo = @{
                    @"name": name,
                    @"address": address
                };

                [discoveredDevices addObject:deviceInfo];
                [foundAddresses addObject:address];
                NSLog(@"🔍 [PrinterSDK] 프린터 발견: %@ (%@)", name, address);
            }
        }
    }];

    // 스캔 완료 후 약간의 딜레이를 두고 결과 반환 (스캔이 비동기이므로)
    // 5초로 늘려서 더 많은 프린터 발견 기회 제공
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [printerSDK stopScanPrinters];

        if (completion) {
            NSLog(@"🔍 검색 완료: %lu개 기기", (unsigned long)discoveredDevices.count);
            completion(discoveredDevices, nil);
        }
    });
}

+ (Printer*)findPrinterByUUID:(NSString*)uuid printerSDK:(PrinterSDK*)printerSDK {
    // 이 메서드는 사용되지 않음
    // BlueberryPrinterPlugin에서 _discoveredPrinters Dictionary를 사용하여 직접 관리
    NSLog(@"⚠️ findPrinterByUUID는 더 이상 사용되지 않습니다. _discoveredPrinters를 사용하세요.");
    return nil;
}

+ (BOOL)isBluetoothEnabled {
    // iOS에서 Core Bluetooth를 사용하여 블루투스 상태 확인
    // 하지만 PrinterSDK가 이미 블루투스를 관리하므로, 간단히 YES 반환
    // 실제 구현은 PrinterSDK의 API나 CBCentralManager를 사용해야 함
    return YES;
}

+ (NSString*)detectPrinterType:(NSString*)deviceName {
    // Star 프린터 지원 제거: ESC/POS 프린터만 지원
    return @"esc_pos";
}

@end
