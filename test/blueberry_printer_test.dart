import 'package:flutter_test/flutter_test.dart';
import 'package:blueberry_printer/blueberry_printer.dart';
import 'package:blueberry_printer/blueberry_printer_platform_interface.dart';
import 'package:blueberry_printer/blueberry_printer_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockBlueberryPrinterPlatform
    with MockPlatformInterfaceMixin
    implements BlueberryPrinterPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final BlueberryPrinterPlatform initialPlatform = BlueberryPrinterPlatform.instance;

  test('$MethodChannelBlueberryPrinter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelBlueberryPrinter>());
  });

  test('getPlatformVersion', () async {
    BlueberryPrinter blueberryPrinterPlugin = BlueberryPrinter();
    MockBlueberryPrinterPlatform fakePlatform = MockBlueberryPrinterPlatform();
    BlueberryPrinterPlatform.instance = fakePlatform;

    expect(await blueberryPrinterPlugin.getPlatformVersion(), '42');
  });
}
