package com.example.blueberry_printer.multiple_order

import java.io.OutputStream
import android.util.Log
import com.example.blueberry_printer.common.EscPosConstants
import com.example.blueberry_printer.common.PrinterCommands
import com.example.blueberry_printer.common.KoreanTextRenderer
import com.example.blueberry_printer.common.PrintConstants
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * 전체 주문(누적) 영수증을 텍스트 파싱 없이 직접 출력하는 클래스
 */
object MultipleOrderDirectPrinter {
    private const val TAG = "MultipleOrderDirectPrinter"

    /**
     * 전체 주문 데이터를 직접 출력 (텍스트 파싱 방식 없이)
     * @param outputStream 프린터 출력 스트림
     * @param orderData 주문 데이터 (모든 버전 포함)
     * @param storeName 매장명
     * @param tableNumber 테이블 번호 (선택사항)
     * @param storeAddress 매장 주소 (선택사항)
     * @param phoneNumber 전화번호 (선택사항)
     * @param businessNumber 사업자등록번호 (선택사항)
     * @param thankYouMessage 감사 메시지 (선택사항)
     * @param language 언어 (기본값: "kor")
     * @param currency 화폐 단위 (기본값: "KRW")
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
        currency: String = "KRW"
    ) {
        try {
            // 프린터 초기화
            outputStream.write(PrinterCommands.POS_Set_PrtInit())
            Log.d(TAG, "프린터 초기화 완료")

            // 다국어 텍스트 가져오기
            val localizer = Localizer(language)

            // API 응답에서 제공하는 총 금액 사용
            val grandTotalPrice = (orderData["totalPrice"] as? Number)?.toDouble() ?: 0.0
            Log.d(TAG, "응답에서 제공된 총 가격: $grandTotalPrice")

            // orderVersion이 없고 orderMenus가 있는 경우(Flutter 모델 구조)
            var orderVersions = orderData["orderVersion"] as? List<Map<String, Any>>
            if (orderVersions == null && orderData.containsKey("orderMenus")) {
                Log.d(TAG, "Flutter 모델 구조 감지: orderMenus 필드 처리 중")
                val orderMenus = orderData["orderMenus"] as? List<Map<String, Any>> ?: emptyList()

                // orderMenus를 orderItems로 변환하여 orderVersion 생성
                val orderItems = mutableListOf<Map<String, Any>>()
                for (menu in orderMenus) {
                    orderItems.add(menu)
                }

                // 단일 버전 orderVersion 생성
                orderVersions = listOf(mapOf("orderItems" to orderItems))
            } else if (orderVersions == null) {
                orderVersions = emptyList()
            }

            Log.d(TAG, "누적 주문 처리 시작 - 버전 수: ${orderVersions.size}")

            // 날짜/시간 출력 (현재 시간)
            printDateTime(outputStream, language)

            // 테이블 번호 출력 (박스로 강조) - 파라미터로 받은 값 사용
            if (tableNumber != null) {
                printTableNumber(outputStream, tableNumber)
            }

            // 타이틀 출력 (매장명)
            printTitle(outputStream, storeName)

            // 매장정보 출력
            printStoreInfo(outputStream, storeAddress, phoneNumber, businessNumber, localizer)

            // 구분선 출력
            printSeparator(outputStream)

            // 누적 상품 목록 출력
            printMergedMenuList(outputStream, orderVersions, currency, localizer)

            // 총 합계 출력
            printGrandTotal(outputStream, grandTotalPrice, currency, localizer)

            // 감사 메시지 출력
            printThankYouMessage(outputStream, thankYouMessage, localizer)

            // 줄바꿈
            feedPaper(outputStream, PrintConstants.LineFeed.AFTER_THANK_YOU)

            // 영수증 자르기
            cutPaper(outputStream)

            Log.d(TAG, "전체 주문 영수증 출력 완료")

        } catch (e: Exception) {
            Log.e(TAG, "전체 주문 영수증 출력 실패", e)
            throw e
        }
    }

    /**
     * 날짜/시간 출력 (현재 시간, 다국어)
     */
    private fun printDateTime(outputStream: OutputStream, language: String) {
        val currentDate = Date()
        val dateFormat = when (language) {
            "eng" -> SimpleDateFormat("MMM d (E) HH:mm", Locale.ENGLISH)
            "jpn" -> SimpleDateFormat("M月d日 (E) HH:mm", Locale.JAPANESE)
            else -> SimpleDateFormat("M월 d일 (E) HH:mm", Locale.KOREAN) // "kor" 기본값
        }

        val formattedDate = dateFormat.format(currentDate)

        val image = KoreanTextRenderer.createTextImage(
            formattedDate,
            24f, // 날짜 (소켓과 동일)
            false,
            KoreanTextRenderer.TextAlign.LEFT
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
            42f, // 소켓 메뉴 크기와 동일
            true,
            KoreanTextRenderer.TextAlign.CENTER
        )
        val bitmap = KoreanTextRenderer.convertToBitmap(image)
        outputStream.write(bitmap)
        outputStream.flush()
    }

    /**
     * 테이블 번호 출력 (박스로 강조)
     */
    private fun printTableNumber(outputStream: OutputStream, tableNumber: String) {
        // 박스 윗부분
        val boxTop = "┌──────────────┐"
        val boxTopImage = KoreanTextRenderer.createTextImage(
            boxTop,
            32f,
            false,
            KoreanTextRenderer.TextAlign.CENTER
        )
        outputStream.write(KoreanTextRenderer.convertToBitmap(boxTopImage))
        outputStream.flush()

        // 테이블 번호 (박스 중간)
        val tableText = "│  테이블 $tableNumber  │"
        val tableImage = KoreanTextRenderer.createTextImage(
            tableText,
            42f, // 소켓 메뉴 크기와 동일
            true, // 굵게
            KoreanTextRenderer.TextAlign.CENTER
        )
        outputStream.write(KoreanTextRenderer.convertToBitmap(tableImage))
        outputStream.flush()

        // 박스 아랫부분
        val boxBottom = "└──────────────┘"
        val boxBottomImage = KoreanTextRenderer.createTextImage(
            boxBottom,
            32f,
            false,
            KoreanTextRenderer.TextAlign.CENTER
        )
        outputStream.write(KoreanTextRenderer.convertToBitmap(boxBottomImage))
        outputStream.flush()
    }

    /**
     * 매장정보 출력 (주소만)
     */
    private fun printStoreInfo(
        outputStream: OutputStream,
        storeAddress: String?,
        phoneNumber: String?,
        businessNumber: String?,
        localizer: Localizer
    ) {
        if (storeAddress != null) {
            val image = KoreanTextRenderer.createTextImage(
                storeAddress,
                28f, // 소켓 옵션 크기와 동일
                false,
                KoreanTextRenderer.TextAlign.CENTER
            )
            val bitmap = KoreanTextRenderer.convertToBitmap(image)
            outputStream.write(bitmap)
            outputStream.flush()
        }
    }

    /**
     * 구분선 출력
     */
    private fun printSeparator(outputStream: OutputStream) {
        val image = KoreanTextRenderer.createTextImage(
            PrintConstants.SEPARATOR_LINE,
            PrintConstants.FontSize.SEPARATOR,
            false,
            KoreanTextRenderer.TextAlign.CENTER
        )
        val bitmap = KoreanTextRenderer.convertToBitmap(image)
        outputStream.write(bitmap)
        outputStream.flush()
    }

    /**
     * 누적 상품 목록 출력 (모든 버전 합치기)
     */
    private fun printMergedMenuList(
        outputStream: OutputStream,
        orderVersions: List<Map<String, Any>>,
        currency: String,
        localizer: Localizer
    ) {
        val sb = StringBuilder()
        val currencySymbol = getCurrencySymbol(currency)

        // 모든 버전의 상품을 합치기 위한 Map (메뉴명 + 옵션 조합을 기준으로)
        val mergedItems = mutableMapOf<String, MutableMap<String, Any>>()

        // 모든 버전의 상품 수집
        for (version in orderVersions) {
            val orderItems = version["orderItems"] as? List<Map<String, Any>> ?: emptyList()

            for (item in orderItems) {
                val menuName = item["menuName"] as? String ?: "상품명 없음"
                val quantity = item["quantity"] as? Int ?: 0
                val basePrice = (item["price"] as? Number)?.toDouble() ?: 0.0

                // 옵션 정보를 포함한 고유 키 생성
                // Flutter 모델에서는 menuOptionItems 필드를 사용하고 네이티브에서는 options 필드를 사용함
                val options = when {
                    item.containsKey("options") -> item["options"] as? List<Map<String, Any>>
                    item.containsKey("menuOptionItems") -> item["menuOptionItems"] as? List<Map<String, Any>>
                    else -> null
                } ?: emptyList()

                Log.d(TAG, "옵션 처리: 메뉴=$menuName, 옵션 개수=${options.size}")
                val optionKey = StringBuilder()
                var optionTotalPrice = 0.0

                for (option in options) {
                    val selectedItems = option["selectedItems"] as? List<Map<String, Any>> ?: emptyList()
                    for (selectedItem in selectedItems) {
                        // Flutter 모델과 네이티브 코드 필드명 차이 처리
                        val optionName = selectedItem["itemName"] as? String
                            ?: selectedItem["menuOptionItemDetailName"] as? String
                            ?: ""

                        val optionPrice = (selectedItem["itemPrice"] as? Number)?.toDouble()
                            ?: (selectedItem["menuOptionItemDetailPrice"] as? Number)?.toDouble()
                            ?: 0.0

                        val optionQuantity = selectedItem["quantity"] as? Int
                            ?: selectedItem["menuOptionItemDetailQuantity"] as? Int
                            ?: 0

                        Log.d(TAG, "옵션 값 처리: 메뉴=$menuName, 옵션=$optionName, 가격=$optionPrice, 수량=$optionQuantity")

                        if (optionPrice > 0) {
                            optionKey.append("|$optionName:$optionQuantity")
                            optionTotalPrice += (optionPrice * optionQuantity)
                        }
                    }
                }

                // 메뉴명 + 옵션 조합을 기준으로 한 고유 키
                val uniqueKey = "$menuName$optionKey"
                // 메뉴 가격 + 옵션 가격 합산
                val price = (item["price"] as? Number)?.toDouble() ?: 0.0
                val totalItemPrice = price + optionTotalPrice
                Log.d(TAG, "[메뉴: $menuName] 기본가격: $price + 옵션가격: $optionTotalPrice = 총가격: $totalItemPrice")

                // 메뉴 아이템 합치기 (동일한 메뉴 + 옵션 조합인 경우에만)
                if (mergedItems.containsKey(uniqueKey)) {
                    val existingItem = mergedItems[uniqueKey]!!
                    existingItem["quantity"] = (existingItem["quantity"] as Int) + quantity
                    existingItem["totalPrice"] = (existingItem["totalPrice"] as Double) + totalItemPrice
                } else {
                    mergedItems[uniqueKey] = mutableMapOf(
                        "menuName" to menuName,
                        "quantity" to quantity,
                        "basePrice" to basePrice,
                        "totalPrice" to totalItemPrice,
                        "options" to options
                    )
                }
            }
        }

        // 다국어 옵션 prefix 가져오기
        val optionPrefix = localizer.getText("option")

        // 합쳐진 상품 출력
        for ((uniqueKey, itemData) in mergedItems) {
            val menuName = itemData["menuName"] as String
            val quantity = itemData["quantity"] as Int
            val totalPrice = itemData["totalPrice"] as Double
            val options = itemData["options"] as List<Map<String, Any>>

            // 메뉴 라인: 메뉴명 x수량 = 가격 형식
            sb.append("$menuName x$quantity = ${formatPrice(totalPrice, currency)}$currencySymbol\n")

            // 옵션 표시 (가격 제거)
            for (option in options) {
                val selectedItems = option["selectedItems"] as? List<Map<String, Any>> ?: emptyList()
                for (selectedItem in selectedItems) {
                    // Flutter 모델과 네이티브 코드 필드명 차이 처리
                    val optionName = selectedItem["itemName"] as? String
                        ?: selectedItem["menuOptionItemDetailName"] as? String
                        ?: "옵션명 없음"

                    val optionPrice = (selectedItem["itemPrice"] as? Number)?.toDouble()
                        ?: (selectedItem["menuOptionItemDetailPrice"] as? Number)?.toDouble()
                        ?: 0.0

                    val optionQuantity = selectedItem["quantity"] as? Int
                        ?: selectedItem["menuOptionItemDetailQuantity"] as? Int
                        ?: 0

                    Log.d(TAG, "옵션 출력: 메뉴=$menuName, 옵션=$optionName, 가격=$optionPrice, 수량=$optionQuantity")

                    // 옵션 이름만 표시 (가격 제거, 다국어)
                    if (optionQuantity > 1) {
                        sb.append("  $optionPrefix $optionName x$optionQuantity\n")
                    } else {
                        sb.append("  $optionPrefix $optionName\n")
                    }
                }
            }
        }

        // 메뉴 목록 출력
        val menuLines = StringBuilder()
        val optionLines = StringBuilder()

        val lines = sb.toString().trim().split("\n")
        for (line in lines) {
            if (line.startsWith("  $optionPrefix")) {
                // 옵션 라인
                optionLines.append(line).append("\n")
            } else {
                // 메뉴 라인
                // 이전에 쌓인 옵션이 있으면 먼저 출력
                if (optionLines.isNotEmpty()) {
                    val optionImage = KoreanTextRenderer.createTextImage(
                        optionLines.toString().trim(),
                        24f, // 옵션 크기 (28f - 4 = 24f)
                        false,
                        KoreanTextRenderer.TextAlign.LEFT
                    )
                    outputStream.write(KoreanTextRenderer.convertToBitmap(optionImage))
                    outputStream.flush()
                    optionLines.clear()
                }

                // 메뉴 라인 출력
                val menuImage = KoreanTextRenderer.createTextImage(
                    line,
                    32f, // 메뉴 크기
                    false,
                    KoreanTextRenderer.TextAlign.LEFT
                )
                outputStream.write(KoreanTextRenderer.convertToBitmap(menuImage))
                outputStream.flush()
            }
        }

        // 마지막에 남은 옵션 출력
        if (optionLines.isNotEmpty()) {
            val optionImage = KoreanTextRenderer.createTextImage(
                optionLines.toString().trim(),
                24f, // 옵션 크기 (28f - 4 = 24f)
                false,
                KoreanTextRenderer.TextAlign.LEFT
            )
            outputStream.write(KoreanTextRenderer.convertToBitmap(optionImage))
            outputStream.flush()
        }
    }

    /**
     * 총 합계 출력
     */
    private fun printGrandTotal(
        outputStream: OutputStream,
        grandTotalPrice: Double,
        currency: String,
        localizer: Localizer
    ) {
        val currencySymbol = getCurrencySymbol(currency)
        val totalText = "${localizer.getText("grand_total")}: ${formatPrice(grandTotalPrice, currency)}$currencySymbol"

        val image = KoreanTextRenderer.createTextImage(
            totalText,
            42f, // 소켓 메뉴 크기와 동일
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
            28f, // 소켓 옵션 크기와 동일
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
        outputStream.write(PrinterCommands.POS_Set_PrtAndFeedPaper(PrintConstants.LineFeed.BEFORE_CUT))
        outputStream.write(EscPosConstants.GS_V_n)
        outputStream.flush()
    }

    /**
     * 가격 포맷팅 (천단위 콤마)
     */
    private fun formatPrice(price: Double, currency: String): String {
        return when (currency) {
            "USD", "EUR" -> String.format("%,.2f", price)
            "KRW", "JPY" -> String.format("%,.0f", price)
            else -> String.format("%,.0f", price) // 기본값: 소수점 없음
        }
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
                    "version" -> "Version"
                    "order_time" -> "Order Time"
                    "total" -> "Total"
                    "grand_total" -> "Grand Total"
                    "option" -> "Option/"
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
                    "version" -> "バージョン"
                    "order_time" -> "注文時刻"
                    "total" -> "合計"
                    "grand_total" -> "総合計"
                    "option" -> "オプション/"
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
                    "version" -> "버전"
                    "order_time" -> "주문시간"
                    "total" -> "합계"
                    "grand_total" -> "총 합계"
                    "option" -> "옵션/"
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
