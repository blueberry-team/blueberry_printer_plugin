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
         * 주문 데이터를 영수증 포맷으로 변환
         * @param orderData 주문 데이터
         * @param storeName 매장명
         * @param storeAddress 매장 주소 (선택사항)
         * @param phoneNumber 전화번호 (선택사항)
         * @param businessNumber 사업자등록번호 (선택사항)
         * @param thankYouMessage 감사 메시지 (선택사항)
         */
        fun formatOrderReceipt(
            orderData: Map<String, Any>,
            storeName: String,
            storeAddress: String? = null,
            phoneNumber: String? = null,
            businessNumber: String? = null,
            thankYouMessage: String? = null
        ): String {
            val sb = StringBuilder()
            
            try {
                // 주문 기본 정보
                val orderNumber = orderData["orderNumber"] as? String ?: "주문번호 없음"
                val tableName = orderData["tableName"] as? String ?: "테이블 정보 없음"
                
                // 주문 데이터에서 총 금액 자동 계산
                var calculatedTotalPrice = 0
                val orderVersions = orderData["orderVersion"] as? List<Map<String, Any>> ?: emptyList()
                for (version in orderVersions) {
                    val orderItems = version["orderItems"] as? List<Map<String, Any>> ?: emptyList()
                    for (item in orderItems) {
                        val itemPrice = item["price"] as? Int ?: 0
                        calculatedTotalPrice += itemPrice
                        
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
                
                // 타이틀 섹션 (커스텀 영수증과 동일한 포맷)
                sb.append("타이틀, 80\n")
                sb.append("$storeName\n\n")
                
                // 매장정보 섹션
                sb.append("매장정보, 20\n")
                if (storeAddress != null) {
                    sb.append("$storeAddress\n")
                }
                if (phoneNumber != null) {
                    sb.append("전화: $phoneNumber\n")
                }
                if (businessNumber != null) {
                    sb.append("사업자등록번호: $businessNumber\n")
                }
                sb.append("\n")
                
                // 구분선 섹션
                sb.append("구분선, 20\n")
                sb.append("================================\n\n")
                
                // 주문 정보 섹션
                sb.append("주문정보, 20\n")
                sb.append("주문번호: $orderNumber\n")
                sb.append("테이블: $tableName\n\n")
                
                // 상품 목록 섹션
                sb.append("상품목록, 20\n")
                val orderVersions = orderData["orderVersion"] as? List<Map<String, Any>> ?: emptyList()
                
                for (version in orderVersions) {
                    val orderItems = version["orderItems"] as? List<Map<String, Any>> ?: emptyList()
                    
                    for (item in orderItems) {
                        val menuName = item["menuName"] as? String ?: "상품명 없음"
                        val quantity = item["quantity"] as? Int ?: 0
                        val price = item["price"] as? Int ?: 0
                        
                        sb.append("$menuName x$quantity = ${formatPrice(price)}원\n")
                        
                        // 옵션 처리
                        val options = item["options"] as? List<Map<String, Any>> ?: emptyList()
                        for (option in options) {
                            val selectedItems = option["selectedItems"] as? List<Map<String, Any>> ?: emptyList()
                            for (selectedItem in selectedItems) {
                                val itemName = selectedItem["itemName"] as? String ?: "옵션명 없음"
                                val itemPrice = selectedItem["itemPrice"] as? Int ?: 0
                                val itemQuantity = selectedItem["quantity"] as? Int ?: 0
                                
                                if (itemPrice > 0) {
                                    sb.append("  + $itemName x$itemQuantity = ${formatPrice(itemPrice)}원\n")
                                }
                            }
                        }
                    }
                }
                
                
                // 줄바꿈 명령
                sb.append("줄바꿈, 2\n\n")
                
                // 합계 섹션
                sb.append("합계, 20\n")
                sb.append("소계: ${formatPrice(calculatedTotalPrice)}원\n")
                val tax = (calculatedTotalPrice * 0.1).toInt()
                val totalWithTax = calculatedTotalPrice + tax
                sb.append("부가세: ${formatPrice(tax)}원\n")
                sb.append("합계: ${formatPrice(totalWithTax)}원\n\n")
                
                // 줄바꿈 명령
                sb.append("줄바꿈, 2\n\n")
                
                // 감사 메시지 섹션
                sb.append("감사메시지, 20\n")
                if (thankYouMessage != null) {
                    sb.append("$thankYouMessage\n\n")
                } else {
                    sb.append("감사합니다!\n")
                    sb.append("다음에 또 방문해 주세요.\n\n")
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
                                
                                // 섹션별 기본 설정
                                val sectionSettings = mapOf(
                                    "타이틀" to Triple(true, RenderKoreanTextToImage.TextAlign.CENTER, 24f),
                                    "매장정보" to Triple(false, RenderKoreanTextToImage.TextAlign.CENTER, 16f),
                                    "구분선" to Triple(false, RenderKoreanTextToImage.TextAlign.CENTER, 14f),
                                    "상품목록" to Triple(false, RenderKoreanTextToImage.TextAlign.LEFT, 14f),
                                    "합계" to Triple(true, RenderKoreanTextToImage.TextAlign.RIGHT, 16f),
                                    "감사메시지" to Triple(false, RenderKoreanTextToImage.TextAlign.CENTER, 16f)
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