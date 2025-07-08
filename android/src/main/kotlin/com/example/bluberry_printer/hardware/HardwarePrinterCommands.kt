package com.example.bluberry_printer.hardware

import java.io.UnsupportedEncodingException

class HardwarePrinterCommands {

    companion object {
        const val KOREAN = "EUC-KR"

        /**
         * 프린터 초기화
         *
         * @return
         */
        fun POS_Set_PrtInit(): ByteArray {
            return HardwareUtilities.byteArraysToBytes(arrayOf(HardwareEscPosConstants.ESC_Init))
        }

        /**
         * 출력 후 이동 (0~255)
         *
         * @param feed
         * @return
         */
        fun POS_Set_PrtAndFeedPaper(feed: Int): ByteArray? {
            if (feed > 255 || feed < 0) return null

            HardwareEscPosConstants.ESC_J[2] = feed.toByte()

            return HardwareUtilities.byteArraysToBytes(arrayOf(HardwareEscPosConstants.ESC_J))
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

        /**
         * 영수증 자르기 (용지 이동 후 자르기)
         * @param feedLines 자르기 전 용지 이동 줄 수
         * @return 자르기 명령 바이트 배열
         */
        fun POS_Cut_Paper_With_Feed(feedLines: Int = 3): ByteArray {
            val commands = mutableListOf<Byte>()
            
            // 1. 용지 이동
            val feedCommand = POS_Set_PrtAndFeedPaper(feedLines)
            if (feedCommand != null) {
                commands.addAll(feedCommand.toList())
            }
            
            // 2. 자르기 명령 (GS V 0 - 전체 자르기)
            commands.addAll(HardwareEscPosConstants.GS_V_n.toList())
            
            return commands.toByteArray()
        }

        /**
         * 영수증 자르기 (다양한 방법 시도)
         * @param feedLines 자르기 전 용지 이동 줄 수
         * @return 자르기 명령 바이트 배열
         */
        fun POS_Cut_Paper_Multiple_Try(feedLines: Int = 3): ByteArray {
            val commands = mutableListOf<Byte>()
            
            // 1. 용지 이동
            val feedCommand = POS_Set_PrtAndFeedPaper(feedLines)
            if (feedCommand != null) {
                commands.addAll(feedCommand.toList())
            }
            
            // 2. 여러 자르기 명령 시도
            // 방법 1: GS V 0 (전체 자르기)
            commands.addAll(HardwareEscPosConstants.GS_V_n.toList())
            
            // 방법 2: GS V B 0 (부분 자르기)
            commands.addAll(HardwareEscPosConstants.GS_V_m_n.toList())
            
            // 방법 3: ESC i
            commands.addAll(HardwareEscPosConstants.GS_i.toList())
            
            // 방법 4: ESC m
            commands.addAll(HardwareEscPosConstants.GS_m.toList())
            
            return commands.toByteArray()
        }
    }
} 