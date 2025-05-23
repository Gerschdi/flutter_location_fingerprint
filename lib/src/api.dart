import 'dart:async';
import 'dart:math';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ble_controller.dart';
import 'fingerprint.dart';

/// Returns the best matching location name based on saved WiFi fingerprints.
Future<String> getWifiStandort() => _determineStandort(true);

/// Returns the best matching location name based on saved BLE fingerprints.
Future<String> getBleStandort() => _determineStandort(false);

Future<String> _determineStandort(bool wifi) async {
  // 1) Perform scan
  Map<String, int> wifiMap = {};
  try {
    final can = await WiFiScan.instance.canStartScan();
    if (can == CanStartScan.yes) {
      await WiFiScan.instance.startScan();
      await Future.delayed(const Duration(milliseconds: 500));
      final results = await WiFiScan.instance.getScannedResults();
      wifiMap = {for (var ap in results) ap.bssid: ap.level};
    }
  } catch (_) {}

  Map<String, int> bleMap = {};
  try {
    final bleResults = await BleController.instance.scanOneShot(2);
    bleMap = {for (var r in bleResults) r.device.id.id: r.rssi};
  } catch (_) {}

  // 2) Fetch fingerprints from Supabase
  final resp = await Supabase.instance.client.from('fingerprints').select();
  final fps = (resp as List)
      .map((e) => Fingerprint.fromJson(e as Map<String, dynamic>))
      .toList();

  // 3) Compare
  const penalty = 1e6;
  const factor = 20.0;

  String match(Map<String, int> cur, bool useWifi) {
    final scores = <MapEntry<Fingerprint, double>>[];
    for (var fp in fps) {
      final stored = useWifi ? fp.wifiData : fp.bleData;
      if (stored == null || stored.isEmpty) continue;
      double sumDiff = 0, sumW = 0;
      stored.forEach((k, v) {
        final c = cur[k];
        if (c != null) {
          final diff = (v - c).toDouble();
          final w = 1.0 / c.abs();
          sumDiff += w * diff * diff;
          sumW += w;
        }
      });
      final dist = sumW > 0 ? sqrt(sumDiff / sumW) * factor : penalty;
      scores.add(MapEntry(fp, dist));
    }
    if (scores.isEmpty) return 'Unknown';
    scores.sort((a, b) => a.value.compareTo(b.value));
    return scores.first.key.name;
  }

  // 4) Return result
  return wifi ? match(wifiMap, true) : match(bleMap, false);
}
