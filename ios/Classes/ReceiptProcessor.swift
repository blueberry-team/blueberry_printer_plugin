import Foundation
import CoreGraphics
import UIKit

class ReceiptProcessor {
    
    // MARK: - 영수증 데이터 처리
    
    /// 영수증 데이터를 ESC/POS 명령으로 변환
    static func processReceiptData(_ receiptData: String) -> Data {
        var commands = Data()
        
        // 프린터 초기화
        commands.append(PrinterCommands.initializePrinter())
        
        // 줄바꿈 간격 설정
        commands.append(PrinterCommands.setLineSpacing(30))
        
        // 영수증 데이터를 줄 단위로 분리
        let lines = receiptData.components(separatedBy: "\n")
        
        for line in lines {
            if line.isEmpty {
                commands.append(PrinterCommands.lineFeed())
                continue
            }
            
            // 특수 명령 처리
            if line.hasPrefix("<") && line.hasSuffix(">") {
                commands.append(processSpecialCommand(line))
                continue
            }
            
            // 일반 텍스트 처리
            commands.append(processTextLine(line))
        }
        
        // 영수증 끝에 종이 자르기 (급지 포함)
        commands.append(PrinterCommands.cutPaperWithFeed())
        
        return commands
    }
    
    /// 특수 명령 처리
    private static func processSpecialCommand(_ command: String) -> Data {
        var commands = Data()
        let cmd = command.trimmingCharacters(in: CharacterSet(charactersIn: "<>"))
        
        switch cmd.lowercased() {
        case "cut":
            commands.append(PrinterCommands.cutPaper())
        case "feed":
            commands.append(PrinterCommands.feedPaper(lines: 3))
        case "bold_on":
            commands.append(PrinterCommands.setBoldText(true))
        case "bold_off":
            commands.append(PrinterCommands.setBoldText(false))
        case "center":
            commands.append(PrinterCommands.setTextAlignment(.center))
        case "left":
            commands.append(PrinterCommands.setTextAlignment(.left))
        case "right":
            commands.append(PrinterCommands.setTextAlignment(.right))
        case "large":
            commands.append(PrinterCommands.setTextSize(width: 1, height: 1))
        case "normal":
            commands.append(PrinterCommands.setTextSize(width: 0, height: 0))
        case "underline_on":
            commands.append(PrinterCommands.setUnderline(true))
        case "underline_off":
            commands.append(PrinterCommands.setUnderline(false))
        default:
            // 알 수 없는 명령은 무시
            break
        }
        
        return commands
    }
    
    /// 텍스트 라인 처리
    private static func processTextLine(_ line: String) -> Data {
        var commands = Data()
        
        // 한글 텍스트를 이미지로 변환하여 인쇄
        if containsKorean(line) {
            if let imageData = convertTextToImage(line) {
                commands.append(imageData)
            }
        } else {
            // 영어/숫자는 직접 인쇄
            commands.append(line.data(using: .ascii) ?? Data())
        }
        
        commands.append(PrinterCommands.lineFeed())
        
        return commands
    }
    
    /// 문자열에 한글이 포함되어 있는지 확인
    private static func containsKorean(_ text: String) -> Bool {
        let koreanRange = NSRange(location: 0, length: text.count)
        let koreanRegex = try? NSRegularExpression(pattern: "[가-힣]", options: [])
        return koreanRegex?.firstMatch(in: text, options: [], range: koreanRange) != nil
    }
    
    /// 텍스트를 이미지로 변환
    private static func convertTextToImage(_ text: String) -> Data? {
        let font = UIFont.systemFont(ofSize: 24)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.black
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let size = attributedString.size()
        
        // 이미지 크기 조정 (프린터 너비에 맞춤)
        let maxWidth: CGFloat = 384 // 일반적인 영수증 프린터 너비
        let scaleFactor = min(1.0, maxWidth / size.width)
        let scaledSize = CGSize(width: size.width * scaleFactor, height: size.height * scaleFactor)
        
        UIGraphicsBeginImageContextWithOptions(scaledSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // 배경을 흰색으로 설정
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(origin: .zero, size: scaledSize))
        
        // 텍스트 그리기
        let scaledFont = font.withSize(font.pointSize * scaleFactor)
        let scaledAttributes: [NSAttributedString.Key: Any] = [
            .font: scaledFont,
            .foregroundColor: UIColor.black
        ]
        
        let scaledAttributedString = NSAttributedString(string: text, attributes: scaledAttributes)
        scaledAttributedString.draw(in: CGRect(origin: .zero, size: scaledSize))
        
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        
        // 이미지를 비트맵 데이터로 변환
        return convertImageToBitmap(image)
    }
    
    /// 이미지를 비트맵 데이터로 변환
    private static func convertImageToBitmap(_ image: UIImage) -> Data? {
        guard let cgImage = image.cgImage else { return nil }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerRow = (width + 7) / 8
        
        var bitmapData = Data(count: bytesPerRow * height)
        
        // 이미지를 흑백으로 변환
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return nil }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let pixelData = context.data else { return nil }
        let pixels = pixelData.bindMemory(to: UInt8.self, capacity: width * height)
        
        // 픽셀 데이터를 비트맵으로 변환
        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = y * width + x
                let byteIndex = y * bytesPerRow + x / 8
                let bitIndex = 7 - (x % 8)
                
                if pixels[pixelIndex] < 128 { // 어두운 픽셀
                    bitmapData[byteIndex] |= (1 << bitIndex)
                }
            }
        }
        
        // ESC/POS 이미지 명령 생성
        return PrinterCommands.printImage(bitmapData, width: width, height: height)
    }
    
    // MARK: - 바코드 및 QR 코드 처리
    
    /// 바코드 인쇄
    static func printBarcode(_ data: String, type: BarcodeType) -> Data {
        var commands = Data()
        
        // 바코드 설정
        commands.append(PrinterCommands.setBarcodeHeight(162))
        commands.append(PrinterCommands.setBarcodeWidth(3))
        
        // 바코드 인쇄
        commands.append(PrinterCommands.printBarcode(data, type: type))
        commands.append(PrinterCommands.lineFeed())
        
        return commands
    }
    
    /// QR 코드 인쇄
    static func printQRCode(_ data: String) -> Data {
        var commands = Data()
        
        // QR 코드 인쇄
        commands.append(PrinterCommands.printQRCode(data))
        commands.append(PrinterCommands.lineFeed())
        
        return commands
    }
    
    // MARK: - 테이블 형식 데이터 처리
    
    /// 테이블 형식 데이터 처리
    static func processTableData(_ tableData: [[String]], columnWidths: [Int]) -> Data {
        var commands = Data()
        
        for row in tableData {
            var line = ""
            for (index, cell) in row.enumerated() {
                if index < columnWidths.count {
                    let width = columnWidths[index]
                    let paddedCell = padString(cell, width: width)
                    line += paddedCell
                }
            }
            commands.append(processTextLine(line))
        }
        
        return commands
    }
    
    /// 문자열을 지정된 너비로 패딩
    private static func padString(_ text: String, width: Int) -> String {
        if text.count >= width {
            return String(text.prefix(width))
        } else {
            return text + String(repeating: " ", count: width - text.count)
        }
    }
    
    // MARK: - 영수증 템플릿 처리
    
    /// 영수증 헤더 생성
    static func createReceiptHeader(storeName: String, address: String, phone: String) -> Data {
        var commands = Data()
        
        // 중앙 정렬
        commands.append(PrinterCommands.setTextAlignment(.center))
        
        // 굵은 글씨로 상점명
        commands.append(PrinterCommands.setBoldText(true))
        commands.append(processTextLine(storeName))
        commands.append(PrinterCommands.setBoldText(false))
        
        // 주소와 전화번호
        commands.append(processTextLine(address))
        commands.append(processTextLine(phone))
        
        // 구분선
        commands.append(processTextLine("--------------------------------"))
        
        // 왼쪽 정렬로 복원
        commands.append(PrinterCommands.setTextAlignment(.left))
        
        return commands
    }
    
    /// 영수증 푸터 생성
    static func createReceiptFooter(totalAmount: String, date: String) -> Data {
        var commands = Data()
        
        // 구분선
        commands.append(processTextLine("--------------------------------"))
        
        // 총액
        commands.append(PrinterCommands.setBoldText(true))
        commands.append(processTextLine("총액: \(totalAmount)"))
        commands.append(PrinterCommands.setBoldText(false))
        
        // 날짜
        commands.append(processTextLine("날짜: \(date)"))
        
        // 중앙 정렬로 감사 메시지
        commands.append(PrinterCommands.setTextAlignment(.center))
        commands.append(processTextLine("감사합니다"))
        
        return commands
    }
} 