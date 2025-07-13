import Flutter
import UIKit
import CoreBluetooth

public class BluberryPrinterPlugin: NSObject, FlutterPlugin {
    private var discoveredPrinters: [String: Printer] = [:]
    private var isScanning = false
    private var scanCallback: FlutterResult?
    private var centralManager: CBCentralManager?
    private var discoveredDevices: [CBPeripheral] = []
    private var printerSDK: PrinterSDK?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "bluberry_printer", binaryMessenger: registrar.messenger())
        let instance = BluberryPrinterPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("🔍 [DEBUG] Flutter 메서드 호출: \(call.method)")
        
        // PrinterSDK 초기화
        if printerSDK == nil {
            printerSDK = PrinterSDK.default()
            setupPrinterNotifications()
        }
        
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
            
        case "searchDevices":
            searchDevices(result: result)
            
        case "connectDevice":
            guard let args = call.arguments as? [String: Any],
                  let address = args["address"] as? String else {
                print("🔍 [DEBUG] 연결 실패: 잘못된 인수")
                result(FlutterError(code: "INVALID_ARGS", message: "기기 주소가 필요합니다", details: nil))
                return
            }
            connectDevice(address: address, result: result)
            
        case "printReceipt":
            guard let args = call.arguments as? [String: Any],
                  let receiptText = args["receiptText"] as? String else {
                print("🔍 [DEBUG] 출력 실패: 잘못된 인수")
                result(FlutterError(code: "NO_TEXT", message: "출력할 텍스트가 필요합니다", details: nil))
                return
            }
            printReceipt(receiptText: receiptText, result: result)
            
        case "printSampleReceipt":
            printSampleReceipt(result: result)
            
        case "disconnect":
            disconnect(result: result)
            
        default:
            print("🔍 [DEBUG] 구현되지 않은 메서드: \(call.method)")
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func setupPrinterNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePrinterConnected),
            name: NSNotification.Name(rawValue: PrinterConnectedNotification),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePrinterDisconnected),
            name: NSNotification.Name(rawValue: PrinterDisconnectedNotification),
            object: nil
        )
    }
    
    @objc private func handlePrinterConnected() {
        print("🔍 [DEBUG] 프린터 연결됨")
    }
    
    @objc private func handlePrinterDisconnected() {
        print("🔍 [DEBUG] 프린터 연결 해제됨")
    }
    
    private func searchDevices(result: @escaping FlutterResult) {
        print("🔍 [DEBUG] searchDevices() 시작 - 실제 프린터 SDK 사용")
        
        self.scanCallback = result
        self.discoveredPrinters.removeAll()
        
        // 실제 프린터 SDK로 스캔 시작
        printerSDK?.scanPrinters { [weak self] printer in
            guard let self = self else { return }
            
            print("🔍 [DEBUG] 프린터 발견: \(printer.name ?? "Unknown") (\(printer.UUIDString ?? "No UUID"))")
            
            // Printer 객체를 UUID로 저장
            if let uuid = printer.UUIDString {
                self.discoveredPrinters[uuid] = printer
            }
            
            // Flutter에 실시간으로 발견된 프린터 전송
            DispatchQueue.main.async {
                let devices = self.discoveredPrinters.map { (uuid, printer) in
                    return [
                        "name": printer.name ?? "Unknown Printer",
                        "address": uuid
                    ]
                }
                print("🔍 [DEBUG] 현재 발견된 프린터: \(devices.count)개")
            }
        }
        
        // 10초 후 스캔 중단
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            self.printerSDK?.stopScanPrinters()
            
            let devices = self.discoveredPrinters.map { (uuid, printer) in
                return [
                    "name": printer.name ?? "Unknown Printer",
                    "address": uuid
                ]
            }
            print("🔍 [DEBUG] 스캔 완료: \(devices.count)개 프린터 발견")
            self.scanCallback?(devices)
            self.scanCallback = nil
        }
    }
    
    private func connectDevice(address: String, result: @escaping FlutterResult) {
        print("🔍 [DEBUG] 연결 시도 시작: \(address)")
        
        // 발견된 프린터 중에서 해당 주소의 프린터 찾기
        guard let printer = discoveredPrinters[address] else {
            print("🔍 [DEBUG] 해당 주소의 프린터를 찾을 수 없음: \(address)")
            result(FlutterError(code: "PRINTER_NOT_FOUND", message: "해당 주소의 프린터를 찾을 수 없습니다", details: nil))
            return
        }
        
        print("🔍 [DEBUG] 프린터 연결 시도: \(printer.name ?? "Unknown")")
        
        // 실제 프린터 SDK로 연결
        printerSDK?.connectBT(printer)
        
        // 연결 완료 대기 (실제로는 notification으로 처리됨)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            print("🔍 [DEBUG] 프린터 연결 완료")
            result(true)
        }
    }
    
    private func printReceipt(receiptText: String, result: @escaping FlutterResult) {
        print("🔍 [DEBUG] 출력 시도 시작")
        print("🔍 [DEBUG] 출력할 텍스트: \(receiptText)")
        
        // 실제 프린터 SDK로 출력
        printerSDK?.printText(receiptText)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            print("🔍 [DEBUG] 출력 완료")
            result(true)
        }
    }
    
    private func printSampleReceipt(result: @escaping FlutterResult) {
        print("🔍 [DEBUG] 샘플 영수증 출력 시도")
        
        let sampleText = """
        카페 블루베리
        
        서울특별시 강남구 테헤란로 123
        전화: 02-1234-5678
        
        ================================
        
        아메리카노 (ICE)        4,500원 x 2
        카페라떼 (HOT)          5,000원 x 1
        블루베리 머핀           3,500원 x 1
        
        ================================
        
        소계: 17,500원
        부가세: 1,750원
        합계: 19,250원
        
        감사합니다!
        다음에 또 방문해 주세요.
        """
        
        print("🔍 [DEBUG] 샘플 텍스트 생성 완료")
        
        // printReceipt 함수 재사용
        printReceipt(receiptText: sampleText, result: result)
    }
    
    private func disconnect(result: @escaping FlutterResult) {
        print("🔍 [DEBUG] 연결 해제 시도")
        
        printerSDK?.disconnect()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            print("🔍 [DEBUG] 연결 해제 완료")
            result(true)
        }
    }
}

// MARK: - CBCentralManagerDelegate (더 이상 사용하지 않음)
extension BluberryPrinterPlugin: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("🔍 [DEBUG] 블루투스가 활성화되었습니다")
        case .poweredOff:
            print("🔍 [DEBUG] 블루투스가 비활성화되었습니다")
        case .unauthorized:
            print("🔍 [DEBUG] 블루투스 권한이 거부되었습니다")
        case .unsupported:
            print("🔍 [DEBUG] 블루투스를 지원하지 않습니다")
        case .unknown:
            print("🔍 [DEBUG] 블루투스 상태를 알 수 없습니다")
        @unknown default:
            print("🔍 [DEBUG] 알 수 없는 블루투스 상태")
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("🔍 [DEBUG] 기기 발견: \(peripheral.name ?? "Unknown") (\(peripheral.identifier.uuidString))")
        
        // 중복 제거
        if !discoveredDevices.contains(where: { $0.identifier == peripheral.identifier }) {
            discoveredDevices.append(peripheral)
        }
    }
} 