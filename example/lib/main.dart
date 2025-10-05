import 'package:flutter/material.dart';
import 'dart:async';

import 'package:blueberry_printer/blueberry_printer.dart';
import 'sample_receipts.dart';
import 'sample_single_order_data.dart';
import 'sample_total_order_data.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

// 연결 상태 Enum
enum PrinterConnectionState {
  connected,    // 연결됨 (녹색)
  suspended,    // 일시 중지 (주황색) - 오프라인, 용지 부족 등
  disconnected, // 연결 안됨 (회색)
}

// 에러 기록 클래스
class ConnectionError {
  final String message;
  final DateTime timestamp;

  ConnectionError({required this.message, required this.timestamp});
}

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
  final _blueberryPrinterPlugin = BlueberryPrinter();
  String _platformVersion = 'Unknown';
  List<Map<String, String>> _devices = [];
  bool _isScanning = false;
  bool _isConnected = false;
  String _connectedDeviceName = '';
  String _connectionStatus = '연결되지 않음';
  StreamSubscription? _connectionStatusSubscription;

  // 연결 상태 추적
  PrinterConnectionState _currentConnectionState = PrinterConnectionState.disconnected;
  final List<ConnectionError> _errorHistory = [];
  bool _hasUnreadStatusChange = false; // 읽지 않은 상태 변경
  bool _isFirstConnection = true; // 첫 연결인지 확인

  static const EventChannel _connectionStatusChannel =
      EventChannel('blueberry_printer/connection_status');

  @override
  void initState() {
    super.initState();
    initPlatformState();
    _requestBluetoothPermissions();
    _listenToConnectionStatus();
  }

  @override
  void dispose() {
    _connectionStatusSubscription?.cancel();
    super.dispose();
  }

  void _listenToConnectionStatus() {
    _connectionStatusSubscription = _connectionStatusChannel
        .receiveBroadcastStream()
        .listen((event) {
      if (event is Map) {
        final status = event['status'] as String?;
        final message = event['message'] as String?;
        final reason = event['reason'] as String?;

        setState(() {
          // 첫 연결이 아닐 때만 알림 표시
          if (!_isFirstConnection) {
            _hasUnreadStatusChange = true;
          }

          if (status == 'connected') {
            _connectionStatus = '연결됨';
            _currentConnectionState = PrinterConnectionState.connected;
            if (!_isConnected) {
              _isConnected = true;
            }
            // 첫 연결 완료
            _isFirstConnection = false;
          } else if (status == 'disconnected') {
            // 이유가 있으면 표시, 없으면 기본 메시지
            _connectionStatus = reason ?? '연결 끊김';
            _isConnected = false;
            _connectedDeviceName = '';

            // 일시적 오류 vs 영구적 오류 구분
            if (reason == '프린터 오프라인' || reason == '용지 부족' || reason == '프린터 에러') {
              _currentConnectionState = PrinterConnectionState.suspended;
            } else {
              _currentConnectionState = PrinterConnectionState.disconnected;
            }

            // 에러 기록 추가
            if (reason != null) {
              _errorHistory.insert(0, ConnectionError(
                message: reason,
                timestamp: DateTime.now(),
              ));
              // 최대 10개까지만 저장
              if (_errorHistory.length > 10) {
                _errorHistory.removeLast();
              }
            }
          }
        });

        if (message != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: status == 'connected' ? Colors.green : Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    });
  }

  Future<void> initPlatformState() async {
    String platformVersion;
    try {
      platformVersion = await _blueberryPrinterPlugin.getPlatformVersion() ?? 'Unknown platform version';
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
      final devices = await _blueberryPrinterPlugin.searchDevices();
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
      final success = await _blueberryPrinterPlugin.connectDevice(address);
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
      final success = await _blueberryPrinterPlugin.disconnect();
      if (success) {
        setState(() {
          _isConnected = false;
          _connectedDeviceName = '';
          _connectionStatus = '연결되지 않음';
          _currentConnectionState = PrinterConnectionState.disconnected;
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
      final success = await _blueberryPrinterPlugin.printSampleReceipt();
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
      final success = await _blueberryPrinterPlugin.printReceipt(SampleReceipts.customReceipt);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '커스텀 영수증 출력이 완료되었습니다' : '커스텀 영수증 출력에 실패했습니다'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      print('커스텀 영수증 출력 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('커스텀 영수증 출력 실패'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 구조화된 주문 영수증 출력
  Future<void> _printOrderReceipt() async {
    print('🔍 [DEBUG] 구조화된 주문 영수증 출력 시작');
    try {
      // 샘플 단일 주문 데이터 가져오기
      final sampleOrderData = getSampleSingleOrderData();

      print(' [DEBUG] 네이티브 함수 호출 전: printSingleOrder');
      print(' [DEBUG] 전달할 데이터: ${sampleOrderData.toJson()}');
      final success = await _blueberryPrinterPlugin.printSingleOrder(
        sampleOrderData,
        storeName: 'JungWoo Cafe',
        tableNumber: 'T-25', // 테이블 번호 추가 (주문 데이터의 테이블명을 덮어씀)
        storeAddress: '123 JungWoo Street, Seoul',
        phoneNumber: '02-8513-6357',
        businessNumber: '333-33-3333',
        thankYouMessage: 'Thank you for visiting!\nPlease come again soon.',
        language: 'eng', // 영어로 테스트
        currency: 'USD', // 달러로 테스트
      );
      print(' [DEBUG] 네이티브 함수 호출 결과: $success');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '구조화된 주문 영수증 출력이 완료되었습니다' : '구조화된 주문 영수증 출력에 실패했습니다'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      print('구조화된 주문 영수증 출력 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('구조화된 주문 영수증 출력 실패'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 누적 주문 영수증 출력 (모든 주문 버전 포함)
  Future<void> _printCumulativeOrderReceipt() async {
    try {
      print('🔍 [DEBUG] 누적 주문 영수증 출력 시작');
      
      // 샘플 전체 주문 데이터 가져오기
      final cumulativeOrderData = getSampleTotalOrderData();
      
      print('🔍 [DEBUG] 누적 주문 데이터 생성 완료 - 메뉴 수: ${cumulativeOrderData.orderMenus.length}');
      
      // 업데이트된 iOS 네이티브 코드가 Flutter 모델 구조를 직접 처리함
      print('🔍 [DEBUG] 주문 메뉴 수: ${cumulativeOrderData.orderMenus.length}');
      
      // 전체 주문 영수증 출력
      bool success = await _blueberryPrinterPlugin.printTotalOrder(
        cumulativeOrderData, // OrderHistoryTotalResponse 객체 그대로 사용
        storeName: '카페 블루베리',
        tableNumber: 'VIP-7', // 테이블 번호 추가 (주문 데이터의 테이블명을 덮어씀)
        storeAddress: '서울특별시 강남구 테헤란로 123',
        phoneNumber: '02-1234-5678',
        businessNumber: '123-45-67890',
        thankYouMessage: '누적 주문에 감사드립니다!\n다음에도 많은 이용 부탁드립니다.',
        language: 'kor',
        currency: 'KRW',
      );
      
      if (success) {
        print('🔍 [DEBUG] 누적 주문 영수증 출력 성공');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('누적 주문 영수증 출력 성공!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        print('🔍 [DEBUG] 누적 주문 영수증 출력 실패');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('누적 주문 영수증 출력 실패'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('🔍 [DEBUG] 누적 주문 영수증 출력 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('누적 주문 영수증 출력 오류: $e'),
            backgroundColor: Colors.red,
          ),
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
        actions: [
          InkWell(
            onTap: () {
              setState(() {
                _hasUnreadStatusChange = false;
              });
              _showErrorHistoryDialog();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 상태 점
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getStatusColor(),
                    ),
                  ),
                  // 알림 배지
                  if (_hasUnreadStatusChange)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Center(
                          child: Text(
                            '!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 6,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
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

            // 기기 검색 및 연결 버튼
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showDeviceSearchDialog,
                    icon: const Icon(Icons.bluetooth_searching),
                    label: const Text('프린터 연결'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                if (_isConnected) ...[
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _disconnect,
                    icon: const Icon(Icons.bluetooth_disabled),
                    label: const Text('연결 해제'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ],
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            
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
                      Column(
                        children: [
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
                          SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _printOrderReceipt,
                              icon: const Icon(Icons.receipt_long),
                              label: const Text('단일 주문 영수증 (점포용)'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _printCumulativeOrderReceipt,
                              icon: const Icon(Icons.layers),
                              label: const Text('전체 주문 영수증 (모든 버전)'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
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

  // 상태 색상 가져오기
  Color _getStatusColor() {
    switch (_currentConnectionState) {
      case PrinterConnectionState.connected:
        return Colors.green;
      case PrinterConnectionState.suspended:
        return Colors.orange;
      case PrinterConnectionState.disconnected:
        return Colors.grey;
    }
  }

  // 에러 히스토리 다이얼로그 표시
  void _showErrorHistoryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getStatusColor(),
                ),
              ),
              const SizedBox(width: 12),
              const Text('연결 상태'),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 300,
              minHeight: 100,
            ),
            child: SizedBox(
              width: double.maxFinite,
              child: _errorHistory.isEmpty
                  ? const Center(child: Text('에러 기록이 없습니다.'))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _errorHistory.length,
                      itemBuilder: (context, index) {
                        final error = _errorHistory[index];
                        return ListTile(
                          leading: const Icon(Icons.error_outline, color: Colors.red, size: 20),
                          title: Text(error.message),
                          subtitle: Text(
                            _formatTimestamp(error.timestamp),
                            style: const TextStyle(fontSize: 12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          dense: true,
                        );
                      },
                    ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _errorHistory.clear();
                });
                Navigator.of(context).pop();
              },
              child: const Text('기록 삭제'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }

  // 시간 포맷
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}초 전';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else {
      return '${timestamp.month}/${timestamp.day} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  // 블루투스 기기 검색 다이얼로그
  Future<void> _showDeviceSearchDialog() async {
    // 검색 시작
    setState(() {
      _isScanning = true;
      _devices = [];
    });

    StateSetter? dialogSetState;

    // 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            dialogSetState = setDialogState;
            return AlertDialog(
              title: const Text('블루투스 기기 검색'),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: _isScanning && _devices.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('검색 중...'),
                          ],
                        ),
                      )
                    : _devices.isEmpty
                        ? const Center(child: Text('검색된 기기가 없습니다.'))
                        : ListView.builder(
                            itemCount: _devices.length,
                            itemBuilder: (context, index) {
                              final device = _devices[index];
                              final deviceName = device['name'] ?? '알 수 없는 기기';
                              final deviceAddress = device['address'] ?? '';

                              return ListTile(
                                leading: const Icon(Icons.bluetooth),
                                title: Text(deviceName),
                                subtitle: Text(deviceAddress),
                                onTap: () async {
                                  Navigator.of(dialogContext).pop();
                                  await _connectDevice(deviceAddress, deviceName);
                                },
                              );
                            },
                          ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    setState(() {
                      _devices = [];
                      _isScanning = false;
                    });
                  },
                  child: const Text('취소'),
                ),
              ],
            );
          },
        );
      },
    );

    // 검색 실행
    try {
      print('🔍 [DEBUG] 기기 검색 시작');
      final devices = await _blueberryPrinterPlugin.searchDevices();
      print('🔍 [DEBUG] 기기 검색 완료: ${devices.length}개');

      if (mounted) {
        setState(() {
          _devices = devices;
          _isScanning = false;
        });
        // 다이얼로그도 업데이트
        dialogSetState?.call(() {});
      }
    } catch (e) {
      print('🔍 [DEBUG] 기기 검색 실패: $e');
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
        dialogSetState?.call(() {});
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('검색 실패: $e')),
        );
      }
    }
  }
}
