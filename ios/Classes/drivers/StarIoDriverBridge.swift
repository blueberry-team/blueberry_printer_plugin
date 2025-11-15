//
//  StarIoDriverBridge.swift
//  blueberry_printer
//
//  PrinterDriver 프로토콜을 구현하는 Swift 브리지
//

import Foundation
import StarIO10

@objc(StarIoDriver)
public class StarIoDriver: NSObject {
    private var starPrinter: StarPrinter?
    private var isConnectedState: Bool = false
    private var connectionStatusCallback: ((String) -> Void)?

    @objc public override init() {
        super.init()
        NSLog("✅ StarIoDriver (Swift) 초기화")
    }

    @objc public func getType() -> Int {
        return 1 // PrinterTypeStarMicronics
    }

    @objc(connectWithAddress:error:)
    public func connect(address: String, error: NSErrorPointer) -> Bool {
        NSLog("🔌 Star Micronics 프린터 연결 시작 - identifier: \(address)")

        // address는 serialNumber (MAC 주소 형식)
        let settings = StarConnectionSettings(interfaceType: .bluetooth,
                                             identifier: address)

        starPrinter = StarPrinter(settings)

        guard let printer = starPrinter else {
            if error != nil {
                error?.pointee = NSError(domain: "StarIoDriver", code: 1001,
                                       userInfo: [NSLocalizedDescriptionKey: "Failed to create StarPrinter"])
            }
            return false
        }

        // Open connection
        do {
            try awaitSync {
                try await printer.open()
            }
            isConnectedState = true
            NSLog("✅ Star 프린터 연결 성공: \(address)")
            return true
        } catch let err as NSError {
            if error != nil {
                error?.pointee = err
            }
            NSLog("❌ Star 프린터 연결 실패: \(err.localizedDescription)")
            return false
        }
    }

    @objc public func disconnect() {
        guard let printer = starPrinter, isConnectedState else {
            return
        }

        Task {
            await printer.close()
            isConnectedState = false
            NSLog("✅ Star 프린터 연결 해제")
        }
    }

    @objc public func isConnected() -> Bool {
        return isConnectedState
    }

    @objc public func getConnectionStatus() -> String {
        return isConnectedState ? "connected" : "disconnected"
    }

    @objc public func cleanup() {
        disconnect()
        stopConnectionMonitoring()
    }

    @objc(startConnectionMonitoringWithCallback:)
    public func startConnectionMonitoring(callback: @escaping (String) -> Void) {
        connectionStatusCallback = callback

        guard let printer = starPrinter else { return }

        Task {
            do {
                let status = try await printer.getStatus()
                if status.hasError {
                    callback("error")
                } else {
                    callback("connected")
                }
            } catch {
                callback("disconnected")
            }
        }
    }

    @objc public func stopConnectionMonitoring() {
        connectionStatusCallback = nil
    }

    @objc(printTotalOrderWithData:storeName:tableNumber:storeAddress:phoneNumber:businessNumber:thankYouMessage:language:currency:error:)
    public func printTotalOrder(data orderData: [String: Any],
                               storeName: String,
                               tableNumber: String?,
                               storeAddress: String?,
                               phoneNumber: String?,
                               businessNumber: String?,
                               thankYouMessage: String?,
                               language: String,
                               currency: String,
                               error: NSErrorPointer) -> Bool {
        if !isConnectedState {
            if error != nil {
                error?.pointee = NSError(domain: "StarIoDriver", code: 1002,
                                       userInfo: [NSLocalizedDescriptionKey: "프린터가 연결되지 않았습니다"])
            }
            return false
        }

        guard let printer = starPrinter else {
            if error != nil {
                error?.pointee = NSError(domain: "StarIoDriver", code: 1002,
                                       userInfo: [NSLocalizedDescriptionKey: "프린터가 연결되지 않았습니다"])
            }
            return false
        }

        // Build StarXpand command
        let command = buildReceiptCommand(orderData: orderData,
                                         storeName: storeName,
                                         tableNumber: tableNumber,
                                         storeAddress: storeAddress,
                                         phoneNumber: phoneNumber,
                                         businessNumber: businessNumber,
                                         thankYouMessage: thankYouMessage,
                                         language: language,
                                         currency: currency)

        // Print
        do {
            try awaitSync {
                try await printer.print(command: command)
            }
            NSLog("✅ Star 프린터 인쇄 완료")
            return true
        } catch let err as NSError {
            if error != nil {
                error?.pointee = err
            }
            NSLog("❌ Star 프린터 인쇄 실패: \(err.localizedDescription)")
            return false
        }
    }

    @objc(printSingleOrderWithData:storeName:tableNumber:storeAddress:phoneNumber:businessNumber:thankYouMessage:language:currency:showStoreLabel:error:)
    public func printSingleOrder(data orderData: [String: Any],
                                storeName: String,
                                tableNumber: String?,
                                storeAddress: String?,
                                phoneNumber: String?,
                                businessNumber: String?,
                                thankYouMessage: String?,
                                language: String,
                                currency: String,
                                showStoreLabel: Bool,
                                error: NSErrorPointer) -> Bool {
        // 단일 주문도 동일한 로직 사용
        return printTotalOrder(data: orderData,
                              storeName: storeName,
                              tableNumber: tableNumber,
                              storeAddress: storeAddress,
                              phoneNumber: phoneNumber,
                              businessNumber: businessNumber,
                              thankYouMessage: thankYouMessage,
                              language: language,
                              currency: currency,
                              error: error)
    }

    @objc(printOrderFromSocketWithData:language:currency:error:)
    public func printOrderFromSocket(data orderData: [String: Any],
                                    language: String,
                                    currency: String,
                                    error: NSErrorPointer) -> Bool {
        if !isConnectedState {
            if error != nil {
                error?.pointee = NSError(domain: "StarIoDriver", code: 1002,
                                       userInfo: [NSLocalizedDescriptionKey: "프린터가 연결되지 않았습니다"])
            }
            return false
        }

        guard let printer = starPrinter else {
            if error != nil {
                error?.pointee = NSError(domain: "StarIoDriver", code: 1002,
                                       userInfo: [NSLocalizedDescriptionKey: "프린터가 연결되지 않았습니다"])
            }
            return false
        }

        // 주문 알림 영수증 출력 (실제 주문 데이터 포함)
        let command = buildOrderNotificationReceipt(orderData: orderData, language: language, currency: currency)

        do {
            try awaitSync {
                try await printer.print(command: command)
            }
            NSLog("✅ Star 프린터 소켓 주문 인쇄 완료")
            return true
        } catch let err as NSError {
            if error != nil {
                error?.pointee = err
            }
            NSLog("❌ Star 프린터 소켓 주문 인쇄 실패: \(err.localizedDescription)")
            return false
        }
    }

    @objc(printTextWithText:fontSize:isBold:align:error:)
    public func printText(text: String,
                         fontSize: CGFloat,
                         isBold: Bool,
                         align: String,
                         error: NSErrorPointer) -> Bool {
        if !isConnectedState {
            if error != nil {
                error?.pointee = NSError(domain: "StarIoDriver", code: 1002,
                                       userInfo: [NSLocalizedDescriptionKey: "프린터가 연결되지 않았습니다"])
            }
            return false
        }

        guard let printer = starPrinter else {
            if error != nil {
                error?.pointee = NSError(domain: "StarIoDriver", code: 1002,
                                       userInfo: [NSLocalizedDescriptionKey: "프린터가 연결되지 않았습니다"])
            }
            return false
        }

        let builder = StarXpandCommand.StarXpandCommandBuilder()
        let printerBuilder = StarXpandCommand.PrinterBuilder()

        // 정렬 설정
        if align == "center" {
            _ = printerBuilder.styleAlignment(.center)
        } else if align == "right" {
            _ = printerBuilder.styleAlignment(.right)
        } else {
            _ = printerBuilder.styleAlignment(.left)
        }

        // 볼드 설정
        if isBold {
            _ = printerBuilder.styleBold(true)
        }

        // 텍스트 출력
        _ = printerBuilder.actionPrintText(text + "\n")

        _ = builder.addDocument(StarXpandCommand.DocumentBuilder()
            .addPrinter(printerBuilder)
        )

        let command = builder.getCommands()

        do {
            try awaitSync {
                try await printer.print(command: command)
            }
            NSLog("✅ Star 프린터 텍스트 인쇄 완료")
            return true
        } catch let err as NSError {
            if error != nil {
                error?.pointee = err
            }
            NSLog("❌ Star 프린터 텍스트 인쇄 실패: \(err.localizedDescription)")
            return false
        }
    }

    // Helper function to format currency
    private func formatCurrency(_ amount: Double, _ currency: String) -> String {
        let intAmount = Int(amount)
        switch currency.uppercased() {
        case "KRW":
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.groupingSeparator = ","
            return "\(formatter.string(from: NSNumber(value: intAmount)) ?? "\(intAmount)")원"
        case "USD":
            return String(format: "$%.2f", amount / 100.0)
        case "JPY":
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.groupingSeparator = ","
            return "¥\(formatter.string(from: NSNumber(value: intAmount)) ?? "\(intAmount)")"
        default:
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.groupingSeparator = ","
            return "\(formatter.string(from: NSNumber(value: intAmount)) ?? "\(intAmount)") \(currency)"
        }
    }

    // Helper function to build order notification receipt
    private func buildOrderNotificationReceipt(orderData: [String: Any], language: String, currency: String) -> String {
        let builder = StarXpandCommand.StarXpandCommandBuilder()
        let printerBuilder = StarXpandCommand.PrinterBuilder()

        // 다국어 텍스트
        func getLocalizedText(_ key: String, _ lang: String) -> String {
            switch lang {
            case "eng":
                switch key {
                case "table": return "Table"
                case "order_create": return "Order  Added"
                case "order_update": return "Order  Updated"
                case "order_cancelled": return "Order  Cancelled"
                case "option": return "Option/"
                default: return key
                }
            case "jpn":
                switch key {
                case "table": return "テーブル"
                case "order_create": return "注文  追加"
                case "order_update": return "注文  変更"
                case "order_cancelled": return "注文  取消"
                case "option": return "オプション/"
                default: return key
                }
            default: // "kor"
                switch key {
                case "table": return "테이블"
                case "order_create": return "주문  추가"
                case "order_update": return "주문  변경"
                case "order_cancelled": return "주문  취소"
                case "option": return "옵션/"
                default: return key
                }
            }
        }

        // 주문 정보 추출
        let orderType = orderData["orderType"] as? String ?? "CREATE"
        let tableNumber = orderData["tableNumber"] as? Int ?? 0
        let items = orderData["items"] as? [[String: Any]] ?? []

        // 날짜/시간 출력
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = language == "jpn" ? "M月d日 (E) HH:mm" : (language == "eng" ? "MMM d (E) HH:mm" : "M월 d일 (E) HH:mm")
        dateFormatter.locale = language == "jpn" ? Locale(identifier: "ja_JP") : (language == "eng" ? Locale(identifier: "en_US") : Locale(identifier: "ko_KR"))
        let dateString = dateFormatter.string(from: Date())

        _ = printerBuilder.styleAlignment(.left)
        _ = printerBuilder.actionPrintText(dateString + "\n\n")

        // 테이블 번호 (박스)
        _ = printerBuilder.styleAlignment(.center)
        _ = printerBuilder.actionPrintText("┌──────────────┐\n")
        _ = printerBuilder.styleBold(true)
        _ = printerBuilder.styleMagnification(StarXpandCommand.MagnificationParameter(width: 2, height: 2))
        _ = printerBuilder.actionPrintText("│ \(getLocalizedText("table", language)) \(tableNumber) │\n")
        _ = printerBuilder.styleMagnification(StarXpandCommand.MagnificationParameter(width: 1, height: 1))
        _ = printerBuilder.styleBold(false)
        _ = printerBuilder.actionPrintText("└──────────────┘\n\n")

        // 주문 타입
        let orderTypeText: String
        switch orderType {
        case "CREATE": orderTypeText = getLocalizedText("order_create", language)
        case "UPDATE": orderTypeText = getLocalizedText("order_update", language)
        case "CANCELLED": orderTypeText = getLocalizedText("order_cancelled", language)
        default: orderTypeText = orderType
        }

        _ = printerBuilder.styleAlignment(.left)
        _ = printerBuilder.styleBold(true)
        _ = printerBuilder.styleMagnification(StarXpandCommand.MagnificationParameter(width: 2, height: 2))
        _ = printerBuilder.actionPrintText(orderTypeText + "\n")
        _ = printerBuilder.styleMagnification(StarXpandCommand.MagnificationParameter(width: 1, height: 1))
        _ = printerBuilder.styleBold(false)

        // 구분선
        _ = printerBuilder.actionPrintText(String(repeating: "-", count: 48) + "\n")

        // 메뉴 아이템 출력
        for item in items {
            let menuName = item["menuName"] as? String ?? ""
            let quantity = item["quantity"] as? Int ?? 1
            let itemOptions = item["itemOptions"] as? [[String: Any]] ?? []

            // 메뉴명 + 수량
            _ = printerBuilder.styleBold(true)
            _ = printerBuilder.actionPrintText("\(menuName) x \(quantity)\n")
            _ = printerBuilder.styleBold(false)

            // 옵션 출력
            for option in itemOptions {
                let optionName = option["name"] as? String ?? ""
                let optionDetails = option["optionDetails"] as? [[String: Any]] ?? []

                let detailNames = optionDetails.compactMap { detail -> String? in
                    guard let detailName = detail["name"] as? String else { return nil }
                    let detailQuantity = detail["quantity"] as? Int ?? 1
                    return detailQuantity > 1 ? "\(detailName) x\(detailQuantity)" : detailName
                }.joined(separator: ", ")

                if !detailNames.isEmpty {
                    _ = printerBuilder.actionPrintText("\(getLocalizedText("option", language)) \(optionName) : \(detailNames)\n")
                }
            }
        }

        // 용지 자르기
        _ = printerBuilder.actionFeedLine(3)
        _ = printerBuilder.actionCut(.partial)

        _ = builder.addDocument(StarXpandCommand.DocumentBuilder()
            .addPrinter(printerBuilder)
        )

        return builder.getCommands()
    }

    // Helper function to build receipt command
    private func buildReceiptCommand(orderData: [String: Any],
                                    storeName: String,
                                    tableNumber: String?,
                                    storeAddress: String?,
                                    phoneNumber: String?,
                                    businessNumber: String?,
                                    thankYouMessage: String?,
                                    language: String,
                                    currency: String) -> String {
        let builder = StarXpandCommand.StarXpandCommandBuilder()
        let printerBuilder = StarXpandCommand.PrinterBuilder()

        // NSNull을 nil로 변환하는 헬퍼
        func stringOrNil(_ value: String?) -> String? {
            guard let val = value, !(val is NSNull) else { return nil }
            return val
        }

        // 헤더
        if !storeName.isEmpty {
            _ = printerBuilder.styleAlignment(.center)
            _ = printerBuilder.styleMagnification(StarXpandCommand.MagnificationParameter(width: 2, height: 2))
            _ = printerBuilder.actionPrintText(storeName + "\n")
            _ = printerBuilder.styleMagnification(StarXpandCommand.MagnificationParameter(width: 1, height: 1))
        }

        if let address = stringOrNil(storeAddress), !address.isEmpty {
            _ = printerBuilder.actionPrintText(address + "\n")
        }

        if let phone = stringOrNil(phoneNumber), !phone.isEmpty {
            _ = printerBuilder.actionPrintText("TEL: " + phone + "\n")
        }

        if let business = stringOrNil(businessNumber), !business.isEmpty {
            _ = printerBuilder.actionPrintText("사업자번호: " + business + "\n")
        }

        _ = printerBuilder.styleAlignment(.left)
        _ = printerBuilder.actionPrintText(String(repeating: "-", count: 48) + "\n")

        // 주문 항목들 (orderMenus 키 사용)
        if let orderMenus = orderData["orderMenus"] as? [[String: Any]] {
            for menu in orderMenus {
                if let name = menu["menuName"] as? String,
                   let quantity = menu["quantity"] as? Int,
                   let price = menu["price"] as? Double {

                    // 메뉴명 길이 제한 (20자)
                    let displayName = name.count > 20 ? String(name.prefix(20)) + "..." : name
                    let menuText = String(format: "%@ x%d", displayName, quantity)
                    let priceText = formatCurrency(price, currency)

                    // 메뉴명과 가격을 같은 줄에 (왼쪽: 메뉴, 오른쪽: 가격)
                    let lineWidth = 48
                    let spacingCount = max(1, lineWidth - menuText.count - priceText.count)
                    let spacing = String(repeating: " ", count: spacingCount)

                    _ = printerBuilder.styleAlignment(.left)
                    _ = printerBuilder.actionPrintText(menuText + spacing + priceText + "\n")

                    // 옵션 출력
                    if let menuOptionItems = menu["menuOptionItems"] as? [[String: Any]] {
                        for optionGroup in menuOptionItems {
                            if let selectedItems = optionGroup["selectedItems"] as? [[String: Any]] {
                                for selectedItem in selectedItems {
                                    let itemName = selectedItem["menuOptionItemDetailName"] as? String
                                        ?? selectedItem["itemName"] as? String ?? ""
                                    let itemPrice = (selectedItem["menuOptionItemDetailPrice"] as? Double)
                                        ?? (selectedItem["itemPrice"] as? Double) ?? 0.0
                                    let itemQuantity = selectedItem["menuOptionItemDetailQuantity"] as? Int
                                        ?? selectedItem["quantity"] as? Int ?? 0

                                    if itemPrice > 0 {
                                        // 옵션 텍스트
                                        let optionText = String(format: "  + %@ x%d", itemName, itemQuantity)
                                        let optionPriceText = formatCurrency(itemPrice * Double(itemQuantity), currency)
                                        let optionSpacingCount = max(1, lineWidth - optionText.count - optionPriceText.count)
                                        let optionSpacing = String(repeating: " ", count: optionSpacingCount)
                                        _ = printerBuilder.actionPrintText(optionText + optionSpacing + optionPriceText + "\n")
                                    } else {
                                        _ = printerBuilder.actionPrintText(String(format: "  + %@\n", itemName))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        _ = printerBuilder.actionPrintText(String(repeating: "-", count: 48) + "\n")

        // 합계 (totalPrice 키 사용)
        if let total = orderData["totalPrice"] as? Double {
            _ = printerBuilder.styleAlignment(.left)
            _ = printerBuilder.styleBold(true)
            _ = printerBuilder.actionPrintText("TOTAL\n")

            _ = printerBuilder.styleAlignment(.right)
            _ = printerBuilder.actionPrintText(formatCurrency(total, currency) + "\n")
            _ = printerBuilder.styleBold(false)
            _ = printerBuilder.styleAlignment(.left)
        }

        // 감사 메시지
        if let message = stringOrNil(thankYouMessage), !message.isEmpty {
            _ = printerBuilder.styleAlignment(.center)
            _ = printerBuilder.actionPrintText("\n" + message + "\n")
        }

        _ = printerBuilder.actionCut(.partial)

        _ = builder.addDocument(StarXpandCommand.DocumentBuilder()
            .addPrinter(printerBuilder)
        )

        return builder.getCommands()
    }

    // Helper function to await async operations
    private func awaitSync<T>(_ operation: @escaping () async throws -> T) throws -> T {
        var result: Result<T, Error>?
        let semaphore = DispatchSemaphore(value: 0)

        Task {
            do {
                let value = try await operation()
                result = .success(value)
            } catch {
                result = .failure(error)
            }
            semaphore.signal()
        }

        semaphore.wait()
        return try result!.get()
    }
}
