package com.example.blueberry_printer.drivers

import android.content.Context
import android.util.Log
import com.starmicronics.stario10.InterfaceType
import com.starmicronics.stario10.StarConnectionSettings
import com.starmicronics.stario10.StarPrinter
import com.starmicronics.stario10.starxpandcommand.DocumentBuilder
import com.starmicronics.stario10.starxpandcommand.MagnificationParameter
import com.starmicronics.stario10.starxpandcommand.PrinterBuilder
import com.starmicronics.stario10.starxpandcommand.StarXpandCommandBuilder
import com.starmicronics.stario10.starxpandcommand.printer.Alignment
import com.starmicronics.stario10.starxpandcommand.printer.CutType
import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Star Micronics 프린터 드라이버
 *
 * StarXpand SDK (StarIO10)를 사용하여 Star Micronics 프린터를 지원합니다.
 */
class StarIoDriver(private val context: Context) : PrinterDriver {
    companion object {
        private const val TAG = "StarIoDriver"
        private const val MONITORING_INTERVAL_MS = 5000L
    }

    private var starPrinter: StarPrinter? = null
    private var isConnected = false
    private var monitoringJob: Job? = null
    private var eventSink: EventChannel.EventSink? = null

    override fun getType(): PrinterDriver.PrinterType {
        return PrinterDriver.PrinterType.STAR_MICRONICS
    }

    override fun connect(address: String): Boolean {
        return try {
            Log.d(TAG, "Star Micronics 프린터 연결 시작: $address")

            // StarConnectionSettings 생성
            val settings = StarConnectionSettings(
                interfaceType = InterfaceType.Bluetooth,
                identifier = address
            )

            // StarPrinter 인스턴스 생성
            val printer = StarPrinter(settings, context)

            // 프린터 연결 (코루틴 → 블로킹 변환)
            try {
                runBlocking {
                    withTimeout(10000) {
                        printer.openAsync().await()
                    }
                }
                starPrinter = printer
                isConnected = true
                Log.d(TAG, "Star Micronics 프린터 연결 성공")
                true
            } catch (e: Exception) {
                Log.e(TAG, "프린터 open 실패: ${e.message}", e)
                false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Star Micronics 프린터 연결 실패: ${e.message}", e)
            false
        }
    }

    override fun disconnect(): Boolean {
        return try {
            Log.d(TAG, "Star Micronics 프린터 연결 해제")
            stopConnectionMonitoring()

            starPrinter?.let { printer ->
                try {
                    runBlocking {
                        withTimeout(5000) {
                            printer.closeAsync().await()
                        }
                    }
                } catch (e: Exception) {
                    Log.w(TAG, "프린터 close 경고: ${e.message}")
                }
            }

            starPrinter = null
            isConnected = false
            true
        } catch (e: Exception) {
            Log.e(TAG, "Star Micronics 프린터 연결 해제 실패: ${e.message}", e)
            false
        }
    }

    override fun isConnected(): Boolean {
        return isConnected && starPrinter != null
    }

    override fun printSingleOrder(
        orderData: Map<String, Any>,
        storeName: String,
        tableNumber: String?,
        storeAddress: String?,
        phoneNumber: String?,
        businessNumber: String?,
        thankYouMessage: String?,
        language: String,
        currency: String,
        showStoreLabel: Boolean
    ): Boolean {
        val printer = starPrinter
        if (printer == null || !isConnected) {
            Log.e(TAG, "프린터가 연결되지 않았습니다")
            return false
        }

        return try {
            Log.d(TAG, "단일 주문 영수증 출력 시작 (Star Micronics)")

            // StarXpand 명령 빌더 생성
            val builder = StarXpandCommandBuilder()
            builder.addDocument(
                DocumentBuilder()
                    .addPrinter(
                        buildSingleOrderReceipt(
                            orderData, storeName, tableNumber, storeAddress,
                            phoneNumber, businessNumber, thankYouMessage,
                            language, currency, showStoreLabel
                        )
                    )
            )

            // 프린터로 전송
            runBlocking {
                withTimeout(30000) {
                    printer.printAsync(builder.getCommands()).await()
                }
            }
            Log.d(TAG, "Star Micronics 단일 주문 영수증 출력 성공")
            true
        } catch (e: Exception) {
            Log.e(TAG, "단일 주문 영수증 출력 실패", e)
            false
        }
    }

    override fun printTotalOrder(
        orderData: Map<String, Any>,
        storeName: String,
        tableNumber: String?,
        storeAddress: String?,
        phoneNumber: String?,
        businessNumber: String?,
        thankYouMessage: String?,
        language: String,
        currency: String
    ): Boolean {
        val printer = starPrinter
        if (printer == null || !isConnected) {
            Log.e(TAG, "프린터가 연결되지 않았습니다")
            return false
        }

        return try {
            Log.d(TAG, "전체 주문 영수증 출력 시작 (Star Micronics)")

            val builder = StarXpandCommandBuilder()
            builder.addDocument(
                DocumentBuilder()
                    .addPrinter(
                        buildTotalOrderReceipt(
                            orderData, storeName, tableNumber, storeAddress,
                            phoneNumber, businessNumber, thankYouMessage,
                            language, currency
                        )
                    )
            )

            runBlocking {
                withTimeout(30000) {
                    printer.printAsync(builder.getCommands()).await()
                }
            }
            Log.d(TAG, "Star Micronics 전체 주문 영수증 출력 성공")
            true
        } catch (e: Exception) {
            Log.e(TAG, "전체 주문 영수증 출력 실패", e)
            false
        }
    }

    override fun printOrderFromSocket(
        orderData: Map<String, Any>,
        language: String,
        currency: String
    ): Boolean {
        val printer = starPrinter
        if (printer == null || !isConnected) {
            Log.e(TAG, "프린터가 연결되지 않았습니다")
            return false
        }

        return try {
            Log.d(TAG, "주문 알림 영수증 출력 시작 (Star Micronics)")

            val builder = StarXpandCommandBuilder()
            builder.addDocument(
                DocumentBuilder()
                    .addPrinter(
                        buildOrderNotificationReceipt(orderData, language, currency)
                    )
            )

            runBlocking {
                withTimeout(30000) {
                    printer.printAsync(builder.getCommands()).await()
                }
            }
            Log.d(TAG, "Star Micronics 주문 알림 영수증 출력 성공")
            true
        } catch (e: Exception) {
            Log.e(TAG, "주문 알림 영수증 출력 실패", e)
            false
        }
    }

    override fun printText(
        text: String,
        fontSize: Float,
        isBold: Boolean,
        align: String
    ): Boolean {
        val printer = starPrinter
        if (printer == null || !isConnected) {
            Log.e(TAG, "프린터가 연결되지 않았습니다")
            return false
        }

        return try {
            Log.d(TAG, "텍스트 출력 시작 (Star Micronics): $text")

            val alignment = when (align.uppercase()) {
                "CENTER" -> Alignment.Center
                "RIGHT" -> Alignment.Right
                else -> Alignment.Left
            }

            val magnification = when {
                fontSize >= 40f -> MagnificationParameter(2, 2)
                fontSize >= 30f -> MagnificationParameter(2, 1)
                else -> MagnificationParameter(1, 1)
            }

            val builder = StarXpandCommandBuilder()
            builder.addDocument(
                DocumentBuilder().addPrinter(
                    PrinterBuilder()
                        .styleAlignment(alignment)
                        .styleMagnification(magnification)
                        .apply { if (isBold) styleBold(true) }
                        .actionPrintText(text + "\n")
                        .actionFeedLine(2)
                        .actionCut(CutType.Partial)
                )
            )

            runBlocking {
                withTimeout(30000) {
                    printer.printAsync(builder.getCommands()).await()
                }
            }
            Log.d(TAG, "Star Micronics 텍스트 출력 성공")
            true
        } catch (e: Exception) {
            Log.e(TAG, "텍스트 출력 실패", e)
            false
        }
    }

    override fun startConnectionMonitoring(
        eventSink: EventChannel.EventSink?,
        onConnectionLost: ((reason: String) -> Unit)?,
        onConnectionRestored: (() -> Unit)?
    ) {
        this.eventSink = eventSink
        stopConnectionMonitoring()

        monitoringJob = CoroutineScope(Dispatchers.IO).launch {
            Log.i(TAG, "Star Micronics 프린터 연결 모니터링 시작")

            while (isActive && isConnected) {
                delay(MONITORING_INTERVAL_MS)

                // StarPrinter의 상태 확인 (간단한 체크)
                if (starPrinter == null) {
                    isConnected = false
                    onConnectionLost?.invoke("PRINTER_UNAVAILABLE")
                    break
                }
            }
        }
    }

    override fun stopConnectionMonitoring() {
        monitoringJob?.cancel()
        monitoringJob = null
        Log.i(TAG, "Star Micronics 프린터 연결 모니터링 중지")
    }

    override fun cleanup() {
        stopConnectionMonitoring()
        disconnect()
    }

    // ========== Private Helper Methods ==========

    /**
     * 단일 주문 영수증 빌드
     */
    private fun buildSingleOrderReceipt(
        orderData: Map<String, Any>,
        storeName: String,
        tableNumber: String?,
        storeAddress: String?,
        phoneNumber: String?,
        businessNumber: String?,
        thankYouMessage: String?,
        language: String,
        currency: String,
        showStoreLabel: Boolean
    ): PrinterBuilder {
        val printerBuilder = PrinterBuilder()

        // 헤더 - 매장명
        printerBuilder
            .styleAlignment(Alignment.Center)
            .styleMagnification(MagnificationParameter(2, 2))
            .styleBold(true)
            .actionPrintText("$storeName\n")
            .styleBold(false)
            .styleMagnification(MagnificationParameter(1, 1))
            .actionFeedLine(1)

        // 매장 정보
        printerBuilder.styleAlignment(Alignment.Center)
        storeAddress?.let { printerBuilder.actionPrintText("$it\n") }
        phoneNumber?.let { printerBuilder.actionPrintText("TEL: $it\n") }
        businessNumber?.let { printerBuilder.actionPrintText("Business No: $it\n") }
        printerBuilder.actionFeedLine(1)

        // 구분선
        printerBuilder
            .styleAlignment(Alignment.Left)
            .actionPrintText("${"-".repeat(48)}\n")

        // 주문 아이템 파싱 및 출력
        val orderVersions = orderData["orderVersion"] as? List<Map<String, Any>>
        if (!orderVersions.isNullOrEmpty()) {
            val firstVersion = orderVersions[0]
            val orderItems = firstVersion["orderItems"] as? List<Map<String, Any>>

            orderItems?.forEach { item ->
                val menuName = item["menuName"] as? String ?: ""
                val quantity = item["quantity"] as? Int ?: 0
                val price = item["price"] as? Int ?: 0
                val totalPrice = price * quantity

                // 메뉴명 + 수량 (왼쪽 정렬)
                printerBuilder
                    .styleAlignment(Alignment.Left)
                    .actionPrintText("$menuName x$quantity\n")

                // 가격 (오른쪽 정렬)
                printerBuilder
                    .styleAlignment(Alignment.Right)
                    .actionPrintText("${formatCurrency(totalPrice, currency)}\n")
                    .styleAlignment(Alignment.Left)

                // 옵션 출력
                val options = item["options"] as? List<Map<String, Any>>
                options?.forEach { option ->
                    val selectedItems = option["selectedItems"] as? List<Map<String, Any>>
                    selectedItems?.forEach { selected ->
                        val itemName = selected["itemName"] as? String ?: ""
                        val itemPrice = selected["itemPrice"] as? Int ?: 0
                        val itemQuantity = selected["quantity"] as? Int ?: 0

                        if (itemPrice > 0) {
                            // 옵션명 + 수량
                            printerBuilder.actionPrintText("  + $itemName x$itemQuantity\n")
                            // 옵션 가격 (오른쪽 정렬)
                            printerBuilder
                                .styleAlignment(Alignment.Right)
                                .actionPrintText("${formatCurrency(itemPrice * itemQuantity, currency)}\n")
                                .styleAlignment(Alignment.Left)
                        } else {
                            printerBuilder.actionPrintText("  + $itemName\n")
                        }
                    }
                }
            }
        }

        // 구분선
        printerBuilder.actionPrintText("${"-".repeat(48)}\n")

        // 합계
        val totalPrice = orderData["totalPrice"] as? Int ?: 0
        printerBuilder
            .styleAlignment(Alignment.Left)
            .styleMagnification(MagnificationParameter(1, 1))
            .styleBold(true)
            .actionPrintText("TOTAL\n")
        printerBuilder
            .styleAlignment(Alignment.Right)
            .actionPrintText("${formatCurrency(totalPrice, currency)}\n")
            .styleBold(false)
            .styleAlignment(Alignment.Left)

        // 감사 메시지
        thankYouMessage?.let {
            printerBuilder
                .actionFeedLine(2)
                .styleAlignment(Alignment.Center)
                .actionPrintText("$it\n")
        }

        // 용지 자르기
        printerBuilder
            .actionFeedLine(3)
            .actionCut(CutType.Partial)

        return printerBuilder
    }

    /**
     * 전체 주문 영수증 빌드 (누적 주문)
     */
    private fun buildTotalOrderReceipt(
        orderData: Map<String, Any>,
        storeName: String,
        tableNumber: String?,
        storeAddress: String?,
        phoneNumber: String?,
        businessNumber: String?,
        thankYouMessage: String?,
        language: String,
        currency: String
    ): PrinterBuilder {
        val printerBuilder = PrinterBuilder()

        // 디버그: 전체 orderData 출력
        Log.d(TAG, "===== buildTotalOrderReceipt 시작 =====")
        Log.d(TAG, "orderData keys: ${orderData.keys}")
        Log.d(TAG, "orderData: $orderData")

        // 헤더 - 매장명
        printerBuilder
            .styleAlignment(Alignment.Center)
            .styleMagnification(MagnificationParameter(2, 2))
            .styleBold(true)
            .actionPrintText("$storeName\n")
            .styleBold(false)
            .styleMagnification(MagnificationParameter(1, 1))
            .actionFeedLine(1)

        // 매장 정보
        printerBuilder.styleAlignment(Alignment.Center)
        storeAddress?.let { printerBuilder.actionPrintText("$it\n") }
        phoneNumber?.let { printerBuilder.actionPrintText("TEL: $it\n") }
        businessNumber?.let { printerBuilder.actionPrintText("Business No: $it\n") }
        printerBuilder.actionFeedLine(1)

        // 테이블 번호
        tableNumber?.let {
            printerBuilder
                .styleAlignment(Alignment.Center)
                .styleMagnification(MagnificationParameter(2, 2))
                .styleBold(true)
                .actionPrintText("Table $it\n")
                .styleBold(false)
                .styleMagnification(MagnificationParameter(1, 1))
                .actionFeedLine(1)
        }

        // 구분선
        printerBuilder
            .styleAlignment(Alignment.Left)
            .actionPrintText("${"-".repeat(48)}\n")

        // 누적 주문 아이템 파싱 및 출력 (orderMenus 구조)
        val orderMenus = orderData["orderMenus"] as? List<Map<String, Any>>
        Log.d(TAG, "orderMenus: $orderMenus")
        Log.d(TAG, "orderMenus size: ${orderMenus?.size}")

        if (!orderMenus.isNullOrEmpty()) {
            orderMenus.forEach { menu ->
                val menuName = menu["menuName"] as? String ?: ""
                val quantity = menu["quantity"] as? Int ?: 0
                val price = (menu["price"] as? Number)?.toInt() ?: 0

                // 메뉴명 길이 제한 (20자)
                val displayName = if (menuName.length > 20) menuName.take(20) + "..." else menuName
                val menuText = "$displayName x$quantity"
                val priceText = formatCurrency(price, currency)

                // 메뉴명과 가격을 같은 줄에
                val lineWidth = 48
                val spacingCount = maxOf(1, lineWidth - menuText.length - priceText.length)
                val spacing = " ".repeat(spacingCount)

                printerBuilder
                    .styleAlignment(Alignment.Left)
                    .actionPrintText(menuText + spacing + priceText + "\n")

                // 옵션 출력
                val menuOptionItems = menu["menuOptionItems"] as? List<Map<String, Any>>
                menuOptionItems?.forEach { optionGroup ->
                    val selectedItems = optionGroup["selectedItems"] as? List<Map<String, Any>>
                    selectedItems?.forEach { selectedItem ->
                        // 필드명이 다를 수 있으므로 두 가지 시도
                        val itemName = selectedItem["menuOptionItemDetailName"] as? String
                            ?: selectedItem["itemName"] as? String ?: ""
                        val itemPrice = (selectedItem["menuOptionItemDetailPrice"] as? Number)?.toInt()
                            ?: (selectedItem["itemPrice"] as? Number)?.toInt() ?: 0
                        val itemQuantity = selectedItem["menuOptionItemDetailQuantity"] as? Int
                            ?: selectedItem["quantity"] as? Int ?: 0

                        if (itemPrice > 0) {
                            // 옵션 텍스트
                            val optionText = "  + $itemName x$itemQuantity"
                            val optionPriceText = formatCurrency(itemPrice * itemQuantity, currency)
                            val optionSpacingCount = maxOf(1, lineWidth - optionText.length - optionPriceText.length)
                            val optionSpacing = " ".repeat(optionSpacingCount)
                            printerBuilder.actionPrintText(optionText + optionSpacing + optionPriceText + "\n")
                        } else {
                            printerBuilder.actionPrintText("  + $itemName\n")
                        }
                    }
                }
            }
        }

        // 구분선
        printerBuilder.actionPrintText("${"-".repeat(48)}\n")

        // 합계
        val totalPrice = (orderData["totalPrice"] as? Number)?.toInt() ?: 0
        Log.d(TAG, "buildTotalOrderReceipt - totalPrice: $totalPrice")

        printerBuilder
            .styleAlignment(Alignment.Left)
            .styleMagnification(MagnificationParameter(1, 1))
            .styleBold(true)
            .actionPrintText("TOTAL\n")
        printerBuilder
            .styleAlignment(Alignment.Right)
            .actionPrintText("${formatCurrency(totalPrice, currency)}\n")
            .styleBold(false)
            .styleAlignment(Alignment.Left)

        // 감사 메시지
        thankYouMessage?.let {
            printerBuilder
                .actionFeedLine(2)
                .styleAlignment(Alignment.Center)
                .actionPrintText("$it\n")
        }

        // 용지 자르기
        printerBuilder
            .actionFeedLine(3)
            .actionCut(CutType.Partial)

        return printerBuilder
    }

    /**
     * 주문 알림 영수증 빌드
     */
    private fun buildOrderNotificationReceipt(
        orderData: Map<String, Any>,
        language: String,
        currency: String
    ): PrinterBuilder {
        val printerBuilder = PrinterBuilder()

        // 다국어 텍스트
        fun getLocalizedText(key: String): String {
            return when (language) {
                "eng" -> when (key) {
                    "table" -> "Table"
                    "order_create" -> "Order  Added"
                    "order_update" -> "Order  Updated"
                    "order_cancelled" -> "Order  Cancelled"
                    "option" -> "Option/"
                    else -> key
                }
                "jpn" -> when (key) {
                    "table" -> "テーブル"
                    "order_create" -> "注文  追加"
                    "order_update" -> "注文  変更"
                    "order_cancelled" -> "注文  取消"
                    "option" -> "オプション/"
                    else -> key
                }
                else -> when (key) { // "kor"
                    "table" -> "테이블"
                    "order_create" -> "주문  추가"
                    "order_update" -> "주문  변경"
                    "order_cancelled" -> "주문  취소"
                    "option" -> "옵션/"
                    else -> key
                }
            }
        }

        // 주문 정보 추출
        val orderType = orderData["orderType"] as? String ?: "CREATE"
        val tableNumber = orderData["tableNumber"] as? Int ?: 0
        val items = orderData["items"] as? List<Map<String, Any>> ?: emptyList()

        // 날짜/시간 출력
        val dateFormat = when (language) {
            "jpn" -> SimpleDateFormat("M月d日 (E) HH:mm", Locale.JAPANESE)
            "eng" -> SimpleDateFormat("MMM d (E) HH:mm", Locale.ENGLISH)
            else -> SimpleDateFormat("M월 d일 (E) HH:mm", Locale.KOREAN)
        }
        val dateString = dateFormat.format(Date())

        printerBuilder
            .styleAlignment(Alignment.Left)
            .actionPrintText("$dateString\n\n")

        // 테이블 번호 (박스)
        printerBuilder
            .styleAlignment(Alignment.Center)
            .actionPrintText("┌──────────────┐\n")
            .styleBold(true)
            .styleMagnification(MagnificationParameter(2, 2))
            .actionPrintText("│ ${getLocalizedText("table")} $tableNumber │\n")
            .styleMagnification(MagnificationParameter(1, 1))
            .styleBold(false)
            .actionPrintText("└──────────────┘\n\n")

        // 주문 타입
        val orderTypeText = when (orderType) {
            "CREATE" -> getLocalizedText("order_create")
            "UPDATE" -> getLocalizedText("order_update")
            "CANCELLED" -> getLocalizedText("order_cancelled")
            else -> orderType
        }

        printerBuilder
            .styleAlignment(Alignment.Left)
            .styleBold(true)
            .styleMagnification(MagnificationParameter(2, 2))
            .actionPrintText("$orderTypeText\n")
            .styleMagnification(MagnificationParameter(1, 1))
            .styleBold(false)

        // 구분선
        printerBuilder.actionPrintText("-".repeat(48) + "\n")

        // 메뉴 아이템 출력
        for (item in items) {
            val menuName = item["menuName"] as? String ?: ""
            val quantity = item["quantity"] as? Int ?: 1
            val itemOptions = item["itemOptions"] as? List<Map<String, Any>> ?: emptyList()

            // 메뉴명 + 수량
            printerBuilder
                .styleBold(true)
                .actionPrintText("$menuName x $quantity\n")
                .styleBold(false)

            // 옵션 출력
            for (option in itemOptions) {
                val optionName = option["name"] as? String ?: ""
                val optionDetails = option["optionDetails"] as? List<Map<String, Any>> ?: emptyList()

                val detailNames = optionDetails.mapNotNull { detail ->
                    val detailName = detail["name"] as? String
                    val detailQuantity = detail["quantity"] as? Int ?: 1
                    if (detailQuantity > 1) "$detailName x$detailQuantity" else detailName
                }.joinToString(", ")

                if (detailNames.isNotEmpty()) {
                    printerBuilder.actionPrintText("${getLocalizedText("option")} $optionName : $detailNames\n")
                }
            }
        }

        // 용지 자르기
        printerBuilder
            .actionFeedLine(3)
            .actionCut(CutType.Partial)

        return printerBuilder
    }

    /**
     * 화폐 포맷팅
     */
    private fun formatCurrency(amount: Int, currency: String): String {
        return when (currency.uppercase()) {
            "KRW" -> "${String.format("%,d", amount)}원"
            "USD" -> "$${String.format("%.2f", amount / 100.0)}"
            "JPY" -> "¥${String.format("%,d", amount)}"
            else -> "${String.format("%,d", amount)} $currency"
        }
    }
}
