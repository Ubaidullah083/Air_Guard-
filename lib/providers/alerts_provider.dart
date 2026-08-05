import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/alert_model.dart';
import '../services/firebase_service.dart';

// ── All unresolved alerts ─────────────────────────────
final allAlertsProvider = StreamProvider<List<AlertModel>>((ref) {
  return FirebaseService.instance.watchAlerts();
});

// ── Alert filter: null = all, otherwise stationId ─────
final alertStationFilterProvider = StateProvider<String?>((ref) => null);

// ── Filtered alerts ───────────────────────────────────
final filteredAlertsProvider = Provider<List<AlertModel>>((ref) {
  final alerts = ref.watch(allAlertsProvider).value ?? [];
  final filter = ref.watch(alertStationFilterProvider);
  if (filter == null) return alerts;
  return alerts.where((a) => a.stationId == filter).toList();
});

// ── Alert count badge ─────────────────────────────────
final alertCountProvider = Provider<int>((ref) {
  return ref.watch(allAlertsProvider).value?.length ?? 0;
});
