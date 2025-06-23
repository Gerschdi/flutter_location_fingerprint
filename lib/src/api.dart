import 'dart:async';
import 'dart:math';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ble_controller.dart';
import 'fingerprint.dart';

/// Singleton service to manage location fingerprint matching
class LocationService {
  LocationService._privateConstructor();
  static final LocationService instance = LocationService._privateConstructor();

  late final List<Fingerprint> _fingerprints;
  bool _initialized = false;

  /// Initialize the service by fetching fingerprints from the database
  Future<void> init() async {
    if (_initialized) return;
    final resp = await Supabase.instance.client
        .from('fingerprints')
        .select();
    final list = resp as List;
    _fingerprints = list
        .map((j) => Fingerprint.fromJson(j as Map<String, dynamic>))
        .toList();
    _initialized = true;
  }

  /// Normalize IDs (BSSID or BLE device IDs) to lowercase without separators
  String _normalizeId(String id) =>
      id.toLowerCase().replaceAll(RegExp(r'[:\-]'), '');

  /// Normalize a map's keys via [_normalizeId]
  Map<String, int> _normalizeMap(Map<String, int> m) =>
      m.map((k, v) => MapEntry(_normalizeId(k), v));

  /// Checks that at least [pct] overlap exists relative to the smaller map
  bool _hasEnoughOverlap(
      Map<String, int> a,
      Map<String, int> b,
      double pct,
      ) {
    final commonCount = a.keys.toSet().intersection(b.keys.toSet()).length;
    final minLen = min(a.length, b.length);
    final needed = max(1, (minLen * pct).ceil());
    return commonCount >= needed;
  }

  /// Cosine similarity over the union of keys
  double _cosineSimilarity(
      Map<String, int> a,
      Map<String, int> b,
      ) {
    final allKeys = <String>{}..addAll(a.keys)..addAll(b.keys);
    double dot = 0, normA = 0, normB = 0;
    for (var k in allKeys) {
      final ai = (a[k] ?? 0).toDouble();
      final bi = (b[k] ?? 0).toDouble();
      dot += ai * bi;
      normA += ai * ai;
      normB += bi * bi;
    }
    if (normA == 0 || normB == 0) return -1.0;
    return dot / (sqrt(normA) * sqrt(normB));
  }

  /// Improved cosine with dynamic overlap filter
  double _improvedCosine(
      Map<String, int> a,
      Map<String, int> b,
      double overlapPct,
      ) {
    if (!_hasEnoughOverlap(a, b, overlapPct)) return -1.0;
    return _cosineSimilarity(a, b);
  }

  /// Determine best location by WiFi
  Future<String> getWifiStandort({double overlapPct = 0.2}) async {
    await init();
    // 1) WiFi scan
    Map<String, int> wifiMap = {};
    if (await WiFiScan.instance.canStartScan(askPermissions: true) ==
        CanStartScan.yes) {
      await WiFiScan.instance.startScan();
      await Future.delayed(const Duration(milliseconds: 500));
      final results = await WiFiScan.instance.getScannedResults();
      for (var ap in results) {
        wifiMap[_normalizeId(ap.bssid)] = ap.level;
      }
    }
    wifiMap = _normalizeMap(wifiMap);

    // Compute scores
    final scores = <String, double>{};
    for (var fp in _fingerprints) {
      final wData = _normalizeMap(fp.wifiData ?? {});
      scores[fp.name] = _improvedCosine(wData, wifiMap, overlapPct);
    }

    // Select best
    String best = 'Unknown';
    double bestScore = -1;
    scores.forEach((name, score) {
      if (score > bestScore) {
        bestScore = score;
        best = name;
      }
    });
    return best;
  }

  /// Determine best location by BLE
  Future<String> getBleStandort({double overlapPct = 0.2}) async {
    await init();
    // 1) BLE scan
    Map<String, int> bleMap = {};
    try {
      final bleResults = await BleController.instance.scanOneShot(2);
      for (var r in bleResults) {
        bleMap[_normalizeId(r.device.id.id)] = r.rssi;
      }
    } catch (_) {}
    bleMap = _normalizeMap(bleMap);

    // Compute scores
    final scores = <String, double>{};
    for (var fp in _fingerprints) {
      final bData = _normalizeMap(fp.bleData ?? {});
      scores[fp.name] = _improvedCosine(bData, bleMap, overlapPct);
    }

    // Select best
    String best = 'Unknown';
    double bestScore = -1;
    scores.forEach((name, score) {
      if (score > bestScore) {
        bestScore = score;
        best = name;
      }
    });
    return best;
  }

  /// Determine best hybrid location by weighted sum
  Future<String> getHybridStandort({
    double overlapPct = 0.2,
    double wifiWeight = 0.5,
    double bleWeight = 0.5,
  }) async {
    await init();
    final wifi = await getWifiStandort(overlapPct: overlapPct);
    final ble = await getBleStandort(overlapPct: overlapPct);
    // compute combined scores directly if needed, or return hybrid majority
    return wifiWeight >= bleWeight ? wifi : ble;
  }
}
