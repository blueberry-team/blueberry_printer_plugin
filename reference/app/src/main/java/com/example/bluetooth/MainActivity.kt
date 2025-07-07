package com.example.bluetooth

import android.Manifest
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.enableEdgeToEdge
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.tooling.preview.Preview
import androidx.core.app.ActivityCompat
import com.example.bluetooth.ui.theme.BluetoothTheme
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.io.IOException
import java.io.OutputStream
import java.util.*
import androidx.compose.ui.unit.dp
import android.util.Log
import kotlinx.coroutines.withContext

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            BluetoothTheme {
                BluetoothScreen(this)
            }
        }
    }
}

@Composable
fun BluetoothScreen(activity: Activity) {
    val context = LocalContext.current
    var status by remember { mutableStateOf("상태: 대기 중") }
    var selectedDevice by remember { mutableStateOf<BluetoothDevice?>(null) }
    var deviceList by remember { mutableStateOf<List<BluetoothDevice>>(emptyList()) }
    val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
    var socket: BluetoothSocket? by remember { mutableStateOf(null) }
    var outputStream: OutputStream? by remember { mutableStateOf(null) }
    val coroutineScope = rememberCoroutineScope()

    val permissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestMultiplePermissions()
    ) { result ->
        Log.d("BluetoothScreen", "권한 요청 결과: $result")
    }

    fun startDiscovery() {
        Log.d("BluetoothScreen", "startDiscovery() 진입")
        if (bluetoothAdapter == null) {
            status = "블루투스 미지원 기기"
            Log.d("BluetoothScreen", "블루투스 미지원 기기")
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            ActivityCompat.checkSelfPermission(
                context,
                Manifest.permission.BLUETOOTH_CONNECT
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            status = "BLUETOOTH_CONNECT 권한 필요"
            Log.d("BluetoothScreen", "BLUETOOTH_CONNECT 권한 필요")
            return
        }
        if (!bluetoothAdapter.isEnabled) {
            val enableBtIntent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
            activity.startActivityForResult(enableBtIntent, 1)
            status = "블루투스 활성화 필요"
            Log.d("BluetoothScreen", "블루투스 활성화 필요")
            return
        }
        status = "기기 검색 중..."
        Log.d("BluetoothScreen", "기기 검색 중...")
        val pairedDevices = bluetoothAdapter.bondedDevices
        deviceList = pairedDevices.toList()
        if (deviceList.isEmpty()) {
            status = "페어링된 기기 없음"
            Log.d("BluetoothScreen", "페어링된 기기 없음")
        } else {
            status = "기기 선택 대기 중"
            Log.d("BluetoothScreen", "페어링된 기기: ${deviceList.map { it.name }}")
        }
    }

    fun checkPermissionsAndScan() {
        Log.d("BluetoothScreen", "checkPermissionsAndScan() 진입")
        val permissions = mutableListOf(
            Manifest.permission.BLUETOOTH,
            Manifest.permission.BLUETOOTH_ADMIN,
            Manifest.permission.ACCESS_FINE_LOCATION
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            permissions.add(Manifest.permission.BLUETOOTH_CONNECT)
            permissions.add(Manifest.permission.BLUETOOTH_SCAN)
        }
        val notGranted = permissions.filter {
            ActivityCompat.checkSelfPermission(context, it) != PackageManager.PERMISSION_GRANTED
        }
        Log.d("BluetoothScreen", "필요 권한: $permissions, 미허용: $notGranted")
        if (notGranted.isNotEmpty()) {
            permissionLauncher.launch(notGranted.toTypedArray())
            Log.d("BluetoothScreen", "권한 요청 실행 (permissionLauncher)")
            ActivityCompat.requestPermissions(
                activity,
                notGranted.toTypedArray(),
                100
            )
            Log.d("BluetoothScreen", "권한 요청 실행 (ActivityCompat)")
        } else {
            startDiscovery()
        }
    }

    fun connect(device: BluetoothDevice) {
        Log.d("BluetoothScreen", "connect() 진입: ${device.name}")
        coroutineScope.launch(Dispatchers.IO) {
            try {
                Log.d("BluetoothScreen", "연결 시도 중...")
                withContext(Dispatchers.Main) { status = "연결 시도 중..." }
                val uuid = device.uuids?.firstOrNull()?.uuid
                    ?: UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
                val s = device.createRfcommSocketToServiceRecord(uuid)
                bluetoothAdapter?.cancelDiscovery()
                s.connect()
                socket = s
                outputStream = s.outputStream
                withContext(Dispatchers.Main) {
                    status = "연결 성공"
                    Log.d("BluetoothScreen", "연결 성공")
                }
            } catch (e: IOException) {
                withContext(Dispatchers.Main) {
                    status = "연결 실패: ${e.message}"
                    Log.e("BluetoothScreen", "연결 실패", e)
                }
            }
        }
    }

    fun sendData(data: String) {
        Log.d("BluetoothScreen", "sendData() 진입: $data")
        coroutineScope.launch(Dispatchers.IO) {
            try {
                outputStream?.write(data.toByteArray())
                withContext(Dispatchers.Main) {
                    status = "데이터 전송 완료"
                    Log.d("BluetoothScreen", "데이터 전송 완료")
                }
            } catch (e: IOException) {
                withContext(Dispatchers.Main) {
                    status = "전송 실패: ${e.message}"
                    Log.e("BluetoothScreen", "전송 실패", e)
                }
            }
        }
    }

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        item {
            Button(onClick = {
                Log.d("BluetoothScreen", "기기 검색 버튼 클릭")
                checkPermissionsAndScan()
            }, modifier = Modifier.fillMaxWidth()) {
                Text("기기 검색")
            }
        }

        if (deviceList.isNotEmpty()) {
            item {
                Text("기기 목록:", modifier = Modifier.padding(top = 8.dp))
            }
            items(deviceList) { device ->
                Button(
                    onClick = {
                        selectedDevice = device
                        status = "${device.name} 선택됨"
                        Log.d("BluetoothScreen", "${device.name} 직접 선택됨")
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 2.dp),
                    enabled = true
                ) {
                    Text(
                        text = device.name ?: device.address,
                        modifier = if (selectedDevice == device) Modifier.padding(4.dp) else Modifier
                    )
                }
            }
        }

        item {
            Button(
                onClick = {
                    Log.d("BluetoothScreen", "연결 버튼 클릭: ${selectedDevice?.name}")
                    selectedDevice?.let { connect(it) }
                },
                enabled = selectedDevice != null,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("연결")
            }
        }

        item {
            Button(
                onClick = {
                    Log.d("BluetoothScreen", "데이터 전송 버튼 클릭")
                    sendData("Hello from Android!")
                },
                enabled = socket != null,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("데이터 전송")
            }
        }

        // 구분선
        item {
            Text(
                text = "=== 한국어 영수증 출력 ===",
                modifier = Modifier.padding(vertical = 8.dp)
            )
        }

        // 한국어 영수증 샘플 출력
        item {
            Button(
                onClick = {
                    Log.d("BluetoothScreen", "코틀린 한국어 영수증 출력 시작")
                    coroutineScope.launch(Dispatchers.IO) {
                        try {
                            outputStream?.let { stream ->
                                KoreanImagePrinter.printKoreanReceiptSample(stream)
                                withContext(Dispatchers.Main) {
                                    status = "한국어 영수증 출력 완료"
                                }
                            } ?: run {
                                withContext(Dispatchers.Main) {
                                    status = "출력 스트림이 연결되지 않았습니다"
                                }
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                status = "영수증 출력 실패: ${e.message}"
                                Log.e("BluetoothScreen", "영수증 출력 실패", e)
                            }
                        }
                    }
                },
                enabled = socket?.isConnected == true,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("한국어 영수증 샘플")
            }
        }

        // 개별 섹션 출력 버튼들
        item {
            Text(
                text = "=== 개별 섹션 출력 ===",
                modifier = Modifier.padding(vertical = 8.dp)
            )
        }

        // 프린터 초기화
        item {
            Button(
                onClick = {
                    coroutineScope.launch(Dispatchers.IO) {
                        try {
                            outputStream?.let { stream ->
                                ReceiptTextParser.초기화(stream)
                                withContext(Dispatchers.Main) {
                                    status = "프린터 초기화 완료"
                                }
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                status = "초기화 실패: ${e.message}"
                            }
                        }
                    }
                },
                enabled = socket?.isConnected == true,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("프린터 초기화")
            }
        }

        // 타이틀 출력
        item {
            Button(
                onClick = {
                    coroutineScope.launch(Dispatchers.IO) {
                        try {
                            outputStream?.let { stream ->
                                ReceiptTextParser.타이틀출력(stream)
                                withContext(Dispatchers.Main) {
                                    status = "타이틀 출력 완료"
                                }
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                status = "타이틀 출력 실패: ${e.message}"
                            }
                        }
                    }
                },
                enabled = socket?.isConnected == true,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("타이틀 출력")
            }
        }

        // 매장정보 출력
        item {
            Button(
                onClick = {
                    coroutineScope.launch(Dispatchers.IO) {
                        try {
                            outputStream?.let { stream ->
                                ReceiptTextParser.매장정보출력(stream)
                                withContext(Dispatchers.Main) {
                                    status = "매장정보 출력 완료"
                                }
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                status = "매장정보 출력 실패: ${e.message}"
                            }
                        }
                    }
                },
                enabled = socket?.isConnected == true,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("매장정보 출력")
            }
        }

        // 구분선 출력
        item {
            Button(
                onClick = {
                    coroutineScope.launch(Dispatchers.IO) {
                        try {
                            outputStream?.let { stream ->
                                ReceiptTextParser.구분선출력(stream)
                                withContext(Dispatchers.Main) {
                                    status = "구분선 출력 완료"
                                }
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                status = "구분선 출력 실패: ${e.message}"
                            }
                        }
                    }
                },
                enabled = socket?.isConnected == true,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("구분선 출력")
            }
        }

        // 상품목록 출력
        item {
            Button(
                onClick = {
                    coroutineScope.launch(Dispatchers.IO) {
                        try {
                            outputStream?.let { stream ->
                                ReceiptTextParser.상품목록출력(stream)
                                withContext(Dispatchers.Main) {
                                    status = "상품목록 출력 완료"
                                }
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                status = "상품목록 출력 실패: ${e.message}"
                            }
                        }
                    }
                },
                enabled = socket?.isConnected == true,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("상품목록 출력")
            }
        }

        // 합계 출력
        item {
            Button(
                onClick = {
                    coroutineScope.launch(Dispatchers.IO) {
                        try {
                            outputStream?.let { stream ->
                                ReceiptTextParser.합계출력(stream)
                                withContext(Dispatchers.Main) {
                                    status = "합계 출력 완료"
                                }
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                status = "합계 출력 실패: ${e.message}"
                            }
                        }
                    }
                },
                enabled = socket?.isConnected == true,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("합계 출력")
            }
        }

        // 감사메시지 출력
        item {
            Button(
                onClick = {
                    coroutineScope.launch(Dispatchers.IO) {
                        try {
                            outputStream?.let { stream ->
                                ReceiptTextParser.감사메시지출력(stream)
                                withContext(Dispatchers.Main) {
                                    status = "감사메시지 출력 완료"
                                }
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                status = "감사메시지 출력 실패: ${e.message}"
                            }
                        }
                    }
                },
                enabled = socket?.isConnected == true,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("감사메시지 출력")
            }
        }

        // 줄바꿈
        item {
            Button(
                onClick = {
                    coroutineScope.launch(Dispatchers.IO) {
                        try {
                            outputStream?.let { stream ->
                                ReceiptTextParser.줄바꿈(stream, 3)
                                withContext(Dispatchers.Main) {
                                    status = "줄바꿈 완료"
                                }
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                status = "줄바꿈 실패: ${e.message}"
                            }
                        }
                    }
                },
                enabled = socket?.isConnected == true,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("줄바꿈 (3줄)")
            }
        }

        // 영수증 자르기
        item {
            Button(
                onClick = {
                    coroutineScope.launch(Dispatchers.IO) {
                        try {
                            outputStream?.let { stream ->
                                ReceiptTextParser.영수증자르기(stream)
                                withContext(Dispatchers.Main) {
                                    status = "영수증 자르기 완료"
                                }
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                status = "영수증 자르기 실패: ${e.message}"
                            }
                        }
                    }
                },
                enabled = socket?.isConnected == true,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("영수증 자르기")
            }
        }

        item {
            Text(status, modifier = Modifier.padding(top = 16.dp))
        }
    }
}

@Composable
fun Greeting(name: String) {
    Text(text = "Hello $name!")
}