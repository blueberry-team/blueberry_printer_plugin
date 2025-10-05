package com.example.blueberry_printer.bluetooth_search

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.util.Log

/**
 * 블루투스 기기 검색을 담당하는 클래스
 */
object BluetoothDeviceSearcher {
    private const val TAG = "BluetoothDeviceSearcher"

    /**
     * 페어링된 블루투스 기기 목록 검색
     * @return 기기 정보 리스트 (name, address)
     * @throws BluetoothNotSupportedException 블루투스 미지원 기기
     * @throws BluetoothNotEnabledException 블루투스 비활성화 상태
     * @throws BluetoothSearchException 검색 실패
     */
    fun searchPairedDevices(): List<Map<String, String>> {
        val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
            ?: throw BluetoothNotSupportedException("블루투스 미지원 기기")

        if (!bluetoothAdapter.isEnabled) {
            throw BluetoothNotEnabledException("블루투스가 비활성화되어 있습니다")
        }

        return try {
            val pairedDevices: Set<BluetoothDevice> = bluetoothAdapter.bondedDevices ?: emptySet()
            Log.d(TAG, "페어링된 기기 수: ${pairedDevices.size}")

            pairedDevices.map { device ->
                mapOf(
                    "name" to (device.name ?: "알 수 없는 기기"),
                    "address" to device.address
                )
            }.also {
                Log.d(TAG, "검색 완료: ${it.size}개 기기")
            }
        } catch (e: Exception) {
            Log.e(TAG, "블루투스 기기 검색 실패", e)
            throw BluetoothSearchException("검색 실패: ${e.message}", e)
        }
    }

    /**
     * 특정 주소의 블루투스 기기 찾기
     * @param address 블루투스 기기 주소
     * @return 찾은 BluetoothDevice
     * @throws BluetoothNotSupportedException 블루투스 미지원 기기
     * @throws BluetoothNotEnabledException 블루투스 비활성화 상태
     * @throws DeviceNotFoundException 기기를 찾을 수 없음
     */
    fun findDeviceByAddress(address: String): BluetoothDevice {
        val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
            ?: throw BluetoothNotSupportedException("블루투스 미지원 기기")

        if (!bluetoothAdapter.isEnabled) {
            throw BluetoothNotEnabledException("블루투스가 비활성화되어 있습니다")
        }

        val device = bluetoothAdapter.bondedDevices?.firstOrNull { it.address == address }
            ?: throw DeviceNotFoundException("주소 '$address'에 해당하는 기기를 찾을 수 없습니다")

        Log.d(TAG, "기기 찾기 성공: ${device.name} (${device.address})")
        return device
    }

    /**
     * 블루투스 어댑터 가져오기
     * @return BluetoothAdapter
     * @throws BluetoothNotSupportedException 블루투스 미지원 기기
     */
    fun getBluetoothAdapter(): BluetoothAdapter {
        return BluetoothAdapter.getDefaultAdapter()
            ?: throw BluetoothNotSupportedException("블루투스 미지원 기기")
    }

    /**
     * 블루투스 활성화 상태 확인
     * @return 활성화 여부
     */
    fun isBluetoothEnabled(): Boolean {
        return try {
            val adapter = BluetoothAdapter.getDefaultAdapter()
            adapter?.isEnabled ?: false
        } catch (e: Exception) {
            Log.e(TAG, "블루투스 상태 확인 실패", e)
            false
        }
    }

    // Custom Exceptions
    class BluetoothNotSupportedException(message: String) : Exception(message)
    class BluetoothNotEnabledException(message: String) : Exception(message)
    class BluetoothSearchException(message: String, cause: Throwable? = null) : Exception(message, cause)
    class DeviceNotFoundException(message: String) : Exception(message)
}
