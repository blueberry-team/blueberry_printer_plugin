package com.example.blueberry_printer.single_order

import java.io.OutputStream
import android.util.Log
import com.example.blueberry_printer.common.EscPosConstants
import com.example.blueberry_printer.common.PrinterCommands
import com.example.blueberry_printer.common.KoreanTextRenderer

/**
 * 단일 주문 영수증을 텍스트 파싱 없이 직접 출력하는 클래스
 */
object SingleOrderDirectPrinter {
    private const val TAG = "SingleOrderDirectPrinter"

    /**
     * 단일 주문 데이터를 직접 출력 (텍스트 파싱 방식 없이)
     * @param outputStream 프린터 출력 스트림
     * @param orderData 주문 데이터
     * @param storeName 매장명
     * @param tableNumber 테이블 번호 (선택사항)
     * @param storeAddress 매장 주소 (선택사항)
     * @param phoneNumber 전화번호 (선택사항)
     * @param businessNumber 사업자등록번호 (선택사항)
     * @param thankYouMessage 감사 메시지 (선택사항)
     * @param language 언어 (기본값: "kor")
     * @param currency 화폐 단위 (기본값: "KRW")
     * @param showStoreLabel 점포용 라벨 표시 여부 (기본값: true)
     */
    fun print(
        outputStream: OutputStream,
        orderData: Map<String, Any>,
        storeName: String,
        tableNumber: String? = null,
        storeAddress: String? = null,
        phoneNumber: String? = null,
        businessNumber: String? = null,
        thankYouMessage: String? = null,
        language: String = "kor",
        currency: String = "KRW",
        showStoreLabel: Boolean = true
    ) {
        try {
            // 프린터 초기화
            outputStream.write(PrinterCommands.POS_Set_PrtInit())
            Log.d(TAG, "프린터 초기화 완료")

            // 다국어 텍스트 가져오기
            val localizer = Localizer(language)

            // 주문 기본 정보 추출
            val orderNumber = orderData["orderNumber"] as? String
                ?: localizer.getText("no_order_number")
            val tableName = orderData["tableName"] as? String
                ?: localizer.getText("no_table_info")

            // 총 금액 계산
            var calculatedTotalPrice = 0
            val orderVersions = orderData["orderVersion"] as? List<Map<String, Any>> ?: emptyList()

            for (version in orderVersions) {
                val orderItems = version["orderItems"] as? List<Map<String, Any>> ?: emptyList()
                for (item in orderItems) {
                    val itemPrice = item["price"] as? Int ?: 0
                    val itemQuantity = item["quantity"] as? Int ?: 0
                    calculatedTotalPrice += (itemPrice * itemQuantity)

                    // 옵션 가격 추가
                    val options = item["options"] as? List<Map<String, Any>> ?: emptyList()
                    for (option in options) {
                        val selectedItems = option["selectedItems"] as? List<Map<String, Any>> ?: emptyList()
                        for (selectedItem in selectedItems) {
                            val optionPrice = selectedItem["itemPrice"] as? Int ?: 0
                            val optionQuantity = selectedItem["quantity"] as? Int ?: 0
                            calculatedTotalPrice += (optionPrice * optionQuantity)
                        }
                    }
                }
            }

            Log.d(TAG, "계산된 총 금액: $calculatedTotalPrice")

            // 점포용 라벨 출력 (요청 시에만)
            if (showStoreLabel) {
                printStoreLabel(outputStream, localizer)
            }

            // 타이틀 출력 (매장명)
            printTitle(outputStream, storeName)

            // 매장정보 출력
            printStoreInfo(outputStream, storeAddress, phoneNumber, businessNumber, localizer)

            // 구분선 출력
            printSeparator(outputStream)

            // 주문 정보 출력
            printOrderInfo(outputStream, orderNumber, tableName, localizer)

            // 상품 목록 출력
            printMenuList(outputStream, orderVersions, currency, localizer)

            // 줄바꿈
            feedPaper(outputStream, 2)

            // 합계 출력
            printTotal(outputStream, calculatedTotalPrice, currency, localizer)

            // 줄바꿈
            feedPaper(outputStream, 2)

            // 감사 메시지 출력
            printThankYouMessage(outputStream, thankYouMessage, localizer)

            // 줄바꿈
            feedPaper(outputStream, 3)

            // 영수증 자르기
            cutPaper(outputStream)

            Log.d(TAG, "단일 주문 영수증 출력 완료")

        } catch (e: Exception) {
            Log.e(TAG, "단일 주문 영수증 출력 실패", e)
            throw e
        }
    }

    /**
     * 점포용 라벨 출력
     */
    private fun printStoreLabel(outputStream: OutputStream, localizer: Localizer) {
        val labelText = """
┌────────────────────┐
│        점포용        │
└────────────────────┘
        """.trimIndent()

        val image = KoreanTextRenderer.createTextImage(
            labelText,
            24f,
            true,
            KoreanTextRenderer.TextAlign.CENTER
        )
        val bitmap = KoreanTextRenderer.convertToBitmap(image)
        outputStream.write(bitmap)
        outputStream.flush()
    }

    /**
     * 타이틀 출력 (매장명)
     */
    private fun printTitle(outputStream: OutputStream, storeName: String) {
        val image = KoreanTextRenderer.createTextImage(
            storeName,
            80f,
            true,
            KoreanTextRenderer.TextAlign.CENTER
        )
        val bitmap = KoreanTextRenderer.convertToBitmap(image)
        outputStream.write(bitmap)
        outputStream.flush()

        feedPaper(outputStream, 1)
    }

    /**
     * 매장정보 출력
     */
    private fun printStoreInfo(
        outputStream: OutputStream,
        storeAddress: String?,
        phoneNumber: String?,
        businessNumber: String?,
        localizer: Localizer
    ) {
        val sb = StringBuilder()

        if (storeAddress != null || phoneNumber != null || businessNumber != null) {
            if (storeAddress != null) {
                sb.append("$storeAddress\n")
            }
            if (phoneNumber != null) {
                sb.append("${localizer.getText("phone")}: $phoneNumber\n")
            }
            if (businessNumber != null) {
                sb.append("${localizer.getText("business_number")}: $businessNumber\n")
            }

            val image = KoreanTextRenderer.createTextImage(
                sb.toString().trim(),
                20f,
                false,
                KoreanTextRenderer.TextAlign.CENTER
            )
            val bitmap = KoreanTextRenderer.convertToBitmap(image)
            outputStream.write(bitmap)
            outputStream.flush()

            feedPaper(outputStream, 1)
        }
    }

    /**
     * 구분선 출력
     */
    private fun printSeparator(outputStream: OutputStream) {
        val separatorText = "================================"

        val image = KoreanTextRenderer.createTextImage(
            separatorText,
            20f,
            false,
            KoreanTextRenderer.TextAlign.CENTER
        )
        val bitmap = KoreanTextRenderer.convertToBitmap(image)
        outputStream.write(bitmap)
        outputStream.flush()

        feedPaper(outputStream, 1)
    }

    /**
     * 주문 정보 출력
     */
    private fun printOrderInfo(
        outputStream: OutputStream,
        orderNumber: String,
        tableName: String,
        localizer: Localizer
    ) {
        val orderInfoText = """
${localizer.getText("order_number")}: $orderNumber
${localizer.getText("table")}: $tableName
        """.trimIndent()

        val image = KoreanTextRenderer.createTextImage(
            orderInfoText,
            20f,
            false,
            KoreanTextRenderer.TextAlign.CENTER
        )
        val bitmap = KoreanTextRenderer.convertToBitmap(image)
        outputStream.write(bitmap)
        outputStream.flush()

        feedPaper(outputStream, 1)
    }

    /**
     * 상품 목록 출력
     */
    private fun printMenuList(
        outputStream: OutputStream,
        orderVersions: List<Map<String, Any>>,
        currency: String,
        localizer: Localizer
    ) {
        val sb = StringBuilder()
        val currencySymbol = getCurrencySymbol(currency)

        for (version in orderVersions) {
            val orderItems = version["orderItems"] as? List<Map<String, Any>> ?: emptyList()

            for (item in orderItems) {
                val menuName = item["menuName"] as? String ?: "상품명 없음"
                val quantity = item["quantity"] as? Int ?: 0
                val basePrice = item["price"] as? Int ?: 0

                // 메뉴 기본 가격만 표시 (옵션 가격 제외)
                val menuTotalPrice = basePrice * quantity
                sb.append("$menuName x$quantity = ${formatPrice(menuTotalPrice)}$currencySymbol\n")

                // 옵션 상세 표시 (가격 포함)
                val options = item["options"] as? List<Map<String, Any>> ?: emptyList()
                for (option in options) {
                    val selectedItems = option["selectedItems"] as? List<Map<String, Any>> ?: emptyList()
                    for (selectedItem in selectedItems) {
                        val itemName = selectedItem["itemName"] as? String ?: "옵션명 없음"
                        val itemPrice = selectedItem["itemPrice"] as? Int ?: 0
                        val itemQuantity = selectedItem["quantity"] as? Int ?: 0

                        // 옵션 총 가격 계산
                        val optionTotalPrice = itemPrice * itemQuantity

                        // 옵션 이름과 가격 표시
                        if (itemQuantity > 1) {
                            sb.append("  - $itemName x$itemQuantity = ${formatPrice(optionTotalPrice)}$currencySymbol\n")
                        } else {
                            sb.append("  - $itemName = ${formatPrice(optionTotalPrice)}$currencySymbol\n")
                        }
                    }
                }
            }
        }

        val image = KoreanTextRenderer.createTextImage(
            sb.toString().trim(),
            20f,
            false,
            KoreanTextRenderer.TextAlign.LEFT
        )
        val bitmap = KoreanTextRenderer.convertToBitmap(image)
        outputStream.write(bitmap)
        outputStream.flush()
    }

    /**
     * 합계 출력
     */
    private fun printTotal(
        outputStream: OutputStream,
        totalPrice: Int,
        currency: String,
        localizer: Localizer
    ) {
        val currencySymbol = getCurrencySymbol(currency)
        val totalText = "${localizer.getText("total")}: ${formatPrice(totalPrice)}$currencySymbol"

        val image = KoreanTextRenderer.createTextImage(
            totalText,
            20f,
            true,
            KoreanTextRenderer.TextAlign.RIGHT
        )
        val bitmap = KoreanTextRenderer.convertToBitmap(image)
        outputStream.write(bitmap)
        outputStream.flush()
    }

    /**
     * 감사 메시지 출력
     */
    private fun printThankYouMessage(
        outputStream: OutputStream,
        thankYouMessage: String?,
        localizer: Localizer
    ) {
        val message = thankYouMessage ?: localizer.getText("thank_you_default")

        val image = KoreanTextRenderer.createTextImage(
            message,
            20f,
            false,
            KoreanTextRenderer.TextAlign.CENTER
        )
        val bitmap = KoreanTextRenderer.convertToBitmap(image)
        outputStream.write(bitmap)
        outputStream.flush()
    }

    /**
     * 줄바꿈
     */
    private fun feedPaper(outputStream: OutputStream, lines: Int = 1) {
        val feedCommand = PrinterCommands.POS_Set_PrtAndFeedPaper(lines)
        if (feedCommand != null) {
            outputStream.write(feedCommand)
        }
    }

    /**
     * 영수증 자르기
     */
    private fun cutPaper(outputStream: OutputStream) {
        outputStream.write(PrinterCommands.POS_Set_PrtAndFeedPaper(200))
        outputStream.write(EscPosConstants.GS_V_n)
        outputStream.flush()
    }

    /**
     * 가격 포맷팅 (천단위 콤마)
     */
    private fun formatPrice(price: Int): String {
        return String.format("%,d", price)
    }

    /**
     * 화폐 단위 심볼 가져오기
     */
    private fun getCurrencySymbol(currency: String): String {
        return when (currency) {
            "USD" -> "$"
            "JPY" -> "¥"
            "EUR" -> "€"
            else -> "원" // KRW 기본값
        }
    }

    /**
     * 다국어 지원을 위한 헬퍼 클래스
     */
    private class Localizer(private val language: String) {
        fun getText(key: String): String {
            return when (language) {
                "eng" -> when (key) {
                    "store_info" -> "Store Information"
                    "order_info" -> "Order Information"
                    "order_number" -> "Order No"
                    "table" -> "Table"
                    "menu_list" -> "Menu List"
                    "subtotal" -> "Subtotal"
                    "tax" -> "Tax"
                    "total" -> "Total"
                    "thank_you_default" -> "Thank you!\nPlease visit us again."
                    "phone" -> "Phone"
                    "business_number" -> "Business No"
                    "no_order_number" -> "No order number"
                    "no_table_info" -> "No table info"
                    else -> key
                }
                "jpn" -> when (key) {
                    "store_info" -> "店舗情報"
                    "order_info" -> "注文情報"
                    "order_number" -> "注文番号"
                    "table" -> "テーブル"
                    "menu_list" -> "メニューリスト"
                    "subtotal" -> "小計"
                    "tax" -> "税金"
                    "total" -> "合計"
                    "thank_you_default" -> "ありがとうございます！\nまたお越しください。"
                    "phone" -> "電話"
                    "business_number" -> "事業者番号"
                    "no_order_number" -> "注文番号なし"
                    "no_table_info" -> "テーブル情報なし"
                    else -> key
                }
                else -> when (key) { // "kor" (기본값)
                    "store_info" -> "매장정보"
                    "order_info" -> "주문정보"
                    "order_number" -> "주문번호"
                    "table" -> "테이블"
                    "menu_list" -> "상품목록"
                    "subtotal" -> "소계"
                    "tax" -> "부가세"
                    "total" -> "합계"
                    "thank_you_default" -> "감사합니다!\n다음에 또 방문해 주세요."
                    "phone" -> "전화"
                    "business_number" -> "사업자등록번호"
                    "no_order_number" -> "주문번호 없음"
                    "no_table_info" -> "테이블 정보 없음"
                    else -> key
                }
            }
        }
    }
}
