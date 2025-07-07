import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:bluberry_printer/bluberry_printer.dart';
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

  Future<void> _searchDevices() async {
    setState(() {
      _isScanning = true;
      _devices = [];
    });

    try {
      final devices = await _bluberryPrinterPlugin.searchDevices();
      setState(() {
        _devices = devices;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${devices.length}개의 기기를 찾았습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('검색 실패: $e')),
        );
      }
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _connectDevice(String address, String name) async {
    try {
      final success = await _bluberryPrinterPlugin.connectDevice(address);
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('연결 실패: $e')),
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
    try {
      final success = await _bluberryPrinterPlugin.printSampleReceipt();
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('샘플 영수증이 출력되었습니다')),
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

  Future<void> _printCustomReceipt() async {
    const receiptText = '''
[TITLE]카페 블루베리[/TITLE]

[STORE_INFO]
서울특별시 강남구 테헤란로 123
전화: 02-1234-5678
사업자등록번호: 123-45-67890
[/STORE_INFO]

[SEPARATOR]

[ITEM_LIST]
아메리카노 (ICE)        4,500원 x 2
카페라떼 (HOT)          5,000원 x 1
블루베리 머핀           3,500원 x 1
[/ITEM_LIST]

[TOTAL]
소계: 17,500원
부가세: 1,750원
합계: 19,250원
[/TOTAL]

[THANK_YOU]
감사합니다!
다음에 또 방문해 주세요.
[/THANK_YOU]
    ''';

    try {
      final success = await _bluberryPrinterPlugin.printReceipt(receiptText);
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
