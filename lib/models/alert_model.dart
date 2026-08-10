enum AlertLevel { advisory, warning, critical, sensorFailure }

class AlertModel {
  final String id;
  final String stationId;
  final String stationName;
  final String sensorKey;
  final String sensorCode;
  final String parameter;
  final double value;
  final String unit;
  final AlertLevel level;
  final String message;
  final DateTime timestamp;
  final bool resolved;

  const AlertModel({
    required this.id,
    required this.stationId,
    required this.stationName,
    required this.sensorKey,
    required this.sensorCode,
    required this.parameter,
    required this.value,
    required this.unit,
    required this.level,
    required this.message,
    required this.timestamp,
    required this.resolved,
  });

  factory AlertModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return AlertModel(
      id: id,
      stationId: map['stationId']?.toString() ?? '',
      stationName: map['stationName']?.toString() ?? '',
      sensorKey: map['sensorKey']?.toString() ?? '',
      sensorCode: map['sensorCode']?.toString() ?? '',
      parameter: map['parameter']?.toString() ?? '',
      value: double.tryParse(map['value']?.toString() ?? '') ?? 0,
      unit: map['unit']?.toString() ?? '',
      level: AlertLevel.values.firstWhere(
        (l) => l.name == map['level']?.toString(),
        orElse: () => AlertLevel.advisory,
      ),
      message: map['message']?.toString() ?? '',
      timestamp: _parseTimestamp(map['timestamp']),
      resolved: map['resolved'] == true,
    );
  }

  // Parse timestamp safely.
  static DateTime _parseTimestamp(dynamic raw) {
    if (raw == null) {
      return DateTime.now();
    }

    final ms = int.tryParse(raw.toString()) ?? 0;

    // If the value is less than January 1, 2000
    // in milliseconds, treat it as uptime/invalid
    // rather than a Unix epoch timestamp.
    const year2000 = 946684800000;

    if (ms < year2000) {
      return DateTime.now();
    }

    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Map<String, dynamic> toMap() => {
    'stationId': stationId,
    'stationName': stationName,
    'sensorKey': sensorKey,
    'sensorCode': sensorCode,
    'parameter': parameter,
    'value': value,
    'unit': unit,
    'level': level.name,
    'message': message,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'resolved': resolved,
  };
}
