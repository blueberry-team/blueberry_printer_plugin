package com.example.blueberry_printer.order_notification

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
 * 소켓으로 받은 주문 알림을 출력하는 클래스
 * Figma 디자인 기반 (node-id: 2774-436)
 */
object OrderNotificationPrinter {
    private const val TAG = "OrderNotificationPrinter"

    /**
     * 주문 알림 데이터를 출력
     * @param outputStream 프린터 출력 스트림
     * @param orderData 주문 알림 데이터
     * @param language 언어 (기본값: "kor")
     * @param currency 화폐 단위 (기본값: "KRW")
     */
    fun print(
        outputStream: OutputStream,
        orderData: Map<String, Any>,
        language: String = "kor",
        currency: String = "KRW"
    ) {
        try {
            // 프린터 초기화
            outputStream.write(PrinterCommands.POS_Set_PrtInit())
            Log.d(TAG, "프린터 초기화 완료")

            // 다국어 텍스트 가져오기
            val localizer = Localizer(language)

            // 주문 기본 정보 추출
            val orderBy = orderData["orderBy"] as? String ?: "ADMIN"
            val tableNumber = orderData["tableNumber"] as? Int ?: 0
            val orderAt = orderData["orderAt"] as? String ?: ""
            val orderType = orderData["orderType"] as? String ?: "CREATE"
            val items = orderData["items"] as? List<Map<String, Any>> ?: emptyList()

            // 날짜/시간 출력
            printDateTime(outputStream, orderAt, language)

            // 테이블 번호 출력 (박스로 강조)
            printTableNumber(outputStream, tableNumber, localizer)

            // 주문 타입 출력 (주문 추가, 주문 변경 등)
            printOrderType(outputStream, orderType, localizer)

            // 구분선 출력
            printSeparator(outputStream)

            // 메뉴 아이템 목록 출력
            printMenuItems(outputStream, items, localizer)

            // 영수증 자르기
            cutPaper(outputStream)

            Log.d(TAG, "주문 알림 출력 완료")

        } catch (e: Exception) {
            Log.e(TAG, "주문 알림 출력 실패", e)
            throw e
        }
    }

    /**
     * 날짜/시간 출력 (작은 글씨, 다국어)
     * 예: 10月9日 (月) 14:43
     */
    private fun printDateTime(outputStream: OutputStream, orderAt: String, language: String) {
        // ISO 8601 형식의 날짜를 파싱하여 원하는 형식으로 변환
        val dateTime = try {
            val inputFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.getDefault())
            val date = inputFormat.parse(orderAt) ?: Date()

            val outputFormat = when (language) {
                "eng" -> SimpleDateFormat("MMM d (E) HH:mm", Locale.ENGLISH)
                "jpn" -> SimpleDateFormat("M月d日 (E) HH:mm", Locale.JAPANESE)
                else -> SimpleDateFormat("M월 d일 (E) HH:mm", Locale.KOREAN)
            }
            outputFormat.format(date)
        } catch (e: Exception) {
            Log.w(TAG, "날짜 파싱 실패, 원본 사용: $orderAt", e)
            orderAt
        }

        val image = KoreanTextRenderer.createTextImage(
            dateTime,
            24f, // 날짜 (16f * 1.5)
            false,
            KoreanTextRenderer.TextAlign.LEFT
        )
        val bitmap = KoreanTextRenderer.convertToBitmap(image)
        outputStream.write(bitmap)
        outputStream.flush()

        feedPaper(outputStream, 1)
    }

    /**
     * 주문 타입 출력 (굵게, 큰 글씨, 다국어)
     * CREATE -> "주문 추가" / "Order Added" / "注文追加"
     */
    private fun printOrderType(outputStream: OutputStream, orderType: String, localizer: Localizer) {
        val typeText = when (orderType) {
            "CREATE" -> localizer.getText("order_create")
            "UPDATE" -> localizer.getText("order_update")
            "CANCELLED" -> localizer.getText("order_cancelled")
            "FULL_CANCELLED" -> localizer.getText("order_full_cancelled")
            "CALCULATED" -> localizer.getText("order_calculated")
            else -> "${localizer.getText("order")}  $orderType"
        }

        val image = KoreanTextRenderer.createTextImage(
            typeText,
            42f, // 주문 타입 (28f * 1.5)
            true, // 굵게
            KoreanTextRenderer.TextAlign.LEFT
        )
        val bitmap = KoreanTextRenderer.convertToBitmap(image)
        outputStream.write(bitmap)
        outputStream.flush()

        feedPaper(outputStream, 1)
    }

    /**
     * 테이블 번호 출력 (박스로 강조, 다국어)
     */
    private fun printTableNumber(outputStream: OutputStream, tableNumber: Int, localizer: Localizer) {
        // 테이블 번호
        val tableText = "${localizer.getText("table")} $tableNumber"
        val tableImage = KoreanTextRenderer.createTextImage(
            tableText,
            42f, // 테이블 번호 (28f * 1.5)
            true, // 굵게
            KoreanTextRenderer.TextAlign.CENTER
        )
        outputStream.write(KoreanTextRenderer.convertToBitmap(tableImage))
        outputStream.flush()
        feedPaper(outputStream, 1)
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

        feedPaper(outputStream, 1)
    }

    /**
     * 메뉴 아이템 목록 출력 (다국어)
     */
    private fun printMenuItems(
        outputStream: OutputStream,
        items: List<Map<String, Any>>,
        localizer: Localizer
    ) {
        for (item in items) {
            val menuName = item["menuName"] as? String ?: localizer.getText("no_menu_name")
            val quantity = item["quantity"] as? Int ?: 0
            val itemOptions = item["itemOptions"] as? List<Map<String, Any>> ?: emptyList()

            // 메뉴명과 수량을 한 줄에 출력
            printMenuItem(outputStream, menuName, quantity)

            // 옵션이 있으면 출력
            if (itemOptions.isNotEmpty()) {
                printMenuItemOptions(outputStream, itemOptions, localizer)
            }
        }
    }

    /**
     * 메뉴 아이템 (메뉴명 + 수량) 출력
     * 예: 아메리카노 (ICE) x 2
     */
    private fun printMenuItem(
        outputStream: OutputStream,
        menuName: String,
        quantity: Int
    ) {
        // 메뉴명과 수량을 같은 줄에 출력
        val menuText = "$menuName x $quantity"
        val menuImage = KoreanTextRenderer.createTextImage(
            menuText,
            36f, // 메뉴명 (24f * 1.5)
            true,
            KoreanTextRenderer.TextAlign.LEFT
        )
        val menuBitmap = KoreanTextRenderer.convertToBitmap(menuImage)
        outputStream.write(menuBitmap)
        outputStream.flush()

        feedPaper(outputStream, 1)
    }

    /**
     * 메뉴 아이템 옵션 목록 출력 (다국어)
     * 예:
     * 옵션/ 맵기 : 중간맛
     * Option/ Spicy : Medium
     */
    private fun printMenuItemOptions(
        outputStream: OutputStream,
        itemOptions: List<Map<String, Any>>,
        localizer: Localizer
    ) {
        val sb = StringBuilder()
        val optionPrefix = localizer.getText("option")

        for (option in itemOptions) {
            val optionName = option["name"] as? String ?: localizer.getText("no_option_name")
            val optionDetails = option["optionDetails"] as? List<Map<String, Any>> ?: emptyList()

            // 옵션 상세 정보를 콤마로 구분하여 출력
            val detailNames = optionDetails.mapNotNull { detail ->
                val detailName = detail["name"] as? String
                val detailQuantity = detail["quantity"] as? Int ?: 1

                if (detailQuantity > 1) {
                    "$detailName x$detailQuantity"
                } else {
                    detailName
                }
            }.joinToString(", ")

            if (detailNames.isNotEmpty()) {
                sb.append("$optionPrefix $optionName : $detailNames\n")
            }
        }

        if (sb.isNotEmpty()) {
            val image = KoreanTextRenderer.createTextImage(
                sb.toString().trim(),
                28f, // 옵션
                false,
                KoreanTextRenderer.TextAlign.LEFT
            )
            val bitmap = KoreanTextRenderer.convertToBitmap(image)
            outputStream.write(bitmap)
            outputStream.flush()
        }
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
     * 다국어 지원을 위한 헬퍼 클래스
     */
    private class Localizer(private val language: String) {
        fun getText(key: String): String {
            return when (language) {
                "eng" -> when (key) {
                    "table" -> "Table"
                    "order" -> "Order"
                    "order_create" -> "Order  Added"
                    "order_update" -> "Order  Updated"
                    "order_cancelled" -> "Order  Cancelled"
                    "order_full_cancelled" -> "Full  Cancelled"
                    "order_calculated" -> "Payment  Done"
                    "option" -> "Option/"
                    "no_menu_name" -> "No menu name"
                    "no_option_name" -> "No option name"
                    else -> key
                }
                "jpn" -> when (key) {
                    "table" -> "テーブル"
                    "order" -> "注文"
                    "order_create" -> "注文  追加"
                    "order_update" -> "注文  変更"
                    "order_cancelled" -> "注文  取消"
                    "order_full_cancelled" -> "全体  取消"
                    "order_calculated" -> "会計  完了"
                    "option" -> "オプション/"
                    "no_menu_name" -> "メニュー名なし"
                    "no_option_name" -> "オプション名なし"
                    else -> key
                }
                else -> when (key) { // "kor" (기본값)
                    "table" -> "테이블"
                    "order" -> "주문"
                    "order_create" -> "주문  추가"
                    "order_update" -> "주문  변경"
                    "order_cancelled" -> "주문  취소"
                    "order_full_cancelled" -> "전체  취소"
                    "order_calculated" -> "계산  완료"
                    "option" -> "옵션/"
                    "no_menu_name" -> "메뉴명 없음"
                    "no_option_name" -> "옵션명 없음"
                    else -> key
                }
            }
        }
    }
}
