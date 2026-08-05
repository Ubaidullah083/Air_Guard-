import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sensor_reading_model.dart';
import '../services/firebase_service.dart';
import 'station_provider.dart';

// ── Latest reading for selected station ───────────────
final latestReadingProvider = StreamProvider<SensorReadingModel?>((ref) {
  final stationId = ref.watch(selectedStationIdProvider);
  if (stationId == null) return Stream.value(null);
  return FirebaseService.instance.watchLatestReading(stationId);
});

// ── History for monitor screen ────────────────────────
// How many readings to fetch per time filter
int _limitForFilter(String filter) {
  switch (filter) {
    case '24H':
      return 288; // every 5 min for 24h
    case '7D':
      return 2016; // every 5 min for 7 days
    default:
      return 12; // every 5 min for 1h
  }
}

final timeFilterProvider = StateProvider<String>((ref) => '1H');

final monitorSensorKeyProvider = StateProvider<String>((ref) => 'mq7');

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
