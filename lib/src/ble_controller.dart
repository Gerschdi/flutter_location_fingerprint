import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleController {
  BleController._internal();
  static final BleController instance = BleController._internal();

  Future<List<ScanResult>> scanOneShot(int seconds) async {
    await stop();
    await FlutterBluePlus.startScan(timeout: Duration(seconds: seconds));
    await FlutterBluePlus.isScanning.where((s) => s == false).first;
    return await FlutterBluePlus.scanResults.first;
  }

  Future<void> stop() async {
    await FlutterBluePlus.stopScan();
    await FlutterBluePlus.isScanning.where((s) => s == false).first;
  }
}
