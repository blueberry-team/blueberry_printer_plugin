import Flutter
import UIKit
import CoreBluetooth
import CoreGraphics

public class BluberryPrinterPlugin: NSObject, FlutterPlugin {
    private var bluetoothManager: CBCentralManager?
    private var discoveredPeripherals: [CBPeripheral] = []
    private var connectedPeripheral: CBPeripheral?
    private var printerCharacteristic: CBCharacteristic?
    private var flutterResult: FlutterResult?
    private var isScanning = false
    
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
        self.flutterResult = result
        self.discoveredPeripherals.removeAll()
        
        if bluetoothManager == nil {
            bluetoothManager = CBCentralManager(delegate: self, queue: nil)
        }
        
        // 블루투스 상태 확인 후 스캔 시작
        if bluetoothManager?.state == .poweredOn {
            startScanning()
        }
        // 블루투스 상태가 변경되면 CBCentralManagerDelegate에서 처리
    }
    
    private func startScanning() {
        guard let manager = bluetoothManager, manager.state == .poweredOn else {
            flutterResult?(FlutterError(code: "BLUETOOTH_OFF", message: "블루투스가 꺼져있습니다", details: nil))
            return
        }
        
        isScanning = true
        manager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        
        // 10초 후 스캔 중지
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            self.stopScanning()
        }
    }
    
    private func stopScanning() {
        bluetoothManager?.stopScan()
        isScanning = false
        
        let devices = discoveredPeripherals.map { peripheral in
            return [
                "name": peripheral.name ?? "Unknown Device",
                "address": peripheral.identifier.uuidString
            ]
        }
        
        flutterResult?(devices)
        flutterResult = nil
    }
    
    private func connectDevice(address: String, result: @escaping FlutterResult) {
        guard let manager = bluetoothManager else {
            result(FlutterError(code: "BLUETOOTH_NOT_INITIALIZED", message: "블루투스가 초기화되지 않았습니다", details: nil))
            return
        }
        
        // UUID로 기기 찾기
        let peripheral = discoveredPeripherals.first { $0.identifier.uuidString == address }
        
        guard let targetPeripheral = peripheral else {
            result(FlutterError(code: "DEVICE_NOT_FOUND", message: "기기를 찾을 수 없습니다", details: nil))
            return
        }
        
        self.flutterResult = result
        self.connectedPeripheral = targetPeripheral
        targetPeripheral.delegate = self
        
        manager.connect(targetPeripheral, options: nil)
    }
    
    private func printReceipt(receiptText: String, result: @escaping FlutterResult) {
        guard connectedPeripheral != nil, let characteristic = printerCharacteristic else {
            result(FlutterError(code: "NOT_CONNECTED", message: "프린터가 연결되지 않았습니다", details: nil))
            return
        }
        
        do {
            let printData = try ReceiptProcessor.parseAndPrint(receiptText: receiptText)
            sendDataToPrinter(data: printData)
            result(true)
        } catch {
            result(FlutterError(code: "PRINT_FAIL", message: "출력 실패: \(error.localizedDescription)", details: nil))
        }
    }
    
    private func printSampleReceipt(result: @escaping FlutterResult) {
        guard connectedPeripheral != nil, let characteristic = printerCharacteristic else {
            result(FlutterError(code: "NOT_CONNECTED", message: "프린터가 연결되지 않았습니다", details: nil))
            return
        }
        
        do {
            let printData = try ReceiptProcessor.parseAndPrint(receiptText: SampleReceipts.sampleReceiptData)
            sendDataToPrinter(data: printData)
            result(true)
        } catch {
            result(FlutterError(code: "PRINT_FAIL", message: "샘플 영수증 출력 실패: \(error.localizedDescription)", details: nil))
        }
    }
    
    private func disconnect(result: @escaping FlutterResult) {
        if let peripheral = connectedPeripheral {
            bluetoothManager?.cancelPeripheralConnection(peripheral)
        }
        
        connectedPeripheral = nil
        printerCharacteristic = nil
        result(true)
    }
    
    private func sendDataToPrinter(data: Data) {
        guard let peripheral = connectedPeripheral,
              let characteristic = printerCharacteristic else {
            return
        }
        
        // 데이터를 청크로 나누어 전송 (블루투스 MTU 고려)
        let chunkSize = 20
        var offset = 0
        
        while offset < data.count {
            let remainingBytes = data.count - offset
            let currentChunkSize = min(chunkSize, remainingBytes)
            let chunk = data.subdata(in: offset..<offset + currentChunkSize)
            
            peripheral.writeValue(chunk, for: characteristic, type: .withoutResponse)
            offset += currentChunkSize
            
            // 작은 지연을 추가하여 안정성 향상
            usleep(10000) // 10ms
        }
    }
}

// MARK: - CBCentralManagerDelegate
extension BluberryPrinterPlugin: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            if isScanning {
                startScanning()
            }
        case .poweredOff:
            flutterResult?(FlutterError(code: "BLUETOOTH_OFF", message: "블루투스가 꺼져있습니다", details: nil))
        case .unsupported:
            flutterResult?(FlutterError(code: "BLUETOOTH_UNSUPPORTED", message: "블루투스를 지원하지 않습니다", details: nil))
        default:
            break
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !discoveredPeripherals.contains(peripheral) {
            discoveredPeripherals.append(peripheral)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices(nil)
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        flutterResult?(FlutterError(code: "CONNECTION_FAILED", message: "연결 실패: \(error?.localizedDescription ?? "Unknown error")", details: nil))
        flutterResult = nil
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if peripheral == connectedPeripheral {
            connectedPeripheral = nil
            printerCharacteristic = nil
        }
    }
}

// MARK: - CBPeripheralDelegate
extension BluberryPrinterPlugin: CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            if characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse) {
                printerCharacteristic = characteristic
                flutterResult?(true)
                flutterResult = nil
                return
            }
        }
    }
}
