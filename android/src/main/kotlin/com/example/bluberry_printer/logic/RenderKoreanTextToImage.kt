package com.example.bluberry_printer.logic

import android.graphics.*
import android.util.Log
import java.io.IOException
import java.io.OutputStream
import com.example.bluberry_printer.data.DataSampleReceipts
import com.example.bluberry_printer.hardware.HardwarePrinterCommands

object RenderKoreanTextToImage {
    private const val TAG = "RenderKoreanTextToImage"

    // 텍스트 정렬 enum
    enum class TextAlign {
        LEFT, CENTER, RIGHT
    }

    // 종이(프린터) 설정
    private const val PAPER_WIDTH_PX = 576 // 일반적인 58mm 프린터 기준 (약 576픽셀)
    private const val MARGIN_PX = 20

    // 텍스트를 이미지로 변환하는 함수 (종이 크기 기준 정렬)
    fun createTextImage(text: String, textSize: Float, isBold: Boolean, align: TextAlign = TextAlign.LEFT): Bitmap {
        val paint = Paint().apply {
            this.textSize = textSize
            color = Color.BLACK
            isAntiAlias = true
            if (isBold) {
                typeface = Typeface.DEFAULT_BOLD
            }
        }

        val lines = text.split("\n")
        val lineHeight = paint.fontMetrics.let { it.bottom - it.top + it.leading }

        // 종이 너비를 고정으로 사용
        val width = PAPER_WIDTH_PX
        val height = (lineHeight * lines.size + MARGIN_PX * 2).toInt()

        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        canvas.drawColor(Color.WHITE)

        var y = MARGIN_PX.toFloat() - paint.fontMetrics.top
        for (line in lines) {
            val lineWidth = paint.measureText(line)
            val x = when (align) {
                TextAlign.LEFT -> MARGIN_PX.toFloat()
                TextAlign.CENTER -> (width - lineWidth) / 2f
                TextAlign.RIGHT -> width - lineWidth - MARGIN_PX.toFloat()
            }
            canvas.drawText(line, x, y, paint)
            y += lineHeight
        }

        return bitmap
    }

    // 비트맵을 프린터용 바이트 배열로 변환
    fun convertToBitmap(bitmap: Bitmap): ByteArray {
        val width = bitmap.width
        val height = bitmap.height

        // 8픽셀당 1바이트로 변환 (흑백)
        val widthBytes = (width + 7) / 8
        val imageData = ByteArray(widthBytes * height)

        for (y in 0 until height) {
            for (x in 0 until width) {
                val pixel = bitmap.getPixel(x, y)
                val gray = (Color.red(pixel) + Color.green(pixel) + Color.blue(pixel)) / 3

                if (gray < 128) { // 어두운 픽셀을 1로 설정
                    val byteIndex = y * widthBytes + x / 8
                    val bitIndex = 7 - (x % 8)
                    imageData[byteIndex] =
                        (imageData[byteIndex].toInt() or (1 shl bitIndex)).toByte()
                }
            }
        }

        return HardwarePrinterCommands.POS_Print_Bitmap(imageData, width, height)
    }
} 