//
//  BluetoothDeviceSearcher.h
//  blueberry_printer
//
//  블루투스 기기 검색을 담당하는 클래스
//

#import <Foundation/Foundation.h>
#import <blueberry_printer/PrinterSDK.h>

/**
 * 검색 완료 콜백
 * @param devices 찾은 기기 목록 (NSDictionary 배열 - name, address 포함)
 * @param error 에러 정보 (없으면 nil)
 */
typedef void(^DeviceSearchCompletion)(NSArray<NSDictionary*>* _Nullable devices, NSError* _Nullable error);

/**
 * 프린터 발견 콜백
 * @param printer 발견된 프린터
 */
typedef void(^PrinterDiscoveryCallback)(Printer* _Nullable printer);

@interface BluetoothDeviceSearcher : NSObject

/**
 * 페어링된 블루투스 프린터 기기 검색
 * @param printerSDK PrinterSDK 인스턴스
 * @param completion 검색 완료 콜백
 */
+ (void)searchPairedDevices:(PrinterSDK*)printerSDK
                 completion:(DeviceSearchCompletion)completion;

/**
 * 특정 UUID의 프린터 찾기
 * @param uuid 프린터 UUID
 * @param printerSDK PrinterSDK 인스턴스
 * @return 찾은 Printer 객체 (없으면 nil)
 */
+ (Printer* _Nullable)findPrinterByUUID:(NSString*)uuid
                             printerSDK:(PrinterSDK*)printerSDK;

/**
 * 블루투스 활성화 상태 확인
 * @return 활성화 여부
 */
+ (BOOL)isBluetoothEnabled;

@end
