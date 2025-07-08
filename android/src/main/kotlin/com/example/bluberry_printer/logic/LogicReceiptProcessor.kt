package com.example.bluberry_printer.logic

import java.io.OutputStream
import android.util.Log
import kotlin.text.Charsets
import com.example.bluberry_printer.hardware.HardwareEscPosConstants
import com.example.bluberry_printer.hardware.HardwareUtilities
import com.example.bluberry_printer.logic.RenderKoreanTextToImage
import com.example.bluberry_printer.data.DataSampleReceipts
import com.example.bluberry_printer.hardware.HardwarePrinterCommands

class LogicReceiptProcessor {
    
    companion object {
        private const val TAG = "LogicReceiptProcessor"
        
        // 프린터 초기화
        fun 초기화(outputStream: OutputStream) {
            try {
                outputStream.write(HardwarePrinterCommands.POS_Set_PrtInit())
            } catch (e: Exception) {
                Log.e(TAG, "프린터 초기화 오류: ${e.message}")
            }
        }
        
        // 타이틀 출력
        fun 타이틀출력(outputStream: OutputStream) {
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
        fun 매장정보출력(outputStream: OutputStream) {
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
        fun 구분선출력(outputStream: OutputStream) {
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
        fun 상품목록출력(outputStream: OutputStream) {
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
        fun 합계출력(outputStream: OutputStream) {
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
        fun 감사메시지출력(outputStream: OutputStream) {
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
        fun 줄바꿈(outputStream: OutputStream, 줄수: Int = 1) {
            try {
                val feedCommand = HardwarePrinterCommands.POS_Set_PrtAndFeedPaper(줄수)
                if (feedCommand != null) {
                    outputStream.write(feedCommand)
                }
            } catch (e: Exception) {
                Log.e(TAG, "줄바꿈 오류: ${e.message}")
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
                                    (contentLine.contains(", ") && contentLine.split(", ").size == 2)) {
                                    break
                                }
                                contentLines.add(contentLine)
                                i++
                            }
                            i-- // 다음 반복에서 올바른 줄을 처리하기 위해
                            
                            if (contentLines.isNotEmpty()) {
                                val content = contentLines.joinToString("\n")
                                Log.d(TAG, "섹션 내용: '$content'")
                                
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
    }
} 