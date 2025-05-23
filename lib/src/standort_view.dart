import 'dart:async';
import 'package:flutter/material.dart';
import 'api.dart';

/// A widget that displays live WiFi and BLE based location.
class StandortView extends StatefulWidget {
  const StandortView({Key? key}) : super(key: key);

  @override
  _StandortViewState createState() => _StandortViewState();
}

class _StandortViewState extends State<StandortView> {
  late Timer _timer;
  String _wifiLoc = 'Unknown';
  String _bleLoc = 'Unknown';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _update());
    _update();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _update() async {
    if (_busy) return;
    setState(() => _busy = true);
    final wifi = await getWifiStandort();
    final ble = await getBleStandort();
    setState(() {
      _wifiLoc = wifi;
      _bleLoc = ble;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('WiFi: $_wifiLoc', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('BLE: $_bleLoc', style: TextStyle(fontWeight: FontWeight.bold)),
          if (_busy) Padding(padding: const EdgeInsets.only(top: 16), child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
