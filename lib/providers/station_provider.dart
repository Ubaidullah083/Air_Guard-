import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/station_model.dart';
import '../services/firebase_service.dart';

// ── Currently selected station ID ─────────────────────
final selectedStationIdProvider = StateProvider<String?>((ref) => null);

// ── User ID (replace with real auth later) ────────────
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

// ── Auto-select first online station ─────────────────
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
