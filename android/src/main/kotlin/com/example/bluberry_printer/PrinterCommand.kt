package com.example.bluberry_printer

import java.io.UnsupportedEncodingException

class PrinterCommand {

    companion object {
        const val KOREAN = "EUC-KR"

        /**
         * 프린터 초기화
         *
         * @return
         */
        fun POS_Set_PrtInit(): ByteArray {
            return Other.byteArraysToBytes(arrayOf(Command.ESC_Init))
        }

        /**
         * 출력 후 이동 (0~255)
         *
         * @param feed
         * @return
         */
        fun POS_Set_PrtAndFeedPaper(feed: Int): ByteArray? {
            if (feed > 255 || feed < 0) return null

            Command.ESC_J[2] = feed.toByte()

            return Other.byteArraysToBytes(arrayOf(Command.ESC_J))
        }

        /**
         * 비트맵 이미지 출력 (GS v 0 방식)
         * @param bitmapData 비트맵 데이터
         * @param width 이미지 폭
         * @param height 이미지 높이
         * @return ESC/POS 명령 바이트 배열
         */
        fun POS_Print_Bitmap(bitmapData: ByteArray, width: Int, height: Int): ByteArray {
            val widthBytes = (width + 7) / 8 // 8픽셀당 1바이트
            val command = ByteArray(8 + bitmapData.size)
            
            // GS v 0 명령 구성
            command[0] = 29 // GS
            command[1] = 118 // v
            command[2] = 48 // 0
            command[3] = 0 // m (normal mode)
            command[4] = (widthBytes and 0xFF).toByte() // xL
            command[5] = ((widthBytes shr 8) and 0xFF).toByte() // xH
            command[6] = (height and 0xFF).toByte() // yL
            command[7] = ((height shr 8) and 0xFF).toByte() // yH
            
            // 비트맵 데이터 복사
            System.arraycopy(bitmapData, 0, command, 8, bitmapData.size)
            
            return command
        }
    }
} 