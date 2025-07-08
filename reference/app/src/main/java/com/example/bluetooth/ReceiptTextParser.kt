package com.example.bluetooth

import android.util.Log
import java.io.IOException
import java.io.OutputStream

class ReceiptTextParser {
    
    companion object {
        private const val TAG = "ReceiptTextParser"
        
        // 프린터 초기화
        fun 초기화(outputStream: OutputStream) {
            try {
                outputStream.write(PrinterCommand.POS_Set_PrtInit())
            } catch (e: IOException) {
                Log.e(TAG, "프린터 초기화 오류: ${e.message}")
            }
        }
        
        // 타이틀 출력
        fun 타이틀출력(outputStream: OutputStream) {
            try {
                val image = KoreanImagePrinter.createTextImage(
                    SampleMockData.TITLE_TEXT, 
                    24f, 
                    true, 
                    KoreanImagePrinter.TextAlign.CENTER
                )
                val bitmap = KoreanImagePrinter.convertToBitmap(image)
                outputStream.write(bitmap)
            } catch (e: Exception) {
                Log.e(TAG, "타이틀 출력 오류: ${e.message}")
            }
        }
        
        // 매장정보 출력
        fun 매장정보출력(outputStream: OutputStream) {
            try {
                val image = KoreanImagePrinter.createTextImage(
                    SampleMockData.STORE_INFO_TEXT, 
                    16f, 
                    false, 
                    KoreanImagePrinter.TextAlign.CENTER
                )
                val bitmap = KoreanImagePrinter.convertToBitmap(image)
                outputStream.write(bitmap)
            } catch (e: Exception) {
                Log.e(TAG, "매장정보 출력 오류: ${e.message}")
            }
        }
        
        // 구분선 출력
        fun 구분선출력(outputStream: OutputStream) {
            try {
                val image = KoreanImagePrinter.createTextImage(
                    SampleMockData.SEPARATOR_TEXT, 
                    14f, 
                    false, 
                    KoreanImagePrinter.TextAlign.CENTER
                )
                val bitmap = KoreanImagePrinter.convertToBitmap(image)
                outputStream.write(bitmap)
            } catch (e: Exception) {
                Log.e(TAG, "구분선 출력 오류: ${e.message}")
            }
        }
        
        // 상품목록 출력
        fun 상품목록출력(outputStream: OutputStream) {
            try {
                val image = KoreanImagePrinter.createTextImage(
                    SampleMockData.ITEMS_TEXT, 
                    14f, 
                    false, 
                    KoreanImagePrinter.TextAlign.LEFT
                )
                val bitmap = KoreanImagePrinter.convertToBitmap(image)
                outputStream.write(bitmap)
            } catch (e: Exception) {
                Log.e(TAG, "상품목록 출력 오류: ${e.message}")
            }
        }
        
        // 합계 출력
        fun 합계출력(outputStream: OutputStream) {
            try {
                val image = KoreanImagePrinter.createTextImage(
                    SampleMockData.TOTAL_TEXT, 
                    16f, 
                    true, 
                    KoreanImagePrinter.TextAlign.RIGHT
                )
                val bitmap = KoreanImagePrinter.convertToBitmap(image)
                outputStream.write(bitmap)
            } catch (e: Exception) {
                Log.e(TAG, "합계 출력 오류: ${e.message}")
            }
        }
        
        // 감사메시지 출력
        fun 감사메시지출력(outputStream: OutputStream) {
            try {
                val image = KoreanImagePrinter.createTextImage(
                    SampleMockData.THANK_YOU_TEXT, 
                    16f, 
                    false, 
                    KoreanImagePrinter.TextAlign.CENTER
                )
                val bitmap = KoreanImagePrinter.convertToBitmap(image)
                outputStream.write(bitmap)
            } catch (e: Exception) {
                Log.e(TAG, "감사메시지 출력 오류: ${e.message}")
            }
        }
        
        // 줄바꿈
        fun 줄바꿈(outputStream: OutputStream, 줄수: Int = 1) {
            try {
                outputStream.write(PrinterCommand.POS_Set_PrtAndFeedPaper(줄수))
            } catch (e: IOException) {
                Log.e(TAG, "줄바꿈 오류: ${e.message}")
            }
        }
        
        // 영수증 자르기
        fun 영수증자르기(outputStream: OutputStream) {
            try {
                outputStream.write(PrinterCommand.POS_Cut_Paper_Multiple_Try())
            } catch (e: IOException) {
                Log.e(TAG, "영수증 자르기 오류: ${e.message}")
            }
        }
        
        // 기존 함수 유지 (호환성을 위해)
        fun parseAndPrint(outputStream: OutputStream, receiptText: String) {
            try {
                // 프린터 초기화
                outputStream.write(PrinterCommand.POS_Set_PrtInit())
                
                val lines = receiptText.split("\n")
                var i = 0
                
                while (i < lines.size) {
                    val line = lines[i].trim()
                    
                    when {
                        line.isEmpty() -> {
                            i++
                            continue
                        }
                        
                        line == "영수증 자르기" -> {
                            // 용지 자르기 명령
                            outputStream.write(PrinterCommand.POS_Cut_Paper_Multiple_Try())
                            break
                        }
                        
                        line.contains(", ") && line.split(", ").size == 2 -> {
                            // 섹션 헤더 (예: "타이틀, 24")
                            val parts = line.split(", ")
                            val sectionName = parts[0]
                            val textSize = parts[1].toFloatOrNull() ?: 16f
                            
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
                                val sectionSettings = mapOf(
                                    "타이틀" to Triple(true, KoreanImagePrinter.TextAlign.CENTER, 24f),
                                    "매장정보" to Triple(false, KoreanImagePrinter.TextAlign.CENTER, 16f),
                                    "구분선" to Triple(false, KoreanImagePrinter.TextAlign.CENTER, 14f),
                                    "상품목록" to Triple(false, KoreanImagePrinter.TextAlign.LEFT, 14f),
                                    "합계" to Triple(true, KoreanImagePrinter.TextAlign.RIGHT, 16f),
                                    "감사메시지" to Triple(false, KoreanImagePrinter.TextAlign.CENTER, 16f)
                                )
                                val settings = sectionSettings[sectionName] ?: Triple(false, KoreanImagePrinter.TextAlign.LEFT, textSize)
                                val (isBold, align, _) = settings
                                
                                val image = KoreanImagePrinter.createTextImage(content, textSize, isBold, align)
                                val bitmap = KoreanImagePrinter.convertToBitmap(image)
                                outputStream.write(bitmap)
                            }
                        }
                        
                        line.startsWith("줄바꿈, ") -> {
                            // 줄바꿈 명령 (예: "줄바꿈, 3")
                            val feedLines = line.substringAfter("줄바꿈, ").toIntOrNull() ?: 1
                            outputStream.write(PrinterCommand.POS_Set_PrtAndFeedPaper(feedLines))
                        }
                    }
                    
                    i++
                }
                
            } catch (e: IOException) {
                Log.e(TAG, "프린터 출력 오류: ${e.message}")
            } catch (e: Exception) {
                Log.e(TAG, "텍스트 파싱 오류: ${e.message}")
            }
        }
    }
} 