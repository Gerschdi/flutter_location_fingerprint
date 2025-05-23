class Fingerprint {
  final int id;
  final int campusId;
  final int gebaeudeId;
  final int stockwerkId;
  final String? raum;
  final String name;
  final DateTime timestamp;
  final Map<String, int>? rssiData;
  final Map<String, int>? wifiData;
  final Map<String, int>? bleData;
  final String? userId;

  Fingerprint({
    required this.id,
    required this.campusId,
    required this.gebaeudeId,
    required this.stockwerkId,
    this.raum,
    required this.name,
    required this.timestamp,
    this.rssiData,
    this.wifiData,
    this.bleData,
    this.userId,
  });

  static int _toInt(dynamic v) => v is int ? v : int.tryParse(v.toString()) ?? 0;

  static Map<String, int>? parseMap(dynamic json) {
    if (json is Map) {
      return json.map((k, v) => MapEntry(k as String, _toInt(v)));
    }
    return null;
  }

  factory Fingerprint.fromJson(Map<String, dynamic> json) {
    return Fingerprint(
      id: _toInt(json['id']),
      campusId: _toInt(json['campus_id']),
      gebaeudeId: _toInt(json['gebaeude_id']),
      stockwerkId: _toInt(json['stockwerk_id']),
      raum: json['raum'] as String?,
      name: json['name'] as String? ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String),
      rssiData: parseMap(json['rssi_data']),
      wifiData: parseMap(json['wifi_data']),
      bleData: parseMap(json['ble_data']),
      userId: json['user_id'] as String?,
    );
  }
}
