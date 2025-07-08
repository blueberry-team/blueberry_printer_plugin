import Foundation

class PrinterCommands {
    
    // MARK: - 기본 명령
    
    /// 프린터 초기화
    static func initializePrinter() -> Data {
        return EscPosConstants.ESC_Init
    }
    
    /// 줄바꿈
    static func lineFeed() -> Data {
        return EscPosConstants.LF
    }
    
    /// 종이 자르기
    static func cutPaper() -> Data {
        return EscPosConstants.GS_V_n
    }
    
    /// 종이 자르기 (급지 포함)
    static func cutPaperWithFeed() -> Data {
        var commands = Data()
        
        // 종이를 먼저 앞으로 이동 (87줄 정도)
        commands.append(feedPaper(lines: 87))
        
        // 그 다음 종이를 자름
        commands.append(EscPosConstants.GS_V_n)
        
        return commands
    }
    
    /// 종이 급지
    static func feedPaper(lines: Int) -> Data {
        var commands = Data()
        for _ in 0..<lines {
            commands.append(EscPosConstants.LF)
        }
        return commands
    }
    
    /// 프린터 급지 후 출력
    static func printAndFeedPaper(lines: Int) -> Data {
        var ESC_J = EscPosConstants.ESC_J
        ESC_J[2] = UInt8(lines)
        return ESC_J
    }
    
    // MARK: - 텍스트 포맷팅
    
    /// 텍스트 정렬 설정
    static func setTextAlignment(_ alignment: TextAlignment) -> Data {
        var ESC_Align = EscPosConstants.ESC_Align
        ESC_Align[2] = alignment.rawValue
        return ESC_Align
    }
    
    /// 텍스트 크기 설정
    static func setTextSize(width: Int, height: Int) -> Data {
        var GS_ExclamationMark = EscPosConstants.GS_ExclamationMark
        let size = UInt8((width << 4) | height)
        GS_ExclamationMark[2] = size
        return GS_ExclamationMark
    }
    
    /// 굵은 텍스트 설정
    static func setBoldText(_ enable: Bool) -> Data {
        var ESC_E = EscPosConstants.ESC_E
        ESC_E[2] = enable ? 1 : 0
        return ESC_E
    }
    
    /// 밑줄 설정
    static func setUnderline(_ enable: Bool) -> Data {
        var ESC_Minus = EscPosConstants.ESC_Minus
        ESC_Minus[2] = enable ? 1 : 0
        return ESC_Minus
    }
    
    /// 반전 텍스트 설정
    static func setInvertedText(_ enable: Bool) -> Data {
        var GS_B = EscPosConstants.GS_B
        GS_B[2] = enable ? 1 : 0
        return GS_B
    }
    
    /// 줄 간격 설정
    static func setLineSpacing(_ spacing: Int) -> Data {
        var ESC_Three = EscPosConstants.ESC_Three
        ESC_Three[2] = UInt8(spacing)
        return ESC_Three
    }
    
    /// 기본 줄 간격으로 재설정
    static func resetLineSpacing() -> Data {
        return EscPosConstants.ESC_Two
    }
    
    /// 문자 간격 설정
    static func setCharacterSpacing(_ spacing: Int) -> Data {
        var ESC_SP = EscPosConstants.ESC_SP
        ESC_SP[2] = UInt8(spacing)
        return ESC_SP
    }
    
    /// 왼쪽 여백 설정
    static func setLeftMargin(_ margin: Int) -> Data {
        var GS_LeftSp = EscPosConstants.GS_LeftSp
        GS_LeftSp[2] = UInt8(margin & 0xFF)
        GS_LeftSp[3] = UInt8((margin >> 8) & 0xFF)
        return GS_LeftSp
    }
    
    /// 절대 위치 설정
    static func setAbsolutePosition(_ position: Int) -> Data {
        var ESC_Relative = EscPosConstants.ESC_Relative
        ESC_Relative[2] = UInt8(position & 0xFF)
        ESC_Relative[3] = UInt8((position >> 8) & 0xFF)
        return ESC_Relative
    }
    
    /// 상대 위치 설정
    static func setRelativePosition(_ position: Int) -> Data {
        var ESC_Absolute = EscPosConstants.ESC_Absolute
        ESC_Absolute[2] = UInt8(position & 0xFF)
        ESC_Absolute[3] = UInt8((position >> 8) & 0xFF)
        return ESC_Absolute
    }
    
    // MARK: - 바코드 및 QR 코드
    
    /// 바코드 높이 설정
    static func setBarcodeHeight(_ height: Int) -> Data {
        var GS_h = EscPosConstants.GS_h
        GS_h[2] = UInt8(height)
        return GS_h
    }
    
    /// 바코드 너비 설정
    static func setBarcodeWidth(_ width: Int) -> Data {
        var GS_w = EscPosConstants.GS_w
        GS_w[2] = UInt8(width)
        return GS_w
    }
    
    /// 바코드 인쇄
    static func printBarcode(_ data: String, type: BarcodeType) -> Data {
        var commands = Data()
        
        // 바코드 타입 설정
        var GS_k = EscPosConstants.GS_k
        GS_k[2] = type.rawValue
        commands.append(GS_k)
        
        // 바코드 데이터 추가
        commands.append(data.data(using: .ascii) ?? Data())
        commands.append(Data([0x00])) // 종료 문자
        
        return commands
    }
    
    /// QR 코드 인쇄
    static func printQRCode(_ data: String) -> Data {
        var commands = Data()
        
        // QR 코드 설정
        commands.append(EscPosConstants.GS_k_m_v_r_nL_nH)
        
        // QR 코드 데이터 추가
        commands.append(data.data(using: .utf8) ?? Data())
        
        return commands
    }
    
    // MARK: - 현금 상자
    
    /// 현금 상자 열기
    static func openCashDrawer() -> Data {
        return EscPosConstants.ESC_p
    }
    
    // MARK: - 상태 확인
    
    /// 프린터 상태 확인
    static func checkPrinterStatus() -> Data {
        var DLE_eot = EscPosConstants.DLE_eot
        DLE_eot[2] = 0x01
        return DLE_eot
    }
    
    // MARK: - 이미지 인쇄
    
    /// 이미지 인쇄 (비트맵 형식)
    static func printImage(_ imageData: Data, width: Int, height: Int) -> Data {
        var commands = Data()
        
        // 이미지 모드 설정
        commands.append(Data([0x1D, 0x76, 0x30, 0x00]))
        
        // 이미지 크기 설정
        commands.append(Data([UInt8(width & 0xFF), UInt8((width >> 8) & 0xFF)]))
        commands.append(Data([UInt8(height & 0xFF), UInt8((height >> 8) & 0xFF)]))
        
        // 이미지 데이터 추가
        commands.append(imageData)
        
        return commands
    }
}

// MARK: - 열거형 정의

enum TextAlignment: UInt8 {
    case left = 0x00
    case center = 0x01
    case right = 0x02
}

enum BarcodeType: UInt8 {
    case code39 = 0x41
    case code128 = 0x49
    case ean13 = 0x43
    case ean8 = 0x44
} 