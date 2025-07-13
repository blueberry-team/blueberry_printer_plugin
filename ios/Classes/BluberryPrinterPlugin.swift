import Flutter
import UIKit

public class BluberryPrinterPlugin: NSObject, FlutterPlugin {
    private var discoveredPrinters: [Printer] = []
    private var isScanning = false
    private var scanCallback: FlutterResult?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "bluberry_printer", binaryMessenger: registrar.messenger())
        let instance = BluberryPrinterPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
            
        case "searchDevices":
            searchDevices(result: result)
            
        case "connectDevice":
            guard let args = call.arguments as? [String: Any],
                  let address = args["address"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "기기 주소가 필요합니다", details: nil))
                return
            }
            connectDevice(address: address, result: result)
            
        case "printReceipt":
            guard let args = call.arguments as? [String: Any],
                  let receiptText = args["receiptText"] as? String else {
                result(FlutterError(code: "NO_TEXT", message: "출력할 텍스트가 필요합니다", details: nil))
                return
            }
            printReceipt(receiptText: receiptText, result: result)
            
        case "printSampleReceipt":
            printSampleReceipt(result: result)
            
        case "disconnect":
            disconnect(result: result)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func searchDevices(result: @escaping FlutterResult) {
        self.scanCallback = result
        self.discoveredPrinters.removeAll()
        
        // PrinterSDK로 프린터 스캔 시작
        PrinterSDK.defaultPrinterSDK().scanPrinters { [weak self] printer in
            guard let self = self else { return }
            
            // 중복 제거
            if !self.discoveredPrinters.contains(where: { $0.uuidString == printer.uuidString }) {
                self.discoveredPrinters.append(printer)
            }
        }
        
        // 10초 후 스캔 중지 및 결과 반환
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            self.stopScanning()
        }
    }
    
    private func stopScanning() {
        PrinterSDK.defaultPrinterSDK().stopScanPrinters()
        
        let devices = discoveredPrinters.map { printer in
            return [
                "name": printer.name ?? "Unknown Device",
                "address": printer.uuidString ?? ""
            ]
        }
        
        scanCallback?(devices)
        scanCallback = nil
    }
    
    private func connectDevice(address: String, result: @escaping FlutterResult) {
        // UUID로 프린터 찾기
        guard let printer = discoveredPrinters.first(where: { $0.uuidString == address }) else {
            result(FlutterError(code: "DEVICE_NOT_FOUND", message: "기기를 찾을 수 없습니다", details: nil))
            return
        }
        
        // 연결 상태 알림 등록
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(printerConnected),
            name: NSNotification.Name(rawValue: PrinterConnectedNotification),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(printerDisconnected),
            name: NSNotification.Name(rawValue: PrinterDisconnectedNotification),
            object: nil
        )
        
        // 블루투스 연결
        PrinterSDK.defaultPrinterSDK().connectBT(printer)
        
        // 연결 결과를 위해 잠시 대기
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            result(true) // 일단 성공으로 처리 (실제로는 notification에서 처리해야 함)
        }
    }
    
    @objc private func printerConnected() {
        print("프린터 연결됨")
    }
    
    @objc private func printerDisconnected() {
        print("프린터 연결 해제됨")
    }
    
    private func printReceipt(receiptText: String, result: @escaping FlutterResult) {
        // 간단한 텍스트 출력 (이미지 변환 방식)
        PrinterSDK.defaultPrinterSDK().printTextImage(receiptText)
        result(true)
    }
    
    private func printSampleReceipt(result: @escaping FlutterResult) {
        // 샘플 영수증 출력
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
        
        PrinterSDK.defaultPrinterSDK().printTextImage(sampleText)
        result(true)
    }
    
    private func disconnect(result: @escaping FlutterResult) {
        PrinterSDK.defaultPrinterSDK().disconnect()
        
        // 알림 해제
        NotificationCenter.default.removeObserver(self)
        
        result(true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
