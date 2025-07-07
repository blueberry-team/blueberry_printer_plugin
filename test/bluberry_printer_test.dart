import 'package:flutter_test/flutter_test.dart';
import 'package:bluberry_printer/bluberry_printer.dart';
import 'package:bluberry_printer/bluberry_printer_platform_interface.dart';
import 'package:bluberry_printer/bluberry_printer_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockBluberryPrinterPlatform
    with MockPlatformInterfaceMixin
    implements BluberryPrinterPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final BluberryPrinterPlatform initialPlatform = BluberryPrinterPlatform.instance;

  test('$MethodChannelBluberryPrinter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelBluberryPrinter>());
  });

  test('getPlatformVersion', () async {
    BluberryPrinter bluberryPrinterPlugin = BluberryPrinter();
    MockBluberryPrinterPlatform fakePlatform = MockBluberryPrinterPlatform();
    BluberryPrinterPlatform.instance = fakePlatform;

    expect(await bluberryPrinterPlugin.getPlatformVersion(), '42');
  });
}
