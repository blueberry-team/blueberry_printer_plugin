package com.example.blueberry_printer.sample_receipt

import java.io.OutputStream
import android.util.Log
import com.example.blueberry_printer.common.EscPosConstants
import com.example.blueberry_printer.common.PrinterCommands
import com.example.blueberry_printer.common.KoreanTextRenderer

/**
 * 간단한 텍스트 출력 프린터
 * 받은 문자열을 그대로 프린터로 출력
 */
object SimpleTextPrinter {
    private const val TAG = "SimpleTextPrinter"

    /**
     * 텍스트를 프린터로 출력
     * @param outputStream 프린터 출력 스트림
     * @param text 출력할 텍스트
     * @param fontSize 폰트 크기 (기본값: 20f)
     * @param isBold 굵게 표시 여부 (기본값: false)
     * @param align 텍스트 정렬 (기본값: LEFT)
     */
    fun print(
        outputStream: OutputStream,
        text: String,
        fontSize: Float = 20f,
        isBold: Boolean = false,
        align: KoreanTextRenderer.TextAlign = KoreanTextRenderer.TextAlign.LEFT
    ) {
        try {
            // 프린터 초기화
            outputStream.write(PrinterCommands.POS_Set_PrtInit())
            Log.d(TAG, "프린터 초기화 완료")

            // 텍스트를 이미지로 변환하여 출력
            val image = KoreanTextRenderer.createTextImage(
                text,
                fontSize,
                isBold,
                align
            )
            val bitmap = KoreanTextRenderer.convertToBitmap(image)
            outputStream.write(bitmap)
            outputStream.flush()

            // 줄바꿈
            feedPaper(outputStream, 3)

            // 영수증 자르기
            cutPaper(outputStream)

            Log.d(TAG, "텍스트 출력 완료")

        } catch (e: Exception) {
            Log.e(TAG, "텍스트 출력 실패", e)
            throw e
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
        outputStream.write(PrinterCommands.POS_Set_PrtAndFeedPaper(200))
        outputStream.write(EscPosConstants.GS_V_n)
        outputStream.flush()
    }
}
