class SensorReadingModel {
  final String stationId;
  final DateTime timestamp;
  final double dust;
  final double pm25;
  final double mq4;
  final double mq7;
  final double mq131;
  final double mq135;
  final double humidity;
  final double temperature;

  const SensorReadingModel({
    required this.stationId,
    required this.timestamp,
    required this.dust,
    required this.pm25,
    required this.mq4,
    required this.mq7,
    required this.mq131,
    required this.mq135,
    required this.humidity,
    required this.temperature,
  });

  factory SensorReadingModel.fromMap(
    String stationId,
    Map<dynamic, dynamic> map,
  ) {
    return SensorReadingModel(
      stationId: stationId,
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              int.tryParse(map['timestamp'].toString()) ?? 0,
            )
          : DateTime.now(),
      dust: _parse(map['dust']),
      pm25: _parse(map['pm25']),
      mq4: _parse(map['mq4']),
      mq7: _parse(map['mq7']),
      mq131: _parse(map['mq131']),
      mq135: _parse(map['mq135']),
      humidity: _parse(map['humidity']),
      temperature: _parse(map['temperature']),
    );
  }

  static double _parse(dynamic v) =>
      double.tryParse(v?.toString() ?? '') ?? 0.0;

  double getValue(String key) {
    switch (key) {
      case 'dust':
        return dust;
      case 'pm25':
        return pm25;
      case 'mq4':
        return mq4;
      case 'mq7':
        return mq7;
      case 'mq131':
        return mq131;
      case 'mq135':
        return mq135;
      case 'humidity':
        return humidity;
      case 'temperature':
        return temperature;
      default:
        return 0;
    }
  }

  Map<String, dynamic> toMap() => {
    'timestamp': timestamp.millisecondsSinceEpoch,
    'dust': dust,
    'pm25': pm25,
    'mq4': mq4,
    'mq7': mq7,
    'mq131': mq131,
    'mq135': mq135,
    'humidity': humidity,
    'temperature': temperature,
  };
}
