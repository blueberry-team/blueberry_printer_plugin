import 'package:flutter/material.dart';
import 'dart:async';

import 'package:bluberry_printer/bluberry_printer.dart';
import 'sample_receipts.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '블루베리 프린터',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _bluberryPrinterPlugin = BluberryPrinter();
  String _platformVersion = 'Unknown';
  List<Map<String, String>> _devices = [];
  bool _isScanning = false;
  bool _isConnected = false;
  String _connectedDeviceName = '';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    String platformVersion;
    try {
      platformVersion = await _bluberryPrinterPlugin.getPlatformVersion() ?? 'Unknown platform version';
    } catch (e) {
      platformVersion = 'Failed to get platform version: $e';
    }

    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Future<bool> _requestBluetoothPermissions() async {
    print("🔍 [DEBUG] _requestBluetoothPermissions() 시작");
    
    // 현재 권한 상태 먼저 확인
    print("🔍 [DEBUG] 현재 권한 상태 확인:");
    Map<Permission, PermissionStatus> currentStatus = {
      Permission.bluetooth: await Permission.bluetooth.status,
      Permission.bluetoothScan: await Permission.bluetoothScan.status,
      Permission.bluetoothConnect: await Permission.bluetoothConnect.status,
      Permission.bluetoothAdvertise: await Permission.bluetoothAdvertise.status,
      Permission.location: await Permission.location.status,
      Permission.locationWhenInUse: await Permission.locationWhenInUse.status,
    };
    
    currentStatus.forEach((permission, status) {
      print("🔍 [DEBUG] 현재 $permission: $status");
    });
    
    // 1단계: 블루투스 권한만 먼저 요청
    print("🔍 [DEBUG] 1단계: 블루투스 권한 요청");
    Map<Permission, PermissionStatus> bluetoothPermissions = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
    ].request();

    print("🔍 [DEBUG] 블루투스 권한 요청 결과:");
    bluetoothPermissions.forEach((permission, status) {
      print("🔍 [DEBUG] $permission: $status");
    });

    // 2단계: 위치 권한 요청 (블루투스 스캔에 필요)
    print("🔍 [DEBUG] 2단계: 위치 권한 요청");
    Map<Permission, PermissionStatus> locationPermissions = await [
      Permission.location,
      Permission.locationWhenInUse,
    ].request();

    print("🔍 [DEBUG] 위치 권한 요청 결과:");
    locationPermissions.forEach((permission, status) {
      print("🔍 [DEBUG] $permission: $status");
    });

    // 모든 권한 상태 확인
    Map<Permission, PermissionStatus> allPermissions = {...bluetoothPermissions, ...locationPermissions};
    
    bool allGranted = allPermissions.values.every((status) => 
      status == PermissionStatus.granted || status == PermissionStatus.limited);

    print("🔍 [DEBUG] 모든 권한 허용됨: $allGranted");

    if (!allGranted) {
      print("🔍 [DEBUG] 권한이 부족함");
      
      // 영구 거부된 권한이 있는지 확인
      bool hasPermanentlyDenied = allPermissions.values.any((status) => 
        status == PermissionStatus.permanentlyDenied);
      
      if (hasPermanentlyDenied && mounted) {
        // 영구 거부된 경우 설정으로 이동하는 버튼 표시
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('권한 필요'),
              content: const Text('블루투스 프린터를 사용하기 위해 블루투스 및 위치 권한이 필요합니다.\n\n설정에서 다음을 확인해주세요:\n• 설정 > 개인정보 보호 및 보안 > 블루투스\n• 설정 > 개인정보 보호 및 보안 > 위치 서비스'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    openAppSettings();
                  },
                  child: const Text('설정으로 이동'),
                ),
              ],
            );
          },
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('블루투스 권한이 필요합니다. 설정에서 권한을 허용해주세요.')),
        );
      }
      return false;
    }

    print("🔍 [DEBUG] 권한 확인 완료 - 1초 대기 후 진행");
    // 권한 요청 후 약간의 지연을 두어 iOS가 권한을 완전히 적용할 시간을 줍니다
    await Future.delayed(const Duration(seconds: 1));
    print("🔍 [DEBUG] 권한 적용 대기 완료");
    return true;
  }

  Future<void> _searchDevices() async {
    print("🔍 [DEBUG] _searchDevices() 시작");
    
    // 권한 요청 제거 - 레퍼런스 앱처럼 바로 스캔 시도
    print("🔍 [DEBUG] 권한 요청 없이 바로 스캔 시작");
    
    setState(() {
      _isScanning = true;
      _devices = [];
    });

    try {
      print("🔍 [DEBUG] 플러그인 호출: searchDevices() 시작");
      final devices = await _bluberryPrinterPlugin.searchDevices();
      print("🔍 [DEBUG] 플러그인 응답 받음: ${devices.length}개 기기");
      
      // 각 기기 정보 출력
      for (int i = 0; i < devices.length; i++) {
        final device = devices[i];
        print("🔍 [DEBUG] 기기 ${i + 1}: ${device['name']} (${device['address']})");
      }
      
      setState(() {
        _devices = devices;
      });
      
      print("🔍 [DEBUG] UI 업데이트 완료: ${_devices.length}개 기기 표시");
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${devices.length}개의 기기를 찾았습니다')),
        );
      }
    } catch (e) {
      print("🔍 [DEBUG] 검색 실패 - 예외 발생: $e");
      print("🔍 [DEBUG] 예외 타입: ${e.runtimeType}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('검색 실패: $e')),
        );
      }
    } finally {
      setState(() {
        _isScanning = false;
      });
      print("🔍 [DEBUG] 검색 완료 - 스캔 상태 해제");
    }
  }

  Future<void> _connectDevice(String address, String name) async {
    print("🔍 [DEBUG] Flutter: 연결 시도 - $name ($address)");
    try {
      final success = await _bluberryPrinterPlugin.connectDevice(address);
      print("🔍 [DEBUG] Flutter: 연결 결과 - $success");
      if (success) {
        setState(() {
          _isConnected = true;
          _connectedDeviceName = name;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$name에 연결되었습니다')),
          );
        }
      }
    } catch (e) {
      print("🔍 [DEBUG] Flutter: 연결 실패 - $e");
      print("🔍 [DEBUG] Flutter: 오류 타입 - ${e.runtimeType}");
      
      String errorMessage = '연결 실패';
      if (e.toString().contains('NO_CHARACTERISTIC')) {
        errorMessage = '프린터 출력 특성을 찾을 수 없습니다. 다른 프린터를 시도해보세요.';
      } else if (e.toString().contains('CONNECTION_TIMEOUT')) {
        errorMessage = '연결 시간이 초과되었습니다. 프린터가 켜져 있는지 확인해주세요.';
      } else if (e.toString().contains('DEVICE_NOT_FOUND')) {
        errorMessage = '기기를 찾을 수 없습니다. 스캔을 다시 시도해주세요.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _disconnect() async {
    try {
      final success = await _bluberryPrinterPlugin.disconnect();
      if (success) {
        setState(() {
          _isConnected = false;
          _connectedDeviceName = '';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('연결이 해제되었습니다')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('연결 해제 실패: $e')),
        );
      }
    }
  }

  Future<void> _printSampleReceipt() async {
    print("🔍 [DEBUG] Flutter: 샘플 영수증 출력 시도");
    try {
      final success = await _bluberryPrinterPlugin.printSampleReceipt();
      print("🔍 [DEBUG] Flutter: 출력 결과 - $success");
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('샘플 영수증이 출력되었습니다')),
          );
        }
      }
    } catch (e) {
      print("🔍 [DEBUG] Flutter: 출력 실패 - $e");
      print("🔍 [DEBUG] Flutter: 오류 타입 - ${e.runtimeType}");
      
      String errorMessage = '출력 실패';
      if (e.toString().contains('NOT_CONNECTED')) {
        errorMessage = '프린터가 연결되지 않았습니다. 먼저 프린터에 연결해주세요.';
      } else if (e.toString().contains('NO_CHARACTERISTIC')) {
        errorMessage = '프린터 출력 특성을 찾을 수 없습니다. 다른 프린터를 시도해보세요.';
      } else if (e.toString().contains('WRITE_FAILED')) {
        errorMessage = '데이터 전송에 실패했습니다. 프린터 상태를 확인해주세요.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _printCustomReceipt() async {
    try {
      final success = await _bluberryPrinterPlugin.printReceipt(SampleReceipts.customReceipt);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('커스텀 영수증이 출력되었습니다')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('출력 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('블루베리 프린터'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
        child: Column(
          children: [
            // 플랫폼 버전 표시
            Card(
              child: ListTile(
                leading: const Icon(Icons.info),
                title: const Text('플랫폼 버전'),
                subtitle: Text(_platformVersion),
              ),
            ),
            
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            
            // 연결 상태 표시
            if (_isConnected)
              Card(
                color: Colors.green.withAlpha(50),
                child: ListTile(
                  leading: const Icon(Icons.bluetooth_connected, color: Colors.green),
                  title: const Text('연결됨'),
                  subtitle: Text(_connectedDeviceName),
                  trailing: ElevatedButton(
                    onPressed: _disconnect,
                    child: const Text('연결 해제'),
                  ),
                ),
              )
            else
              Card(
                color: Colors.red.withAlpha(50),
                child: const ListTile(
                  leading: Icon(Icons.bluetooth_disabled, color: Colors.red),
                  title: Text('연결되지 않음'),
                  subtitle: Text('블루투스 프린터에 연결해주세요'),
                ),
              ),
            
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            
            // 기기 검색 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isScanning ? null : _searchDevices,
                icon: _isScanning 
                  ? SizedBox(
                      width: MediaQuery.of(context).size.width * 0.04,
                      height: MediaQuery.of(context).size.width * 0.04,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
                label: Text(_isScanning ? '검색 중...' : '블루투스 기기 검색'),
              ),
            ),
            
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            
            // 기기 목록
            Expanded(
              child: _devices.isEmpty
                ? const Center(
                    child: Text('검색된 기기가 없습니다.\n위 버튼을 눌러 기기를 검색해보세요.'),
                  )
                : ListView.builder(
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      final deviceName = device['name'] ?? '알 수 없는 기기';
                      final deviceAddress = device['address'] ?? '';
                      
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.bluetooth),
                          title: Text(deviceName),
                          subtitle: Text(deviceAddress),
                          trailing: ElevatedButton(
                            onPressed: _isConnected ? null : () => _connectDevice(
                              deviceAddress, 
                              deviceName
                            ),
                            child: const Text('연결'),
                          ),
                        ),
                      );
                    },
                  ),
            ),
            
            // 영수증 출력 버튼들
            if (_isConnected) ...[
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              Card(
                color: Colors.blue.withAlpha(50),
                child: Padding(
                  padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
                  child: Column(
                    children: [
                      const Text(
                        '영수증 출력',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _printSampleReceipt,
                              icon: const Icon(Icons.receipt),
                              label: const Text('샘플 영수증'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _printCustomReceipt,
                              icon: const Icon(Icons.print),
                              label: const Text('커스텀 영수증'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
