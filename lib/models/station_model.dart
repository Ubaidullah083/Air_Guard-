class StationModel {
  final String id;
  final String name;
  final String location;
  final String ownerId;
  final bool isOnline;
  final DateTime? lastSeen;
  final Map<String, double> thresholds;

  const StationModel({
    required this.id,
    required this.name,
    required this.location,
    required this.ownerId,
    required this.isOnline,
    this.lastSeen,
    required this.thresholds,
  });

  factory StationModel.fromMap(String id, Map<dynamic, dynamic> map) {
    final info = map['info'] as Map? ?? {};
    final config = map['config'] as Map? ?? {};
    final threshMap = config['thresholds'] as Map? ?? {};

    return StationModel(
      id: id,
      name: info['name']?.toString() ?? 'Unknown Station',
      location: info['location']?.toString() ?? '',
      ownerId: info['owner']?.toString() ?? '',
      isOnline: info['status']?.toString().trim().toLowerCase() == 'online',
      lastSeen: info['lastSeen'] != null
          ? DateTime.tryParse(info['lastSeen'].toString())
          : null,
      thresholds: Map<String, double>.fromEntries(
        threshMap.entries.map(
          (e) => MapEntry(
            e.key.toString(),
            double.tryParse(e.value.toString()) ?? 0,
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> toMap() => {
    'info': {
      'name': name,
      'location': location,
      'owner': ownerId,
      'status': isOnline ? 'online' : 'offline',
      'lastSeen': lastSeen?.toIso8601String(),
    },
    'config': {'thresholds': thresholds},
  };

  StationModel copyWith({
    String? name,
    String? location,
    bool? isOnline,
    DateTime? lastSeen,
    Map<String, double>? thresholds,
  }) => StationModel(
    id: id,
    name: name ?? this.name,
    location: location ?? this.location,
    ownerId: ownerId,
    isOnline: isOnline ?? this.isOnline,
    lastSeen: lastSeen ?? this.lastSeen,
    thresholds: thresholds ?? this.thresholds,
  );
}
