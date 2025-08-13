package com.example.blueberry_printer.logic

import java.io.OutputStream
import android.util.Log
import kotlin.text.Charsets
import com.example.blueberry_printer.hardware.HardwareEscPosConstants
import com.example.blueberry_printer.hardware.HardwareUtilities
import com.example.blueberry_printer.logic.RenderKoreanTextToImage
import com.example.blueberry_printer.data.DataSampleReceipts
import com.example.blueberry_printer.hardware.HardwarePrinterCommands

object LogicReceiptProcessor {
        private const val TAG = "LogicReceiptProcessor"
        
        /**
         * 단일 주문 데이터를 영수증 포맷으로 변환 (점포용)
         * @param orderData 주문 데이터
         * @param storeName 매장명
         * @param tableNumber 테이블 번호 (선택사항)
         * @param storeAddress 매장 주소 (선택사항)
         * @param phoneNumber 전화번호 (선택사항)
         * @param businessNumber 사업자등록번호 (선택사항)
         * @param thankYouMessage 감사 메시지 (선택사항)
         * @param showStoreLabel 점포용 라벨 표시 여부
         */
        fun formatSingleOrderReceipt(
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
        ): String {
            val sb = StringBuilder()
            
            // 다국어 텍스트 헬퍼 함수
            fun getLocalizedText(key: String): String {
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
            
            // 화폐 단위 헬퍼 함수
            fun getCurrencySymbol(): String {
                return when (currency) {
                    "USD" -> "$"
                    "JPY" -> "¥"
                    "EUR" -> "€"
                    else -> "원" // KRW 기본값
                }
            }
            
            try {
                // 주문 기본 정보
                val orderNumber = orderData["orderNumber"] as? String ?: getLocalizedText("no_order_number")
                val tableName = orderData["tableName"] as? String ?: getLocalizedText("no_table_info")
                
                // 주문 데이터에서 총 금액 자동 계산
                var calculatedTotalPrice = 0
                val orderVersions = orderData["orderVersion"] as? List<Map<String, Any>> ?: emptyList()
                for (version in orderVersions) {
                    val orderItems = version["orderItems"] as? List<Map<String, Any>> ?: emptyList()
                    for (item in orderItems) {
                        val itemPrice = item["price"] as? Int ?: 0
                        val itemQuantity = item["quantity"] as? Int ?: 0
                        calculatedTotalPrice += (itemPrice * itemQuantity)
                        
                        // 옵션 가격도 추가
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
                
                // 점포용 라벨 섹션 (요청 시에만 표시)
                if (showStoreLabel) {
                    sb.append("점포용라벨, 24\n")
                    sb.append("┌────────────────────┐\n")
                    sb.append("│        ${getLocalizedText("store_label")}        │\n")
                    sb.append("└────────────────────┘\n\n")
                }
                
                // 타이틀 섹션 (커스텀 영수증과 동일한 포맷)
                sb.append("타이틀, 80\n")
                sb.append("$storeName\n\n")
                
                // 매장정보 섹션
                sb.append("${getLocalizedText("store_info")}, 20\n")
                if (storeAddress != null) {
                    sb.append("$storeAddress\n")
                }
                if (phoneNumber != null) {
                    sb.append("${getLocalizedText("phone")}: $phoneNumber\n")
                }
                if (businessNumber != null) {
                    sb.append("${getLocalizedText("business_number")}: $businessNumber\n")
                }
                sb.append("\n")
                
                // 구분선 섹션
                sb.append("구분선, 20\n")
                sb.append("================================\n\n")
                
                // 주문 정보 섹션
                sb.append("${getLocalizedText("order_info")}, 20\n")
                sb.append("${getLocalizedText("order_number")}: $orderNumber\n")
                sb.append("${getLocalizedText("table")}: $tableName\n\n")
                
                // 상품 목록 섹션
                sb.append("${getLocalizedText("menu_list")}, 20\n")
                val orderVersions = orderData["orderVersion"] as? List<Map<String, Any>> ?: emptyList()
                
                for (version in orderVersions) {
                    val orderItems = version["orderItems"] as? List<Map<String, Any>> ?: emptyList()
                    
                    for (item in orderItems) {
                        val menuName = item["menuName"] as? String ?: "상품명 없음"
                        val quantity = item["quantity"] as? Int ?: 0
                        val basePrice = item["price"] as? Int ?: 0
                        
                        // 메뉴 기본 가격 계산
                        val menuTotalPrice = basePrice * quantity
                        
                        // 옵션 가격 계산
                        var optionTotalPrice = 0
                        val options = item["options"] as? List<Map<String, Any>> ?: emptyList()
                        for (option in options) {
                            val selectedItems = option["selectedItems"] as? List<Map<String, Any>> ?: emptyList()
                            for (selectedItem in selectedItems) {
                                val itemPrice = selectedItem["itemPrice"] as? Int ?: 0
                                val itemQuantity = selectedItem["quantity"] as? Int ?: 0
                                optionTotalPrice += (itemPrice * itemQuantity)
                            }
                        }
                        
                        // 최종 가격 = 메뉴가격 x 개수 + 옵션가격 합계
                        val finalPrice = menuTotalPrice + optionTotalPrice
                        sb.append("$menuName x$quantity = ${formatPrice(finalPrice)}${getCurrencySymbol()}\n")
                        
                        // 옵션 상세 표시 (옵션이 있는 경우에만, 가격 없이 옵션명만)
                        if (optionTotalPrice > 0) {
                            for (option in options) {
                                val selectedItems = option["selectedItems"] as? List<Map<String, Any>> ?: emptyList()
                                for (selectedItem in selectedItems) {
                                    val itemName = selectedItem["itemName"] as? String ?: "옵션명 없음"
                                    val itemPrice = selectedItem["itemPrice"] as? Int ?: 0
                                    val itemQuantity = selectedItem["quantity"] as? Int ?: 0
                                    
                                    if (itemPrice > 0) {
                                        if (itemQuantity > 1) {
                                            sb.append("  - $itemName x$itemQuantity\n")
                                        } else {
                                            sb.append("  - $itemName\n")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                
                // 줄바꿈 명령
                sb.append("줄바꿈, 2\n\n")
                
                // 합계 섹션
                sb.append("${getLocalizedText("total")}, 20\n")
                sb.append("${getLocalizedText("total")}: ${formatPrice(calculatedTotalPrice)}${getCurrencySymbol()}\n\n")
                
                // 줄바꿈 명령
                sb.append("줄바꿈, 2\n\n")
                
                // 감사 메시지 섹션
                sb.append("감사메시지, 20\n")
                if (thankYouMessage != null) {
                    sb.append("$thankYouMessage\n\n")
                } else {
                    sb.append("${getLocalizedText("thank_you_default")}\n\n")
                }
                
                // 줄바꿈 명령
                sb.append("줄바꿈, 3\n\n")
                
                // 영수증 자르기 명령
                sb.append("영수증 자르기")
                
            } catch (e: Exception) {
                Log.e(TAG, "주문 영수증 포맷팅 실패", e)
                // 에러 시 기본 영수증 반환 (커스텀 영수증과 동일한 포맷)
                return "타이틀, 80\n$storeName\n\n감사메시지, 20\n감사합니다!\n\n영수증 자르기"
            }
            
            return sb.toString()
        }
        
        /**
         * 전체 주문 데이터를 영수증 포맷으로 변환 (모든 주문 버전 포함)
         * @param orderData 주문 데이터 (모든 버전 포함)
         * @param storeName 매장명
         * @param tableNumber 테이블 번호 (선택사항)
         * @param storeAddress 매장 주소 (선택사항)
         * @param phoneNumber 전화번호 (선택사항)
         * @param businessNumber 사업자등록번호 (선택사항)
         * @param thankYouMessage 감사 메시지 (선택사항)
         */
        fun formatTotalOrderReceipt(
            orderData: Map<String, Any>,
            storeName: String,
            tableNumber: String? = null,
            storeAddress: String? = null,
            phoneNumber: String? = null,
            businessNumber: String? = null,
            thankYouMessage: String? = null,
            language: String = "kor",
            currency: String = "KRW"
        ): String {
            val sb = StringBuilder()
            
            // 다국어 텍스트 헬퍼 함수
            fun getLocalizedText(key: String): String {
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
                        "thank_you_default" -> "감사합니다!\n다음에 또 방문해 주세요."
                        "phone" -> "전화"
                        "business_number" -> "사업자등록번호"
                        "no_order_number" -> "주문번호 없음"
                        "no_table_info" -> "테이블 정보 없음"
                        else -> key
                    }
                }
            }
            
            // 화폐 단위 헬퍼 함수
            fun getCurrencySymbol(): String {
                return when (currency) {
                    "USD" -> "$"
                    "JPY" -> "¥"
                    "EUR" -> "€"
                    else -> "원" // KRW 기본값
                }
            }
            
            try {
                // 주문 기본 정보
                val orderNumber = orderData["orderNumber"] as? String ?: getLocalizedText("no_order_number")
                val tableName = orderData["tableName"] as? String ?: getLocalizedText("no_table_info")
                
                // API 응답에서 제공하는 총 금액 사용
                val grandTotalPrice = orderData["totalPrice"] as? Int ?: 0
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
                
                // 타이틀 섹션 (커스텀 영수증과 동일한 포맷)
                sb.append("타이틀, 80\n")
                sb.append("$storeName\n\n")
                
                // 매장정보 섹션
                sb.append("${getLocalizedText("store_info")}, 20\n")
                if (storeAddress != null) {
                    sb.append("$storeAddress\n")
                }
                if (phoneNumber != null) {
                    sb.append("${getLocalizedText("phone")}: $phoneNumber\n")
                }
                if (businessNumber != null) {
                    sb.append("${getLocalizedText("business_number")}: $businessNumber\n")
                }
                sb.append("\n")
                
                // 구분선 섹션
                sb.append("구분선, 20\n")
                sb.append("================================\n\n")
                
                // 주문 정보 섹션
                sb.append("${getLocalizedText("order_info")}, 20\n")
                sb.append("${getLocalizedText("order_number")}: $orderNumber\n")
                sb.append("${getLocalizedText("table")}: $tableName\n\n")
                
                // 누적 상품 목록 섹션 (모든 버전 합치기)
                sb.append("${getLocalizedText("menu_list")}, 20\n")
                
                // 모든 버전의 상품을 합치기 위한 Map (메뉴명 + 옵션 조합을 기준으로)
                val mergedItems = mutableMapOf<String, MutableMap<String, Any>>()
                
                // 모든 버전의 상품 수집
                for (version in orderVersions) {
                    val orderItems = version["orderItems"] as? List<Map<String, Any>> ?: emptyList()
                    
                    for (item in orderItems) {
                        val menuName = item["menuName"] as? String ?: "상품명 없음"
                        val quantity = item["quantity"] as? Int ?: 0
                        val basePrice = item["price"] as? Int ?: 0
                        
                        // 옵션 정보를 포함한 고유 키 생성
                        // Flutter 모델에서는 menuOptionItems 필드를 사용하고 네이티브에서는 options 필드를 사용함
                        val options = when {
                            item.containsKey("options") -> item["options"] as? List<Map<String, Any>>
                            item.containsKey("menuOptionItems") -> item["menuOptionItems"] as? List<Map<String, Any>>
                            else -> null
                        } ?: emptyList()
                        
                        Log.d(TAG, "옵션 처리: 메뉴=$menuName, 옵션 개수=${options.size}")
                        val optionKey = StringBuilder()
                        var optionTotalPrice = 0
                        
                        for (option in options) {
                            val selectedItems = option["selectedItems"] as? List<Map<String, Any>> ?: emptyList()
                            for (selectedItem in selectedItems) {
                                // Flutter 모델과 네이티브 코드 필드명 차이 처리
                                val optionName = selectedItem["itemName"] as? String 
                                    ?: selectedItem["menuOptionItemDetailName"] as? String 
                                    ?: ""
                                
                                val optionPrice = selectedItem["itemPrice"] as? Int 
                                    ?: selectedItem["menuOptionItemDetailPrice"] as? Int 
                                    ?: 0
                                
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
                        // API에서 제공하는 가격 사용 
                        // 메뉴 아이템에는 totalPrice가 아닌 price 필드가 있으며, 수량을 곱해야 함
                        val price = menuItem["price"] as? Int ?: 0
                        val totalItemPrice = price
                        Log.d(TAG, "[메뉴: $menuName] 가격: $price = $totalItemPrice")
                        
                        // 메뉴 아이템 합치기 (동일한 메뉴 + 옵션 조합인 경우에만)
                        if (mergedItems.containsKey(uniqueKey)) {
                            val existingItem = mergedItems[uniqueKey]!!
                            existingItem["quantity"] = (existingItem["quantity"] as Int) + quantity
                            existingItem["totalPrice"] = (existingItem["totalPrice"] as Int) + totalItemPrice
                        } else {
                            mergedItems[uniqueKey] = mutableMapOf(
                                "menuName" to menuName,
                                "quantity" to quantity,
                                "basePrice" to basePrice,
                                "apiTotalPrice" to apiTotalPrice,
                                "totalPrice" to totalItemPrice,
                                "options" to options
                            )
                        }
                    }
                }
                
                // 합쳐진 상품 출력
                for ((uniqueKey, itemData) in mergedItems) {
                    val menuName = itemData["menuName"] as String
                    val quantity = itemData["quantity"] as Int
                    val totalPrice = itemData["totalPrice"] as Int
                    val apiTotalPrice = itemData["apiTotalPrice"] as? Int
                    val options = itemData["options"] as List<Map<String, Any>>
                    
                    // 응답에서 제공된 totalPrice를 사용하므로 개별 아이템 합산 제거
                    
                    sb.append("$menuName x$quantity = ${formatPrice(totalPrice)}${getCurrencySymbol()}\n")
                    
                    // 옵션 표시 (가격 없이 옵션명만)
                    for (option in options) {
                        val selectedItems = option["selectedItems"] as? List<Map<String, Any>> ?: emptyList()
                        for (selectedItem in selectedItems) {
                            // Flutter 모델과 네이티브 코드 필드명 차이 처리
                            val optionName = selectedItem["itemName"] as? String 
                                ?: selectedItem["menuOptionItemDetailName"] as? String 
                                ?: "옵션명 없음"
                            
                            val optionPrice = selectedItem["itemPrice"] as? Int 
                                ?: selectedItem["menuOptionItemDetailPrice"] as? Int 
                                ?: 0
                            
                            val optionQuantity = selectedItem["quantity"] as? Int 
                                ?: selectedItem["menuOptionItemDetailQuantity"] as? Int 
                                ?: 0
                            
                            Log.d(TAG, "옵션 출력: 메뉴=$menuName, 옵션=$optionName, 가격=$optionPrice, 수량=$optionQuantity")
                            
                            if (optionPrice > 0) {
                                if (optionQuantity > 1) {
                                    sb.append("  - $optionName x$optionQuantity\n")
                                } else {
                                    sb.append("  - $optionName\n")
                                }
                            }
                        }
                    }
                }
                
                Log.d(TAG, "계산된 총 금액: $grandTotalPrice")
                
                // 줄바꿈 명령
                sb.append("줄바꿈, 2\n\n")
                
                // 총 합계 섹션
                sb.append("${getLocalizedText("grand_total")}, 20\n")
                sb.append("${getLocalizedText("grand_total")}: ${formatPrice(grandTotalPrice)}${getCurrencySymbol()}\n\n")
                
                // 줄바꿈 명령
                sb.append("줄바꿈, 2\n\n")
                
                // 감사 메시지 섹션
                sb.append("감사메시지, 20\n")
                if (thankYouMessage != null) {
                    sb.append("$thankYouMessage\n\n")
                } else {
                    sb.append("${getLocalizedText("thank_you_default")}\n\n")
                }
                
                // 줄바꿈 명령
                sb.append("줄바꿈, 3\n\n")
                
                // 영수증 자르기 명령
                sb.append("영수증 자르기")
                
            } catch (e: Exception) {
                Log.e(TAG, "누적 주문 영수증 포맷팅 실패", e)
                // 에러 시 기본 영수증 반환 (커스텀 영수증과 동일한 포맷)
                return "타이틀, 80\n$storeName\n\n감사메시지, 20\n감사합니다!\n\n영수증 자르기"
            }
            
            return sb.toString()
        }
        
        /**
         * 가격 포맷팅 (천단위 콤마)
         */
        private fun formatPrice(price: Int): String {
            return String.format("%,d", price)
        }
        
        // 프린터 초기화
        fun initialize(outputStream: OutputStream) {
            try {
                outputStream.write(HardwarePrinterCommands.POS_Set_PrtInit())
            } catch (e: Exception) {
                Log.e(TAG, "프린터 초기화 오류: ${e.message}")
            }
        }
        
        // 타이틀 출력
        fun printTitle(outputStream: OutputStream) {
            try {
                val image = RenderKoreanTextToImage.createTextImage(
                    DataSampleReceipts.TITLE_TEXT, 
                    24f, 
                    true, 
                    RenderKoreanTextToImage.TextAlign.CENTER
                )
                val bitmap = RenderKoreanTextToImage.convertToBitmap(image)
                outputStream.write(bitmap)
            } catch (e: Exception) {
                Log.e(TAG, "타이틀 출력 오류: ${e.message}")
            }
        }
        
        // 매장정보 출력
        fun printStoreInfo(outputStream: OutputStream) {
            try {
                val image = RenderKoreanTextToImage.createTextImage(
                    DataSampleReceipts.STORE_INFO_TEXT, 
                    16f, 
                    false, 
                    RenderKoreanTextToImage.TextAlign.CENTER
                )
                val bitmap = RenderKoreanTextToImage.convertToBitmap(image)
                outputStream.write(bitmap)
            } catch (e: Exception) {
                Log.e(TAG, "매장정보 출력 오류: ${e.message}")
            }
        }
        
        // 구분선 출력
        fun printSeparator(outputStream: OutputStream) {
            try {
                val image = RenderKoreanTextToImage.createTextImage(
                    DataSampleReceipts.SEPARATOR_TEXT, 
                    14f, 
                    false, 
                    RenderKoreanTextToImage.TextAlign.CENTER
                )
                val bitmap = RenderKoreanTextToImage.convertToBitmap(image)
                outputStream.write(bitmap)
            } catch (e: Exception) {
                Log.e(TAG, "구분선 출력 오류: ${e.message}")
            }
        }
        
        // 상품목록 출력
        fun printItems(outputStream: OutputStream) {
            try {
                val image = RenderKoreanTextToImage.createTextImage(
                    DataSampleReceipts.ITEMS_TEXT, 
                    14f, 
                    false, 
                    RenderKoreanTextToImage.TextAlign.LEFT
                )
                val bitmap = RenderKoreanTextToImage.convertToBitmap(image)
                outputStream.write(bitmap)
            } catch (e: Exception) {
                Log.e(TAG, "상품목록 출력 오류: ${e.message}")
            }
        }
        
        // 합계 출력
        fun printTotal(outputStream: OutputStream) {
            try {
                val image = RenderKoreanTextToImage.createTextImage(
                    DataSampleReceipts.TOTAL_TEXT, 
                    16f, 
                    true, 
                    RenderKoreanTextToImage.TextAlign.RIGHT
                )
                val bitmap = RenderKoreanTextToImage.convertToBitmap(image)
                outputStream.write(bitmap)
            } catch (e: Exception) {
                Log.e(TAG, "합계 출력 오류: ${e.message}")
            }
        }
        
        // 감사메시지 출력
        fun printThankYou(outputStream: OutputStream) {
            try {
                val image = RenderKoreanTextToImage.createTextImage(
                    DataSampleReceipts.THANK_YOU_TEXT, 
                    16f, 
                    false, 
                    RenderKoreanTextToImage.TextAlign.CENTER
                )
                val bitmap = RenderKoreanTextToImage.convertToBitmap(image)
                outputStream.write(bitmap)
            } catch (e: Exception) {
                Log.e(TAG, "감사메시지 출력 오류: ${e.message}")
            }
        }
        
        // 줄바꿈
        fun feedPaper(outputStream: OutputStream, lines: Int = 1) {
            try {
                val feedCommand = HardwarePrinterCommands.POS_Set_PrtAndFeedPaper(lines)
                if (feedCommand != null) {
                    outputStream.write(feedCommand)
                }
            } catch (e: Exception) {
                Log.e(TAG, "줄바꿈 오류: ${e.message}")
            }
        }
        
        // 영수증 자르기
        fun cutPaper(outputStream: OutputStream) {
            try {
                outputStream.write(HardwarePrinterCommands.POS_Set_PrtAndFeedPaper(200))
                outputStream.write(HardwareEscPosConstants.GS_V_n)
                outputStream.flush()
                
            } catch (e: Exception) {
                Log.e(TAG, "영수증 자르기 오류: ${e.message}")
            }
        }
        
        // 기존 함수 유지 (호환성을 위해)
        fun parseAndPrint(outputStream: OutputStream, receiptText: String) {
            try {
                Log.d(TAG, "영수증 파싱 시작: $receiptText")
                Log.d(TAG, "영수증 텍스트 길이: ${receiptText.length}")
                
                // 프린터 초기화
                outputStream.write(HardwarePrinterCommands.POS_Set_PrtInit())
                Log.d(TAG, "프린터 초기화 완료")
                
                val lines = receiptText.split("\n")
                Log.d(TAG, "총 라인 수: ${lines.size}")
                var i = 0
                
                while (i < lines.size) {
                    val line = lines[i].trim()
                    Log.d(TAG, "처리 중인 라인 $i: '$line'")
                    
                    when {
                        line.isEmpty() -> {
                            Log.d(TAG, "빈 라인 건너뛰기")
                            i++
                            continue
                        }
                        
                        line == "영수증 자르기" -> {
                            // 영수증 자르기 명령
                            cutPaper(outputStream)
                            Log.d(TAG, "영수증 자르기 완료")
                        }
                        
                        line.contains(", ") && line.split(", ").size == 2 -> {
                            // 섹션 헤더 (예: "타이틀, 24")
                            val parts = line.split(", ")
                            val sectionName = parts[0]
                            val textSize = parts[1].toFloatOrNull() ?: 16f
                            
                            Log.d(TAG, "섹션 처리 시작: $sectionName, 크기: $textSize")
                            
                            // 다음 줄부터 해당 섹션의 내용 수집
                            i++
                            val contentLines = mutableListOf<String>()
                            
                            while (i < lines.size) {
                                val contentLine = lines[i].trim()
                                if (contentLine.isEmpty() || 
                                    (contentLine.contains(", ") && contentLine.split(", ").size == 2) ||
                                    contentLine == "영수증 자르기") {
                                    break
                                }
                                contentLines.add(contentLine)
                                i++
                            }
                            i-- // 다음 반복에서 올바른 줄을 처리하기 위해
                            
                            if (contentLines.isNotEmpty()) {
                                val content = contentLines.joinToString("\n")
                                Log.d(TAG, "섹션 내용: '$content'")
                                
                                // 섹션별 기본 설정 - 폰트 크기 조정
                                val sectionSettings = mapOf(
                                    "타이틀" to Triple(true, RenderKoreanTextToImage.TextAlign.CENTER, 20f), // 타이틀 폰트 축소 (24f -> 20f)
                                    "매장정보" to Triple(false, RenderKoreanTextToImage.TextAlign.CENTER, 18f), // 폰트 크기 증가 (16f -> 18f)
                                    "구분선" to Triple(false, RenderKoreanTextToImage.TextAlign.CENTER, 16f), // 폰트 크기 증가 (14f -> 16f)
                                    "상품목록" to Triple(false, RenderKoreanTextToImage.TextAlign.LEFT, 16f), // 폰트 크기 증가 (14f -> 16f)
                                    "합계" to Triple(true, RenderKoreanTextToImage.TextAlign.RIGHT, 18f), // 폰트 크기 증가 (16f -> 18f)
                                    "감사메시지" to Triple(false, RenderKoreanTextToImage.TextAlign.CENTER, 18f) // 폰트 크기 증가 (16f -> 18f)
                                )
                                val settings = sectionSettings[sectionName] ?: Triple(false, RenderKoreanTextToImage.TextAlign.LEFT, textSize)
                                val (isBold, align, _) = settings
                                
                                Log.d(TAG, "이미지 생성 시작: 굵기=$isBold, 정렬=$align, 크기=$textSize")
                                val image = RenderKoreanTextToImage.createTextImage(content, textSize, isBold, align)
                                Log.d(TAG, "이미지 생성 완료: ${image.width}x${image.height}")
                                
                                val bitmap = RenderKoreanTextToImage.convertToBitmap(image)
                                Log.d(TAG, "비트맵 변환 완료: ${bitmap.size}바이트")
                                
                                outputStream.write(bitmap)
                                outputStream.flush() // 즉시 전송
                                Log.d(TAG, "섹션 출력 완료: $sectionName")
                            } else {
                                Log.d(TAG, "섹션 내용이 비어있음: $sectionName")
                            }
                        }
                        
                        line.startsWith("줄바꿈, ") -> {
                            // 줄바꿈 명령 (예: "줄바꿈, 3")
                            val feedLines = line.substringAfter("줄바꿈, ").toIntOrNull() ?: 1
                            val feedCommand = HardwarePrinterCommands.POS_Set_PrtAndFeedPaper(feedLines)
                            if (feedCommand != null) {
                                outputStream.write(feedCommand)
                            }
                        }
                        
                        else -> {
                            Log.d(TAG, "알 수 없는 라인 형식: '$line'")
                        }
                    }
                    
                    i++
                }
                
                Log.d(TAG, "영수증 파싱 완료")
                
            } catch (e: Exception) {
                Log.e(TAG, "프린터 출력 오류: ${e.message}", e)
                throw e
            } catch (e: Exception) {
                Log.e(TAG, "텍스트 파싱 오류: ${e.message}", e)
                throw e
            }
        }