import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sensor_reading_model.dart';
import '../services/firebase_service.dart';
import '../services/alert_service.dart';
import 'station_provider.dart';

// ── How many readings to fetch per time filter ────────
int _limitForFilter(String filter) {
  switch (filter) {
    case '24H':
      return 288;
    case '7D':
      return 2016;
    default:
      return 12;
  }
}

final timeFilterProvider = StateProvider<String>((ref) => '1H');
final monitorSensorKeyProvider = StateProvider<String>((ref) => 'mq7');

// ── Latest reading — also triggers alert evaluation ───
final latestReadingProvider = StreamProvider<SensorReadingModel?>((ref) {
  final stationId = ref.watch(selectedStationIdProvider);
  if (stationId == null) return Stream.value(null);

  return FirebaseService.instance.watchLatestReading(stationId).asyncMap((
    reading,
  ) async {
    if (reading == null) return null;

    // ✅ Get station to access its thresholds
    final station = await FirebaseService.instance.getStationOnce(stationId);

    if (station != null) {
      // ✅ Evaluate reading against thresholds
      // Only create alerts if not already created for this timestamp
      await AlertService.instance.evaluateReading(reading, station);
    }

    return reading;
  });
});

// ── History for monitor screen ─────────────────────────
final historyProvider = StreamProvider<List<SensorReadingModel>>((ref) {
  final stationId = ref.watch(selectedStationIdProvider);
  final filter = ref.watch(timeFilterProvider);
  if (stationId == null) return Stream.value([]);
  return FirebaseService.instance.watchReadingsHistory(
    stationId,
    limitToLast: _limitForFilter(filter),
  );
});

// ── Worst 24h values ──────────────────────────────────
final worst24hProvider = FutureProvider.family<Map<String, double>, String>((
  ref,
  stationId,
) {
  return FirebaseService.instance.getWorst24h(stationId);
});
