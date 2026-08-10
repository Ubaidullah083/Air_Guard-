import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/station_model.dart';
import '../models/sensor_reading_model.dart';
import '../services/firebase_service.dart';
import '../core/constants/sensor_constants.dart';

// ── Currently selected station ID ─────────────────────
final selectedStationIdProvider = StateProvider<String?>((ref) => null);

// ── User ID ───────────────────────────────────────────
final userIdProvider = Provider<String>((ref) => 'demo-user');

// ── All stations for this user ────────────────────────
final stationsProvider = StreamProvider<List<StationModel>>((ref) {
  final userId = ref.watch(userIdProvider);
  return FirebaseService.instance.watchUserStations(userId);
});

// ── Currently selected station ────────────────────────
final selectedStationProvider = StreamProvider<StationModel?>((ref) {
  final stationId = ref.watch(selectedStationIdProvider);
  if (stationId == null) return Stream.value(null);
  return FirebaseService.instance.watchStation(stationId);
});

// ── Auto-select first online station ──────────────────
final autoSelectProvider = Provider<void>((ref) {
  final stations = ref.watch(stationsProvider).value ?? [];
  final selectedId = ref.watch(selectedStationIdProvider);

  if (selectedId == null && stations.isNotEmpty) {
    final online = stations.firstWhere(
      (s) => s.isOnline,
      orElse: () => stations.first,
    );
    Future.microtask(
      () => ref.read(selectedStationIdProvider.notifier).state = online.id,
    );
  }
});

// ── Global AQI level — drives background on ALL screens ──
final globalAqiLevelProvider = StateProvider<AirQualityLevel>(
  (ref) => AirQualityLevel.good,
);

// ── Helper to compute AQI from reading + station ──────
AirQualityLevel computeAqiLevel(
  SensorReadingModel? reading,
  StationModel? station,
) {
  if (reading == null || station == null) {
    return AirQualityLevel.offline;
  }
  AirQualityLevel worst = AirQualityLevel.good;
  for (final sensor in SensorConstants.sensors) {
    if (!sensor.isActive) continue;
    final value = reading.getValue(sensor.key);
    final elevated =
        station.thresholds['${sensor.key}_elevated'] ?? sensor.defaultElevated;
    final critical =
        station.thresholds['${sensor.key}_critical'] ?? sensor.defaultCritical;
    final level = AirQualityHelper.getLevel(value, elevated, critical);
    if (level.index > worst.index) worst = level;
  }
  return worst;
}
