package com.example.bluberry_printer

class Other {
    companion object {
        // 여러 byte[]를 하나로 합침
        fun byteArraysToBytes(data: Array<ByteArray?>): ByteArray {
            var length = 0
            for (arr in data) {
                if (arr != null) length += arr.size
            }
            val result = ByteArray(length)
            var pos = 0
            for (arr in data) {
                if (arr != null) {
                    System.arraycopy(arr, 0, result, pos, arr.size)
                    pos += arr.size
                }
            }
            return result
        }

        // 문자열에서 특정 문자 모두 제거
        fun RemoveChar(str: String?, c: Char): String? {
            return str?.replace(c.toString(), "")
        }

        // 16진수 문자열을 byte[]로 변환
        fun HexStringToBytes(hex: String?): ByteArray {
            if (hex == null || hex.isEmpty()) return ByteArray(0)
            val len = hex.length / 2
            val result = ByteArray(len)
            for (i in 0 until len) {
                val index = i * 2
                val v = hex.substring(index, index + 2).toInt(16)
                result[i] = v.toByte()
            }
            return result
        }
    }
} 